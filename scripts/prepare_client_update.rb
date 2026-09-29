#!/usr/bin/env ruby
# Build an identity-preserving CSiM update from the saved client definitions.
require 'digest'
require 'fileutils'
require 'json'
require 'yaml'

module ClientUpdate
  ROOT = File.expand_path('..', __dir__)
  CLIENT = Dir[File.join(ROOT, 'sources/exports/production-september-2026/unpacked/*')].fetch(0)
  REVIEWED = File.join(
    ROOT,
    'sources/live-review/2026-09-17T163028Z/unpacked/dashboard/dashboard_export_20260917T163029'
  )
  OVERLAY = File.join(ROOT, 'dashboard/overlays/beth-panel-coverage.json')
  BASELINE = File.join(ROOT, 'dashboard/client-baseline')
  UPDATE = File.join(ROOT, 'dashboard/client-update')

  module_function

  def read(path)
    YAML.safe_load(File.read(path))
  end

  def write(path, value)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, YAML.dump(value).gsub(/^ +'$/, "'").gsub(/: \n/, ":\n").gsub(/^(\s*-) +\n/, "\\1\n"))
  end

  def definitions(root, kind)
    pattern = kind == 'datasets' ? 'datasets/**/*.yaml' : "#{kind}/*.yaml"
    Dir[File.join(root, pattern)].sort.to_h do |path|
      value = read(path)
      key = case kind
            when 'datasets' then value.fetch('table_name')
            when 'charts' then value.fetch('slice_name')
            else value.fetch('uuid')
            end
      [key, [path, value]]
    end
  end

  def rewrite(value, mapping)
    case value
    when Hash then value.transform_values { |item| rewrite(item, mapping) }
    when Array then value.map { |item| rewrite(item, mapping) }
    when String
      mapping.reduce(value) { |text, (before, after)| text.gsub(before, after) }
    else value
    end
  end

  def relations(sql)
    sql.to_s.scan(/"v1"\."([^"]+)"/).flatten.uniq
  end

  def canonical_relation(name)
    name.sub(/ 2024-2025\z/, '')
  end

  def relation_mapping(client_datasets, reviewed_datasets)
    client = client_datasets.values.flat_map { |(_, item)| relations(item['sql']) }.uniq
    reviewed = reviewed_datasets.values.flat_map { |(_, item)| relations(item['sql']) }.uniq
    reviewed.to_h do |name|
      destination = client.find { |candidate| canonical_relation(candidate) == canonical_relation(name) }
      raise "No client relation matches #{name}" unless destination
      [name, destination]
    end
  end

  def apply_panel_overlay(dashboard, charts)
    plan = JSON.parse(File.read(OVERLAY))
    raise 'The overlay does not match the reviewed dashboard' unless dashboard['uuid'] == plan['dashboardUuid']
    by_uuid = charts.values.to_h { |(_, chart)| [chart.fetch('uuid'), chart] }
    source_ids = []
    plan.fetch('panels').each do |panel|
      chart = by_uuid.fetch(panel.fetch('uuid'))
      chart['description'] = panel.fetch('description')
      nodes = dashboard.fetch('position').values.select do |node|
        node.is_a?(Hash) && node['type'] == 'CHART' && node.dig('meta', 'uuid') == panel['uuid']
      end
      raise "Expected one layout node for #{panel['uuid']}" unless nodes.length == 1
      nodes.first.fetch('meta')['sliceNameOverride'] = panel.fetch('title')
      source_ids << nodes.first.dig('meta', 'chartId')
    end
    dashboard.dig('metadata', 'native_filter_configuration').each do |filter|
      next unless plan.fetch('filters').include?(filter['id'])
      filter.fetch('scope')['excluded'] = (filter.dig('scope', 'excluded') + source_ids).uniq.sort
      filter['chartsInScope'] = filter.fetch('chartsInScope').reject { |id| source_ids.include?(id) }
    end
    dashboard.dig('position', plan.fetch('formulaNode'), 'meta')['code'] = plan.fetch('formula')
  end

  def copy_baseline
    FileUtils.rm_rf(BASELINE)
    FileUtils.cp_r(CLIENT, BASELINE)
    File.write(File.join(BASELINE, 'manifest.json'), JSON.pretty_generate({
      'profile' => 'client-baseline',
      'source' => 'production-september-2026',
      'sourceSha256' => Digest::SHA256.file(File.join(ROOT, 'sources/exports/production-september-2026/dashboard.zip')).hexdigest,
      'charts' => 20,
      'datasets' => 6,
      'filters' => 6,
      'reportingRowsIncluded' => false
    }) + "\n")
  end

  def build_update
    client_database_path = Dir[File.join(CLIENT, 'databases/*.yaml')].fetch(0)
    client_database = read(client_database_path)
    reviewed_database = read(Dir[File.join(REVIEWED, 'databases/*.yaml')].fetch(0))
    client_dashboard_path = Dir[File.join(CLIENT, 'dashboards/*.yaml')].fetch(0)
    client_dashboard = read(client_dashboard_path)
    reviewed_dashboard = read(Dir[File.join(REVIEWED, 'dashboards/*.yaml')].fetch(0))
    client_datasets = definitions(CLIENT, 'datasets')
    reviewed_datasets = definitions(REVIEWED, 'datasets')
    client_charts = definitions(CLIENT, 'charts')
    reviewed_charts = definitions(REVIEWED, 'charts')

    raise 'Expected six client datasets' unless client_datasets.length == 6
    raise 'Expected six reviewed datasets' unless reviewed_datasets.length == 6
    raise 'Expected twenty client charts' unless client_charts.length == 20
    raise 'Expected twenty-one reviewed charts' unless reviewed_charts.length == 21
    raise 'Dataset names differ' unless client_datasets.keys.sort == reviewed_datasets.keys.sort
    missing_client_charts = client_charts.keys - reviewed_charts.keys
    raise "Reviewed dashboard lost client charts: #{missing_client_charts}" unless missing_client_charts.empty?

    apply_panel_overlay(reviewed_dashboard, reviewed_charts)
    relations = relation_mapping(client_datasets, reviewed_datasets)
    uuid_mapping = {reviewed_database.fetch('uuid') => client_database.fetch('uuid'),
                    reviewed_dashboard.fetch('uuid') => client_dashboard.fetch('uuid')}
    reviewed_datasets.each do |name, (_, reviewed)|
      uuid_mapping[reviewed.fetch('uuid')] = client_datasets.fetch(name).last.fetch('uuid')
    end
    reviewed_charts.each do |name, (_, reviewed)|
      next unless client_charts.key?(name)
      uuid_mapping[reviewed.fetch('uuid')] = client_charts.fetch(name).last.fetch('uuid')
    end

    FileUtils.rm_rf(UPDATE)
    FileUtils.mkdir_p(File.join(UPDATE, 'databases'))
    FileUtils.cp(client_database_path, File.join(UPDATE, 'databases', File.basename(client_database_path)))
    FileUtils.cp(File.join(REVIEWED, 'metadata.yaml'), File.join(UPDATE, 'metadata.yaml'))

    reviewed_datasets.each do |name, (_, reviewed)|
      client_path, client = client_datasets.fetch(name)
      target = rewrite(reviewed, uuid_mapping)
      target['table_name'] = client.fetch('table_name')
      target['schema'] = client['schema'] if client.key?('schema')
      # The PostgreSQL catalog selects the database used by this virtual
      # dataset. It is environment-specific: retain the client value (`data`)
      # instead of carrying the local demo catalog (`csim_demo`) from review.
      target['catalog'] = client['catalog'] if client.key?('catalog')
      target['database_uuid'] = client_database.fetch('uuid')
      relations.each do |before, after|
        target['sql'] = target['sql'].gsub(%("v1"."#{before}"), %("v1"."#{after}")) if target['sql']
      end
      write(File.join(UPDATE, 'datasets', client_database.fetch('database_name'), File.basename(client_path)), target)
    end

    reviewed_charts.each do |name, (reviewed_path, reviewed)|
      target = rewrite(reviewed, uuid_mapping)
      output_name = client_charts.key?(name) ? File.basename(client_charts.fetch(name).first) : File.basename(reviewed_path)
      write(File.join(UPDATE, 'charts', output_name), target)
    end

    target_dashboard = rewrite(reviewed_dashboard, uuid_mapping)
    %w[dashboard_title slug published].each do |field|
      target_dashboard[field] = client_dashboard[field] if client_dashboard.key?(field)
    end
    write(File.join(UPDATE, 'dashboards', File.basename(client_dashboard_path)), target_dashboard)

    File.write(File.join(UPDATE, 'manifest.json'), JSON.pretty_generate({
      'profile' => 'client-update',
      'clientBaseline' => 'production-september-2026',
      'clientBaselineSha256' => Digest::SHA256.file(File.join(ROOT, 'sources/exports/production-september-2026/dashboard.zip')).hexdigest,
      'reviewedSource' => 'sources/live-review/2026-09-17T163028Z',
      'panelCoverageOverlay' => 'dashboard/overlays/beth-panel-coverage.json',
      'charts' => 21,
      'datasets' => 6,
      'filters' => 6,
      'databaseUuid' => client_database.fetch('uuid'),
      'dashboardUuid' => client_dashboard.fetch('uuid'),
      'preservedRelations' => relations,
      'reportingRowsIncluded' => false,
      'requiresSuperset61ReferenceRepair' => true
    }) + "\n")
  end

  def build
    copy_baseline
    build_update
    puts JSON.generate({baseline: BASELINE, update: UPDATE})
  end
end

ClientUpdate.build if $PROGRAM_NAME == __FILE__
