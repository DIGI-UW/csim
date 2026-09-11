#!/usr/bin/env ruby
# frozen_string_literal: true

# Build the two Superset-native packages from the preserved April export.
# The source export is never edited.  `dashboard/baseline` is a portable copy
# with only its local connection template changed; `dashboard/corrected` has
# the minimum date/filter changes required for the demonstration.

require 'fileutils'
require 'yaml'
require 'date'

ROOT = File.expand_path('..', __dir__)
SOURCE = File.join(ROOT, 'sources', 'exports', 'april-2026', 'unpacked',
                   'dashboard_export_20260423T185803')
OUTPUT = File.join(ROOT, 'dashboard')
DATABASE_URI = 'postgresql+psycopg2://csim:XXXXXXXXXX@db:5432/csim_demo'
TIME_SERIES = [
  'Inappropriate UTI diagnosis (time series) - Ind',
  'Abx duration (time series) - Ind',
  'Volume of UC submissions (time series) - Ind',
  'Inappropriate UTI+ASPN diagnosis (time series) - Ind',
  'Positive UA (time series) - Ind'
].freeze

def load_yaml(path)
  YAML.safe_load(File.read(path), permitted_classes: [Date, Time], aliases: true)
end

def write_yaml(path, value)
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, YAML.dump(value).gsub(/: \n/, ":\n").gsub(/^(\s*-) +\n/, "\\1\n"))
end

def normalized_database!(package)
  paths = Dir[File.join(package, 'databases', '*.yaml')]
  raise 'expected exactly one database definition' unless paths.length == 1
  path = paths.first
  database = load_yaml(path)
  database['database_name'] = 'CSiM demo PostgreSQL'
  database['sqlalchemy_uri'] = DATABASE_URI
  database.delete('password')
  database.delete('encrypted_extra')
  write_yaml(path, database)
end

def copied_package(name)
  target = File.join(OUTPUT, name)
  FileUtils.rm_rf(target)
  FileUtils.mkdir_p(target)
  FileUtils.cp_r(Dir[File.join(SOURCE, '*')], target)
  normalized_database!(target)
  Dir[File.join(target, 'datasets', '**', '*.yaml')].each do |path|
    dataset = load_yaml(path)
    # PostgreSQL catalog overrides the database name in the connection URI.
    # Keep the supplied warehouse isolated under its local deployment name.
    dataset['catalog'] = 'csim_demo' if dataset['catalog'] == 'data'
    write_yaml(path, dataset)
  end
  target
end

def dynamic_aggregate_sql(source_sql)
  normal = source_sql.gsub("\r\n", "\n").strip.sub(/;\s*\z/, '')
  match = normal.match(/\AWITH raw_data AS \((.*?)\),\s*hospital_agg AS/m)
  raise 'April aggregate SQL no longer has the expected raw_data CTE' unless match

  raw = match[1]
  continuation = normal[match.end(0)..]
  continuation = continuation.sub(/ORDER BY month_date, hosp_code, location_code\s*\z/m, '')
  # Raw observations are constrained before their month/year keys are replaced.
  # The remainder of the original query therefore calculates each measure from
  # the selected raw records, rather than taking the highest monthly rate.
  adapted = <<~SQL
    WITH source_raw AS (
    #{raw}
    ), raw_data AS (
      SELECT hosp_name, location, sign_symp,
             EXTRACT(MONTH FROM date_trunc('{{ grain }}', make_date(year::int, month::int, 1)))::int AS month,
             EXTRACT(YEAR FROM date_trunc('{{ grain }}', make_date(year::int, month::int, 1)))::int AS year,
             ucx_positive, urinalysis, tx___1, duration
      FROM source_raw
      WHERE TRUE
      {% if from_dttm %} AND make_date(year::int, month::int, 1) >= TIMESTAMP '{{ from_dttm }}' {% endif %}
      {% if to_dttm %} AND make_date(year::int, month::int, 1) < TIMESTAMP '{{ to_dttm }}' {% endif %}
    ), hospital_agg AS
    #{continuation}
  SQL

  <<~SQL
    {% set applied_time = get_time_filter('month_date', strftime='%Y-%m-%d %H:%M:%S', remove_filter=True) %}
    {% if from_dttm is not defined %}{% set from_dttm = applied_time.from_expr %}{% endif %}
    {% if to_dttm is not defined %}{% set to_dttm = applied_time.to_expr %}{% endif %}
    {% set grain = {'P1M': 'month', 'P3M': 'quarter', 'P1Y': 'year'}.get(time_grain, 'month') %}
    {% set grain_interval = {'month': '1 month', 'quarter': '3 months', 'year': '1 year'}[grain] %}
    WITH observed AS (
    #{adapted}
    ), bounds AS (
      SELECT {% if from_dttm %} TIMESTAMP '{{ from_dttm }}' {% else %} first_date {% endif %} AS start_at,
             {% if to_dttm %} TIMESTAMP '{{ to_dttm }}' {% else %} last_date + INTERVAL '{{ grain_interval }}' {% endif %} AS end_at
      FROM (SELECT MIN(month_date) AS first_date, MAX(month_date) AS last_date FROM observed) extent
    ), calendar AS (
      SELECT value::date AS month_date
      FROM bounds, LATERAL generate_series(
        date_trunc('{{ grain }}', start_at),
        date_trunc('{{ grain }}', end_at - INTERVAL '1 microsecond'),
        INTERVAL '{{ grain_interval }}'
      ) AS value
    ), dimensions AS (
      SELECT DISTINCT hosp_num, hosp_code, state, location_name, location_code
      FROM observed
    )
    SELECT d.hosp_num, d.hosp_code, d.state, d.location_name, d.location_code,
           c.month_date,
           o.ucsub, o.txpos, o.asbtreated, o.aspn_treated, o.asbcase, o.pos_ua,
           o.dur_sum, o.dur_count, o.dur_cat_1, o.dur_cat_2, o.dur_cat_3, o.dur_cat_4,
           o.inappdx, o.inappdx_aspn, o.prev, o.txrate, o.pos_ua_rate, o.medabxdur
    FROM dimensions d CROSS JOIN calendar c
    LEFT JOIN observed o ON o.hosp_code = d.hosp_code
      AND o.location_code = d.location_code AND o.month_date = c.month_date
    ORDER BY c.month_date, d.hosp_code, d.location_code
  SQL
end

def corrected_package!(package)
  dashboard_paths = Dir[File.join(package, 'dashboards', '*.yaml')]
  raise 'expected exactly one dashboard definition' unless dashboard_paths.length == 1
  dashboard_path = dashboard_paths.first
  dashboard = load_yaml(dashboard_path)
  dashboard['dashboard_title'] = 'CSiM UTI/ASB Dashboard [Individual Data] — corrected demo'
  dashboard['slug'] = 'csim-individual-corrected'
  dashboard['description'] = 'Reproducible CSiM dashboard using the supplied demonstration database.'

  filters = dashboard.fetch('metadata').fetch('native_filter_configuration')
  filters.each do |filter|
    case filter['name']
    when 'Time Period'
      filter['description'] = 'Select the reporting dates. This limits the observations before they are grouped.'
    when 'Time Unit'
      filter['description'] = 'Group the selected observations by Month, Quarter, or Year.'
    end
  end
  write_yaml(dashboard_path, dashboard)

  aggregate_paths = Dir[File.join(package, 'datasets', '**', 'UTI_Aggregate_ALL_DATA_*.yaml')]
  raise 'expected exactly one aggregate dataset definition' unless aggregate_paths.length == 1
  aggregate_path = aggregate_paths.first
  aggregate = load_yaml(aggregate_path)
  aggregate['sql'] = dynamic_aggregate_sql(aggregate.fetch('sql'))
  aggregate['main_dttm_col'] = 'month_date'
  write_yaml(aggregate_path, aggregate)

  Dir[File.join(package, 'charts', '*.yaml')].each do |path|
    chart = load_yaml(path)
    params = chart.fetch('params')
    next unless params['x_axis'] == 'month_date'
    # Clearing the shared control exposes this saved fallback. All source dates
    # represent months; Day is also disabled by the released instance policy.
    params['time_grain_sqla'] = 'P1M'
    params['x_axis'] = 'month_date'
    params['granularity_sqla'] = 'month_date'
    params['xAxisForceCategorical'] = false
    params['xAxisLabelRotation'] = 0
    params['x_axis_time_format'] = 'csim_period'
    params['tooltipTimeFormat'] = 'csim_period'
    params['order_desc'] = false
    params['row_limit'] = 1000
    params['show_empty_columns'] = true if TIME_SERIES.include?(chart['slice_name'])
    params.fetch('adhoc_filters', []).each do |filter|
      filter['subject'] = 'month_date' if filter['operator'] == 'TEMPORAL_RANGE'
    end
    write_yaml(path, chart)
  end
end

FileUtils.rm_rf(OUTPUT)
baseline = copied_package('baseline')
baseline_dashboard_paths = Dir[File.join(baseline, 'dashboards', '*.yaml')]
raise 'expected exactly one baseline dashboard definition' unless baseline_dashboard_paths.length == 1
baseline_dashboard_path = baseline_dashboard_paths.first
baseline_dashboard = load_yaml(baseline_dashboard_path)
baseline_dashboard['slug'] = 'csim-individual-baseline'
baseline_dashboard['description'] = 'Unchanged April 2026 CSiM export, connected only to the supplied demonstration database.'
write_yaml(baseline_dashboard_path, baseline_dashboard)

corrected = copied_package('corrected')
corrected_package!(corrected)

preview = File.join(OUTPUT, 'preview')
FileUtils.cp_r(corrected, preview)
preview_dashboard_path = Dir[File.join(preview, 'dashboards', '*.yaml')].first
preview_dashboard = load_yaml(preview_dashboard_path)
preview_dashboard['slug'] = 'csim-individual-preview'
preview_dashboard['dashboard_title'] = 'CSiM UTI/ASB Dashboard [Individual Data] — upstream snapshot'
preview_dashboard['metadata']['native_filter_configuration'].each do |filter|
  filter['time_grains'] = %w[P1M P3M P1Y] if filter['filterType'] == 'filter_timegrain'
end
write_yaml(preview_dashboard_path, preview_dashboard)

require_relative 'prepare_hourly'
require_relative 'prepare_examples'

puts "Prepared #{baseline} and #{corrected} from the preserved April export."
