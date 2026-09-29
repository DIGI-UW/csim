#!/usr/bin/env ruby
# Isolated native Select-filter comparison; no changes to Superset source.
require_relative 'prepare_reconciled'

module NativeMonthDashboard
  PREFIX = <<~JINJA.freeze
    {% set from_values = filter_values('from_month', remove_filter=True) %}
    {% set through_values = filter_values('through_month', remove_filter=True) %}
    {% set from_dttm = (from_values[0] | to_datetime('%Y-%m')).strftime('%Y-%m-%d 00:00:00') if from_values else none %}
    {% if through_values %}
      {% set through = through_values[0] | to_datetime('%Y-%m') %}
      {% set to_dttm = through.replace(year=through.year + (1 if through.month == 12 else 0), month=through.month % 12 + 1).strftime('%Y-%m-%d 00:00:00') %}
    {% else %}{% set to_dttm = none %}{% endif %}
  JINJA

  def self.build(fixture: false)
    profile = fixture ? 'standard-month-selectors-examples' : 'standard-month-selectors'
    source_profile = fixture ? 'standard-sortable-examples' : 'standard-sortable'
    target = File.join(ReconciledDashboard::ROOT, 'dashboard', profile)
    FileUtils.rm_rf(target)
    FileUtils.cp_r(File.join(ReconciledDashboard::ROOT, 'dashboard', source_profile), target)
    files = Dir[File.join(target, '**/*.yaml')].sort
    ids = files.reject { |p| p.include?('/databases/') }.map do |p|
      id = ReconciledDashboard.read(p)['uuid']
      [id, ReconciledDashboard.uuid(profile, id)] if id
    end.compact.to_h
    files.each do |path|
      text = File.read(path)
      ids.each { |before, after| text = text.gsub(before, after) }
      item = YAML.safe_load(text)
      if path.include?('/datasets/')
        item['table_name'] = 'Native month selectors — ' + item['table_name']
        if item['main_dttm_col'] == 'month_date'
          original_sql = item.fetch('sql')
          # Native Select options query the same dataset. Supply whole calendar
          # years there so a window may start before the first observed month.
          # Chart queries continue to use only the selected observations.
          item['sql'] = <<~SQL
            {% if columns == ['from_month'] or columns == ['through_month'] %}
            WITH reporting_extent AS (
            #{original_sql}
            )
            SELECT generate_series(date_trunc('year', MIN(month_date)),
              date_trunc('year', MAX(month_date)) + INTERVAL '11 months',
              INTERVAL '1 month')::date AS month_date
            FROM reporting_extent
            {% else %}
            #{PREFIX}#{original_sql}
            {% endif %}
          SQL
          %w[from_month through_month].each do |name|
            item['columns'] << {'column_name'=>name, 'is_dttm'=>false, 'type'=>'VARCHAR',
              'groupby'=>true, 'filterable'=>true, 'expression'=>"to_char(month_date, 'YYYY-MM')"}
          end
        end
      elsif path.include?('/dashboards/')
        item['slug'] = fixture ? "csim-#{profile}" : "csim-individual-#{profile}"
        item['dashboard_title'] = 'CSiM Individual Data — September / native month selectors' + (fixture ? ' / known records' : '')
        item['description'] = 'Official Superset with native From/Through month dropdowns. The saved window is explicit, not a rolling default. Clearing an endpoint removes that bound.'
        controls = item.fetch('metadata').fetch('native_filter_configuration')
        period = controls.find { |f| f['filterType']=='filter_time' }
        grain = controls.find { |f| f['filterType']=='filter_timegrain' }
        dataset = grain.fetch('targets').first.fetch('datasetUuid')
        start_month, end_month = fixture ? ['2025-11', '2026-04'] : ['2025-09', '2026-08']
        months = [['from_month', 'From month', start_month], ['through_month', 'Through month', end_month]].map do |column, name, value|
          filter = Marshal.load(Marshal.dump(period))
          filter.merge!('id'=>"NATIVE_FILTER-csim-#{column}", 'name'=>name, 'filterType'=>'filter_select',
            'targets'=>[{'datasetUuid'=>dataset, 'column'=>{'name'=>column}}],
            'description'=>'Includes the whole selected month. Clear to remove this date boundary.',
            'controlValues'=>{'sortAscending'=>true, 'enableEmptyFilter'=>false, 'defaultToFirstItem'=>false,
              'creatable'=>false, 'multiSelect'=>false, 'searchAllOptions'=>false, 'inverseSelection'=>false},
            'defaultDataMask'=>{'extraFormData'=>{'filters'=>[{'col'=>column, 'op'=>'IN', 'val'=>[value]}]},
              'filterState'=>{'label'=>value, 'value'=>[value]}})
          filter
        end
        item['metadata']['native_filter_configuration'] = months + controls.reject { |f| f==period }
        # Stable Superset's vertical sidebar omits Clear all acknowledgements.
        # The horizontal native bar forwards them; preserve the reproduced
        # vertical failure as a comparison gap, not a passing recovery claim.
        item['metadata']['filter_bar_orientation'] = 'HORIZONTAL'
      elsif path.include?('/charts/')
        item['query_context'] = nil
      end
      ReconciledDashboard.write(path, item)
    end
    manifest = JSON.parse(File.read(File.join(target, 'manifest.json')))
    manifest.merge!('profile'=>profile, 'sourceProfile'=>source_profile, 'filters'=>7,
      'controls'=>'native-month-selectors', 'filterOrientation'=>'HORIZONTAL',
      'slug'=>fixture ? "csim-#{profile}" : "csim-individual-#{profile}")
    File.write(File.join(target, 'manifest.json'), JSON.pretty_generate(manifest)+"\n")
  end
end

if $PROGRAM_NAME == __FILE__
  NativeMonthDashboard.build
  NativeMonthDashboard.build(fixture: true)
end
