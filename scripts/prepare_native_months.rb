#!/usr/bin/env ruby
# Isolated native Select-filter comparison; no changes to Superset source.
require_relative 'prepare_reconciled'

module NativeMonthDashboard
  PREFIX = <<~JINJA.freeze
    {% set from_values = filter_values('from_month', remove_filter=True) %}
    {% set through_values = filter_values('through_month', remove_filter=True) %}
    {% set last_month = get_time_filter(default='Last month', strftime='%Y-%m-%d', remove_filter=True) %}
    {% set current_month = (last_month.to_expr | to_datetime('%Y-%m-%d')).replace(day=1) %}
    {% set rolling_start = current_month.replace(year=current_month.year - 1).strftime('%Y-%m-%d 00:00:00') %}
    {% set rolling_end = current_month.strftime('%Y-%m-%d 00:00:00') %}
    {% set month_cache_key = cache_key_wrapper(rolling_end) %}
    {% set native_from = rolling_start if from_values and from_values[0] == '12 months ago' else (from_values[0] | to_datetime('%Y-%m')).strftime('%Y-%m-%d 00:00:00') if from_values else none %}
    {% if through_values and through_values[0] == 'Last complete month' %}
      {% set native_to = rolling_end %}
    {% elif through_values %}
      {% set through = through_values[0] | to_datetime('%Y-%m') %}
      {% set native_to = through.replace(year=through.year + (1 if through.month == 12 else 0), month=through.month % 12 + 1).strftime('%Y-%m-%d 00:00:00') %}
    {% else %}{% set native_to = none %}{% endif %}
  JINJA

  def self.add_period_summary(target, profile)
    source_dataset = ReconciledDashboard.read(File.join(target, 'datasets/PostgreSQL/UTI_Aggregate_ALL_DATA_40.yaml'))
    dataset = source_dataset.merge('table_name'=>"Reporting period — #{profile}",
      'uuid'=>ReconciledDashboard.uuid(profile, 'native-reporting-period-dataset'),
      'description'=>'Selected month boundaries and validation only; no reporting records or measures.',
      'metrics'=>[], 'columns'=>[], 'sql'=>PREFIX + <<~SQL)
        WITH bounds AS (
          SELECT {% if native_from %}TIMESTAMP '{{ native_from }}'{% else %}NULL::timestamp{% endif %} AS first_month,
                 {% if native_to %}TIMESTAMP '{{ native_to }}'{% else %}NULL::timestamp{% endif %} AS after_last_month
        )
        SELECT COALESCE(to_char(first_month, 'Mon YYYY'), 'No start limit') AS "From",
               COALESCE(to_char(after_last_month - INTERVAL '1 month', 'Mon YYYY'), 'No end limit') AS "Through",
               '{{ {'P1M':'Month', 'P3M':'Quarter', 'P1Y':'Year'}.get(time_grain, 'Month') }}'::text AS "Group by",
               CASE WHEN first_month >= after_last_month THEN
                 'Choose a Through month on or after ' || to_char(first_month, 'Mon YYYY') || '. The selected range is reversed.'
               WHEN '{{ time_grain }}' IN ('P3M', 'P1Y') THEN
                 'Only the selected months contribute to each ' || '{{ {'P3M':'quarter', 'P1Y':'year'}.get(time_grain, 'period') }}' || '. Changing Group by keeps these dates.'
               ELSE 'Both endpoint months are included. All-time totals and latest-month comparisons keep their own coverage.' END AS "Status",
               NULL::text AS from_month, NULL::text AS through_month, CURRENT_DATE AS month_date
        FROM bounds
      SQL
    %w[From Through Status from_month through_month].each do |name|
      dataset['columns'] << {'column_name'=>name, 'is_dttm'=>false, 'type'=>'VARCHAR', 'groupby'=>true, 'filterable'=>true}
    end
    dataset['columns'] << {'column_name'=>'Group by', 'is_dttm'=>false, 'type'=>'VARCHAR', 'groupby'=>true, 'filterable'=>true}
    dataset['columns'] << {'column_name'=>'month_date', 'is_dttm'=>true, 'type'=>'DATE', 'groupby'=>true, 'filterable'=>true}
    ReconciledDashboard.write(File.join(target, 'datasets/PostgreSQL/Reporting_period.yaml'), dataset)
    chart_id = 108
    chart_uuid = ReconciledDashboard.uuid(profile, 'native-reporting-period-chart')
    chart = {'slice_name'=>'Reporting period', 'description'=>'Resolved dates and guidance for the applied month selection.',
      'viz_type'=>'table', 'uuid'=>chart_uuid, 'version'=>'1.0.0', 'dataset_uuid'=>dataset['uuid'], 'query_context'=>nil,
      'params'=>{'datasource'=>'108__table', 'slice_id'=>chart_id, 'viz_type'=>'table', 'query_mode'=>'raw',
        'all_columns'=>['From', 'Through', 'Group by', 'Status'], 'groupby'=>[], 'metrics'=>[], 'adhoc_filters'=>[],
        'order_by_cols'=>[], 'row_limit'=>2, 'server_pagination'=>false, 'include_search'=>false, 'show_totals'=>false,
        'show_cell_bars'=>false, 'time_grain_sqla'=>'P1M', 'column_config'=>{'From'=>{'columnWidth'=>110}, 'Through'=>{'columnWidth'=>110}, 'Group by'=>{'columnWidth'=>90}, 'Status'=>{'columnWidth'=>420, 'truncateLongCells'=>false}},
        'extra_form_data'=>{}, 'dashboards'=>[]}}
    ReconciledDashboard.write(File.join(target, 'charts/Reporting_period.yaml'), chart)
    path = Dir[File.join(target, 'dashboards/*.yaml')].fetch(0)
    dashboard = ReconciledDashboard.read(path)
    row, node = 'ROW-csim-native-period', 'CHART-csim-native-period'
    dashboard['position']['GRID_ID']['children'].unshift(row)
    dashboard['position'][row] = {'id'=>row, 'type'=>'ROW', 'children'=>[node], 'parents'=>['ROOT_ID','GRID_ID'],
      'meta'=>{'background'=>'BACKGROUND_TRANSPARENT'}}
    dashboard['position'][node] = {'id'=>node, 'type'=>'CHART', 'children'=>[], 'parents'=>['ROOT_ID','GRID_ID',row],
      'meta'=>{'chartId'=>chart_id, 'sliceName'=>'Reporting period', 'uuid'=>chart_uuid, 'width'=>12, 'height'=>16}}
    dashboard['metadata']['native_filter_configuration'].each do |filter|
      if ['From month', 'Through month', 'Time Unit'].include?(filter['name'])
        filter['chartsInScope'] = filter.fetch('chartsInScope', []) | [chart_id]
      else
        filter['scope']['excluded'] = filter['scope'].fetch('excluded', []) | [chart_id]
      end
    end
    dashboard['metadata']['global_chart_configuration']['chartsInScope'] |= [chart_id]
    ReconciledDashboard.write(path, dashboard)
  end

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
            #{PREFIX}
            {% if columns == ['from_month'] or columns == ['through_month'] %}
            {% set from_dttm = none %}{% set to_dttm = none %}
            WITH reporting_extent AS (
            #{original_sql}
            ), available_months AS (
              SELECT generate_series(
                LEAST(date_trunc('year', MIN(month_date)), TIMESTAMP '{{ rolling_start }}'),
                GREATEST(date_trunc('year', MAX(month_date)) + INTERVAL '11 months', TIMESTAMP '{{ rolling_end }}'),
                INTERVAL '1 month')::date AS month_date
              FROM reporting_extent
            )
            SELECT month_date FROM available_months
            {% if columns == ['through_month'] and native_from %}
              WHERE month_date >= TIMESTAMP '{{ native_from }}'
            {% endif %}
            UNION ALL SELECT NULL::date AS month_date
            {% if columns == ['through_month'] and native_from %}
              WHERE TIMESTAMP '{{ rolling_end }}' > TIMESTAMP '{{ native_from }}'
            {% endif %}
            {% else %}
            {% set from_dttm = native_from %}{% set to_dttm = native_to %}
            #{original_sql}
            {% endif %}
          SQL
          %w[from_month through_month].each do |name|
            item['columns'] << {'column_name'=>name, 'is_dttm'=>false, 'type'=>'VARCHAR',
              'groupby'=>true, 'filterable'=>true, 'expression'=>"CASE WHEN month_date IS NULL THEN '#{name == 'from_month' ? '12 months ago' : 'Last complete month'}' ELSE to_char(month_date, 'YYYY-MM') END"}
          end
        end
      elsif path.include?('/dashboards/')
        item['slug'] = fixture ? "csim-#{profile}" : "csim-individual-#{profile}"
        item['dashboard_title'] = 'CSiM Individual Data — September / native month selectors' + (fixture ? ' / known records' : '')
        item['description'] = 'Official Superset with native From/Through month dropdowns. The opening window follows the last 12 complete months. Choose named months for a fixed window. Clearing an endpoint removes that bound.'
        controls = item.fetch('metadata').fetch('native_filter_configuration')
        period = controls.find { |f| f['filterType']=='filter_time' }
        grain = controls.find { |f| f['filterType']=='filter_timegrain' }
        dataset = grain.fetch('targets').first.fetch('datasetUuid')
        start_month, end_month = fixture ? ['2025-11', '2026-04'] : ['12 months ago', 'Last complete month']
        months = [['from_month', 'From month', start_month], ['through_month', 'Through month', end_month]].map do |column, name, value|
          filter = Marshal.load(Marshal.dump(period))
          filter.merge!('id'=>"NATIVE_FILTER-csim-#{column}", 'name'=>name, 'filterType'=>'filter_select',
            'targets'=>[{'datasetUuid'=>dataset, 'column'=>{'name'=>column}}],
            'description'=> column == 'from_month' ? 'Includes the whole starting month. 12 months ago moves forward each month. Clear for no start boundary.' : 'Includes the whole ending month. Last complete month moves forward each month. Choices follow From month. Clear for no end boundary.',
            'controlValues'=>{'sortAscending'=>true, 'enableEmptyFilter'=>false, 'defaultToFirstItem'=>false,
              'creatable'=>false, 'multiSelect'=>false, 'searchAllOptions'=>false, 'inverseSelection'=>false},
            'defaultDataMask'=>{'extraFormData'=>{'filters'=>[{'col'=>column, 'op'=>'IN', 'val'=>[value]}]},
              'filterState'=>{'label'=>value, 'value'=>[value]}})
          filter['cascadeParentIds'] = ['NATIVE_FILTER-csim-from_month'] if column == 'through_month'
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
    add_period_summary(target, profile)
    manifest = JSON.parse(File.read(File.join(target, 'manifest.json')))
    manifest.merge!('profile'=>profile, 'sourceProfile'=>source_profile, 'filters'=>7,
      'charts'=>22, 'datasets'=>7, 'reportingCharts'=>21, 'reportingDatasets'=>6, 'controlSummaryCharts'=>1,
      'controls'=>'native-month-selectors', 'filterOrientation'=>'HORIZONTAL',
      'slug'=>fixture ? "csim-#{profile}" : "csim-individual-#{profile}")
    File.write(File.join(target, 'manifest.json'), JSON.pretty_generate(manifest)+"\n")
  end
end

if $PROGRAM_NAME == __FILE__
  NativeMonthDashboard.build
  NativeMonthDashboard.build(fixture: true)
end
