#!/usr/bin/env ruby
# Full September copies for the month-range workflow; existing identities stay intact.
require_relative 'prepare_reconciled'

module MonthRangeDashboard
  PROFILES = %w[reconciled-months reconciled-months-examples].freeze
  def self.build(profile, fixture: false)
    source_profile = fixture ? 'reconciled-examples' : 'reconciled'
    source = File.join(ReconciledDashboard::ROOT, 'dashboard', source_profile)
    target = File.join(ReconciledDashboard::ROOT, 'dashboard', profile)
    FileUtils.rm_rf(target)
    FileUtils.cp_r(source, target)
    files = Dir[File.join(target, '**/*.yaml')].sort
    identities = files.reject { |path| path.include?('/databases/') }.map do |path|
      identity = ReconciledDashboard.read(path)['uuid']
      [identity, ReconciledDashboard.uuid(profile, identity)] if identity
    end.compact.to_h
    slug = fixture ? "csim-#{profile}" : "csim-individual-#{profile}"
    # Superset resolves the rolling default at query time. Complete months keep
    # the inclusive fields honest; fixture workflows retain explicit windows.
    window = fixture ? '2025-11-01 : 2026-05-01' : "DATETRUNC(DATEADD(DATETIME('today'), -1, YEAR), MONTH) : DATETRUNC(DATETIME('today'), MONTH)"
    files.each do |path|
      text = File.read(path)
      identities.each { |before, after| text = text.gsub(before, after) }
      item = YAML.safe_load(text)
      if path.include?('/dashboards/')
        item['slug'] = slug
        item['dashboard_title'] = 'CSiM Individual Data — September / month range controls' + (fixture ? ' / known records' : '')
        item['description'] = 'Full September dashboard. From month and Through month include both complete months; Group by changes buckets without widening the selected window.'
        controls = item.fetch('metadata').fetch('native_filter_configuration')
        grain = controls.find { |filter| filter['filterType'] == 'filter_timegrain' }
        grain['name'] = 'Group by'
        grain['time_grains'] = %w[P1M P3M P1Y]
        period = controls.find { |filter| filter['filterType'] == 'filter_time' }
        period['name'] = 'Reporting months'
        period['description'] = 'Both endpoints include the entire month. The default is the last 12 complete months; Group by does not add observations outside it.'
        period['controlValues'] = {'enableEmptyFilter'=>true, 'csimMonthRange'=>true, 'csimGrainFilterId'=>grain.fetch('id')}
        period['defaultDataMask'] = {'extraFormData'=>{'time_range'=>window}, 'filterState'=>{'value'=>window}}
      elsif path.include?('/datasets/')
        # Superset also matches imports by database/schema/table_name. Separate
        # UUIDs alone do not isolate these virtual datasets from their source.
        item['table_name'] = 'Month controls — ' + item['table_name']
      elsif path.include?('/charts/')
        item['query_context'] = nil
      end
      ReconciledDashboard.write(path, item)
    end
    manifest = JSON.parse(File.read(File.join(target, 'manifest.json')))
    manifest.merge!('profile'=>profile, 'sourceProfile'=>source_profile, 'slug'=>slug,
                    'controls'=>'inclusive-month-range', 'defaultTimeRange'=>window)
    File.write(File.join(target, 'manifest.json'), JSON.pretty_generate(manifest)+"\n")
  end
  def self.build_all
    build(PROFILES[0])
    build(PROFILES[1], fixture: true)
  end
end

MonthRangeDashboard.build_all if $PROGRAM_NAME == __FILE__
