#!/usr/bin/env ruby
# Keep existing dashboard identities and URLs while replacing month dropdowns
# with Superset's built-in date editor. No Superset application changes.
require_relative 'prepare_native_months'

module NativeDateDashboard
  def self.build(fixture: false)
    NativeMonthDashboard.build(fixture: fixture)
    profile = fixture ? 'standard-month-selectors-examples' : 'standard-month-selectors'
    source = File.join(ReconciledDashboard::ROOT, 'dashboard', fixture ? 'standard-sortable-examples' : 'standard-sortable')
    target = File.join(ReconciledDashboard::ROOT, 'dashboard', profile)
    Dir[File.join(source, 'datasets/**/*.yaml')].each do |path|
      original = ReconciledDashboard.read(path)
      destination = path.sub(source, target)
      dataset = ReconciledDashboard.read(destination)
      # Restore the same native date filtering already used by the official
      # comparison. Remove only the retired month-menu query and columns.
      dataset['sql'] = original['sql']
      dataset['columns'] = original['columns']
      dataset['table_name'] = 'Native date entry — ' + original['table_name']
      ReconciledDashboard.write(destination, dataset)
    end
    path = Dir[File.join(target, 'dashboards/*.yaml')].fetch(0)
    dashboard = ReconciledDashboard.read(path)
    original = ReconciledDashboard.read(Dir[File.join(source, 'dashboards/*.yaml')].fetch(0))
    period = original['metadata']['native_filter_configuration'].find { |f| f['filterType'] == 'filter_time' }
    start_date, end_date = fixture ? ['2025-11-01', '2026-05-01'] : ['2025-09-01', '2026-09-01']
    time_range = "#{start_date}T00:00:00 : #{end_date}T00:00:00"
    period['defaultDataMask'] = {'extraFormData'=>{'time_range'=>time_range}, 'filterState'=>{'value'=>time_range}}
    period['description'] = 'Choose a specific start and end in Custom. The start is included; the end is excluded. For February through March, use February 1 to April 1. Reporting records are monthly.'
    period['chartsInScope'] |= [108]
    controls = dashboard['metadata']['native_filter_configuration'].reject { |f| ['From month', 'Through month'].include?(f['name']) }
    controls << period
    dashboard['metadata']['native_filter_configuration'] = ['Hospital and state', 'Location of Urine Culture Collection', 'Time Period', 'Time Unit', 'Your hospital', 'Cohort/State'].map { |name| controls.find { |f| f['name'] == name } }
    dashboard['metadata']['filter_bar_orientation'] = 'VERTICAL'
    dashboard['dashboard_title'] = 'CSiM Individual Data — September / Superset 6.1.0' + (fixture ? ' / known records' : '')
    dashboard['description'] = 'Full September dashboard on official Superset 6.1.0. Left-hand filters; Time Period opens in Custom with specific start/end dates. End is exclusive. The saved opening range is fixed.'
    dashboard['css'] = dashboard['css'].sub("\n[id^=\"HEADER-\"] { scroll-margin-top: 160px; }\n", "\n")
    %w[MARKDOWN-4LE_6MIsEUYEjgMUcvAyM MARKDOWN-WIofdf7GkSmIbs0pSuT-6].each do |id|
      dashboard['position'].fetch(id).fetch('meta')['code'] = '**Choose Your hospital in the left filter panel to display the hospital comparison panels.** Then choose Cohort/State for the comparison.'
    end
    ReconciledDashboard.write(path, dashboard)

    summary_path = File.join(target, 'datasets/PostgreSQL/Reporting_period.yaml')
    summary = ReconciledDashboard.read(summary_path)
    summary['description'] = 'Applied date boundaries and grouping; no reporting records or measures.'
    summary['sql'] = <<~SQL
      {% set period = get_time_filter('month_date', strftime='%Y-%m-%d %H:%M:%S', remove_filter=True) %}
      WITH bounds AS (
        SELECT {% if period.from_expr %}TIMESTAMP '{{ period.from_expr }}'{% else %}NULL::timestamp{% endif %} AS start_date,
               {% if period.to_expr %}TIMESTAMP '{{ period.to_expr }}'{% else %}NULL::timestamp{% endif %} AS end_date
      )
      SELECT COALESCE(to_char(start_date, 'YYYY-MM-DD HH24:MI'), 'No start limit') AS "Start",
             COALESCE(to_char(end_date, 'YYYY-MM-DD HH24:MI'), 'No end limit') AS "End (exclusive)",
             '{{ {'P1M':'Month', 'P3M':'Quarter', 'P1Y':'Year'}.get(time_grain, 'Month') }}'::text AS "Group by",
             CASE WHEN start_date >= end_date THEN 'Choose an end after the start.'
             ELSE 'Start included; end excluded. Monthly records use the first day of each month. Grouping does not expand the selected dates.' END AS "Status",
             CURRENT_DATE AS month_date
      FROM bounds
    SQL
    summary['columns'] = ['Start', 'End (exclusive)', 'Group by', 'Status'].map { |name| {'column_name'=>name, 'is_dttm'=>false, 'type'=>'VARCHAR', 'groupby'=>true, 'filterable'=>true} }
    summary['columns'] << {'column_name'=>'month_date', 'is_dttm'=>true, 'type'=>'DATE', 'groupby'=>true, 'filterable'=>true}
    ReconciledDashboard.write(summary_path, summary)
    chart_path = File.join(target, 'charts/Reporting_period.yaml')
    chart = ReconciledDashboard.read(chart_path)
    chart['description'] = 'Applied start and exclusive end, with the selected grouping.'
    chart['params']['all_columns'] = ['Start', 'End (exclusive)', 'Group by', 'Status']
    chart['params']['column_config'] = {'Start'=>{'columnWidth'=>150}, 'End (exclusive)'=>{'columnWidth'=>150}, 'Group by'=>{'columnWidth'=>90}, 'Status'=>{'columnWidth'=>420, 'truncateLongCells'=>false}}
    ReconciledDashboard.write(chart_path, chart)
    manifest_path = File.join(target, 'manifest.json')
    manifest = JSON.parse(File.read(manifest_path))
    manifest.merge!('filters'=>6, 'controls'=>'native-specific-dates', 'filterOrientation'=>'VERTICAL', 'defaultTimeRange'=>time_range)
    File.write(manifest_path, JSON.pretty_generate(manifest)+"\n")
  end
end

if $PROGRAM_NAME == __FILE__
  NativeDateDashboard.build
  NativeDateDashboard.build(fixture: true)
end
