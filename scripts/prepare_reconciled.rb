#!/usr/bin/env ruby
# Keep the established dashboard intact; combine its fixes with Beth's test layout.
require 'digest'
require 'fileutils'
require 'yaml'
require 'json'

module ReconciledDashboard
  ROOT = File.expand_path('..', __dir__)
  LATEST = '33866218-9d48-480a-94c9-75860633d428'
  NUMERIC = "hosp_code ~ '^[0-9]+([.][0-9]+)?$'"
  NAMED = "hosp_code !~ '^[0-9]+([.][0-9]+)?$'"
  OWN_HOSPITAL_STACKED = [
    'Top abx (own hospital stacked) - Ind',
    'UC location (own hospital stacked) - Ind',
    'Abx duration (own hospital stacked) - Ind'
  ].freeze
  HOSPITAL_PROMPT = '**Choose Your hospital in Filters and controls to display the hospital charts below.** ' \
                    'Then choose Cohort/State for the comparison charts.'
  def self.read(path)
    YAML.safe_load(File.read(path))
  end
  def self.write(path, value)
    # Psych versions indent a standalone closing quote differently; normalize that syntax.
    File.write(path, YAML.dump(value).gsub(/^ +'$/, "'").gsub(/: \n/, ":\n").gsub(/^(\s*-) +\n/, "\\1\n"))
  end
  def self.uuid(namespace, source)
    hex = Digest::SHA256.hexdigest("https://csim.uwdigi.org/#{namespace}/#{source}")[0,32]
    hex[12] = '5'; hex[16] = '8'
    [hex[0,8], hex[8,4], hex[12,4], hex[16,4], hex[20,12]].join('-')
  end
  def self.calendar_breakdown(sql, antibiotic: false)
    source = sql.gsub("\r\n", "\n").strip.sub(/;\s*\z/, '')
    series = antibiotic ? ', antibiotic_name' : ''
    selected_series = antibiotic ? ', d.antibiotic_name' : ''
    measure = antibiotic ? 'o.prescription_count, o.rnk' : 'o.n_submissions'
    series_join = antibiotic ? 'AND o.antibiotic_name = d.antibiotic_name' : ''
    <<~SQL
      {% set applied_time = get_time_filter('month_date', strftime='%Y-%m-%d %H:%M:%S') %}
      {% set start_at = from_dttm if from_dttm is defined else applied_time.from_expr %}
      {% set end_at = to_dttm if to_dttm is defined else applied_time.to_expr %}
      WITH csim_source AS (
      #{source}
      ), observed AS (
        SELECT * FROM csim_source WHERE TRUE
        {% if start_at %} AND month_date >= TIMESTAMP '{{ start_at }}' {% endif %}
        {% if end_at %} AND month_date < TIMESTAMP '{{ end_at }}' {% endif %}
      ), bounds AS (
        SELECT {% if start_at %} TIMESTAMP '{{ start_at }}' {% else %} first_month {% endif %} AS start_at,
               {% if end_at %} TIMESTAMP '{{ end_at }}' {% else %} last_month + INTERVAL '1 month' {% endif %} AS end_at
        FROM (SELECT MIN(month_date) AS first_month, MAX(month_date) AS last_month FROM observed) observed_bounds
      ), calendar AS (
        SELECT value::date AS month_date FROM bounds,
          LATERAL generate_series(date_trunc('month', start_at),
            date_trunc('month', end_at - INTERVAL '1 microsecond'), INTERVAL '1 month') AS value
      ), dimensions AS (
        SELECT DISTINCT hosp_num, hosp_code, state, location_name, location_code#{series}
        FROM observed
      )
      SELECT d.hosp_num, d.hosp_code, d.state, d.location_name, d.location_code,
             c.month_date#{selected_series}, #{measure}
      FROM dimensions d CROSS JOIN calendar c
      LEFT JOIN observed o ON o.hosp_code = d.hosp_code
        AND o.location_code IS NOT DISTINCT FROM d.location_code
        AND o.month_date = c.month_date #{series_join}
      ORDER BY c.month_date, d.hosp_code, d.location_code#{selected_series}
    SQL
  end
  def self.build(profile, fixture: false)
    source = Dir[File.join(ROOT, 'sources/exports/test-current-20260911/unpacked/*')].fetch(0)
    target = File.join(ROOT, 'dashboard', profile)
    FileUtils.rm_rf(target)
    FileUtils.cp_r(File.join(ROOT, 'dashboard/corrected'), target)
    dashboard_path = Dir[File.join(target, 'dashboards/*.yaml')].fetch(0)
    dashboard = read(dashboard_path)
    test = read(Dir[File.join(source, 'dashboards/*.yaml')].fetch(0))
    dashboard['position'] = test.fetch('position')
    dashboard['dashboard_title'] = fixture ? 'CSiM September version — known test records' : 'CSiM Individual Data — September version'
    dashboard['slug'] = fixture ? 'csim-reconciled-examples' : 'csim-individual-reconciled'
    dashboard['description'] = 'Beth’s September test layout and explanations, with date and filter corrections. The established twenty-chart version remains available separately.'
    dashboard['css'] = dashboard.fetch('css', '') + "\n/* Keep section headings below the fixed dashboard toolbar. */\n[id^=\"HEADER-\"] { scroll-margin-top: 90px; }\n"

    # Keep the lower comparison controls familiar while making their initial
    # state explicit. The chart queries below guard against an unset hospital.
    %w[MARKDOWN-4LE_6MIsEUYEjgMUcvAyM MARKDOWN-WIofdf7GkSmIbs0pSuT-6].each do |id|
      dashboard['position'].fetch(id).fetch('meta')['code'] = HOSPITAL_PROMPT
      dashboard['position'].fetch(id).fetch('meta')['height'] = 12
    end
    dashboard['position']['MARKDOWN-8qLF0rtVZnycDfi3XPowe']['meta']['code'] =
      '*Manual upload note from the source dashboard:* March 30, 2026. This is separate from the latest reporting month shown beside it.'

    # Section links stay on this dashboard and do not restore a saved filter state.
    headers = dashboard['position'].values.select { |node| node.is_a?(Hash) && node['type'] == 'HEADER' && node['meta']['text'].match?(/^\d+[.]/) }.sort_by { |node| node['meta']['text'].split(' ').first.split('.').map(&:to_i) }
    toc = headers.map do |node|
      text = node.fetch('meta').fetch('text')
      "- [#{text}](##{node.fetch('id')})"
    end
    dashboard['position']['MARKDOWN-kbpKudPZL01ntlPcgzEYI']['meta']['code'] = "### **Table of Contents**\n" + toc.join("\n")

    test_charts = Dir[File.join(source, 'charts/*.yaml')].to_h { |path| item = read(path); [item.fetch('uuid'), [path, item]] }
    Dir[File.join(target, 'charts/*.yaml')].each do |path|
      chart = read(path)
      original = test_charts.fetch(chart.fetch('uuid')).last
      chart['params']['show_empty_columns'] = true if chart['params']['x_axis']=='month_date'
      chart['params']['y_axis_format'] = original['params']['y_axis_format'] if original['params']['y_axis_format'] == ',.0%'
      if chart['slice_name'] == 'Inappropriate UTI diagnosis (latest month comparison) - Ind'
        ['Cohort', 'Your Hospital', 'Your State'].each do |column|
          chart['params'].fetch('column_config').fetch(column)['d3NumberFormat'] = ',.0%'
        end
      end
      if chart['slice_name'].include?('stacked')
        chart['params']['adhoc_filters'].each do |filter|
          next unless filter['subject']=='hosp_code' && ['IN','NOT IN'].include?(filter['operator'])
          predicate = filter['operator']=='IN' ? NAMED : NUMERIC
          filter.merge!('expressionType'=>'SQL', 'sqlExpression'=>predicate, 'subject'=>nil,
                        'operator'=>nil, 'operatorId'=>nil, 'comparator'=>nil)
        end
      end
      if OWN_HOSPITAL_STACKED.include?(chart['slice_name'])
        chart['description'] = 'Choose Your hospital in Filters and controls. No hospital data is combined while the selection is empty.'
        chart['params']['csim_hospital_selector'] = 'Your hospital'
      end
      if chart['slice_name'] == 'Volume of UC submissions (own hospital)'
        chart['description'] = 'All-time total for the selected hospital. Choose Your hospital in Filters and controls.'
        chart['params']['adhoc_filters'].reject! { |filter| filter['subject']=='hosp_code' }
        chart['params']['adhoc_filters'] << {
          'expressionType'=>'SQL', 'sqlExpression'=>NUMERIC, 'clause'=>'WHERE',
          'subject'=>nil, 'operator'=>nil, 'operatorId'=>nil, 'comparator'=>nil,
          'isExtra'=>false, 'isNew'=>false, 'datasourceWarning'=>false,
          'filterOptionName'=>'filter_csim_numeric_hospital'
        }
        chart['params']['metric'] = {
          'expressionType'=>'SQL',
          'sqlExpression'=>'SUM(ucsub)',
          'label'=>'All-time hospital submissions',
          'hasCustomLabel'=>true
        }
        chart['params']['subtitle'] = 'Choose Your hospital above'
        chart['params']['csim_hospital_selector'] = 'Your hospital'
      end
      if ['Inappropriate UTI diagnosis (latest month comparison) - Ind', 'Abx duration (latest comparison) - Ind'].include?(chart['slice_name'])
        chart['params']['csim_hospital_selector'] = 'Hospital and state'
      end
      if chart['params']['csim_hospital_selector']
        # Require one explicit hospital even when the chart is opened outside
        # the dashboard. Keep the original measures and dataset SQL intact.
        chart['params']['adhoc_filters'] << {
          'expressionType'=>'SQL',
          'sqlExpression'=>"{{ filter_values('hosp_code') | length }} = 1 AND #{NUMERIC}",
          'clause'=>'WHERE', 'isExtra'=>false,
          'filterOptionName'=>'filter_csim_selected_hospital'
        }
      end
      write(path, chart)
    end
    latest_path, latest = test_charts.fetch(LATEST)
    latest['query_context'] = nil
    latest['slice_name'] = 'Latest reporting month'
    dashboard['position'].each_value do |node|
      next unless node['type']=='CHART'
      meta = node['meta']
      meta['sliceName'] = latest['slice_name'] if meta['chartId']==107
      meta['sliceNameOverride'] = 'All-time UC submissions by your hospital' if meta['chartId']==106
      meta['sliceNameOverride'] = 'All-time UC submissions by the cohort' if meta['chartId']==100
    end
    latest['description'] = 'Latest reporting month with urine culture submissions for the selected hospital/state and collection location. Independent of Time Period, Time Unit and the lower comparison selectors.'
    latest['params'].merge!(
      'metric' => {'expressionType'=>'SQL', 'sqlExpression'=>'MAX(CASE WHEN ucsub > 0 THEN month_date END)', 'label'=>'Latest reporting month', 'hasCustomLabel'=>true},
      'time_grain_sqla'=>'P1M', 'time_format'=>'%b %Y', 'force_timestamp_formatting'=>true,
      'subtitle'=>'Latest reporting month with submissions', 'header_font_size'=>0.7
    )
    write(File.join(target, 'charts', File.basename(latest_path)), latest)

    chart_ids = dashboard['position'].values.map { |node| node['meta']['chartId'] if node.is_a?(Hash) && node['type']=='CHART' }.compact
    metadata = dashboard.fetch('metadata')
    guidance = metadata['native_filter_configuration'].find { |filter| filter['id']=='NATIVE_FILTER_DIVIDER-6zEv6G16s53VZ725ZhoAw' }
    guidance['description'] = 'Start with Cohort, or choose a hospital for the main charts and latest-month comparisons. For the lower hospital charts and all-time total, use Your hospital below.'
    metadata['chart_configuration'] = test['metadata']['chart_configuration']
    metadata['global_chart_configuration']['chartsInScope'] = chart_ids.sort
    test_filters = test['metadata']['native_filter_configuration'].to_h { |filter| [filter['id'], filter] }
    metadata['native_filter_configuration'].each do |filter|
      next unless filter['type']=='NATIVE_FILTER'
      upstream = test_filters.fetch(filter['id'])
      if ['Your hospital', 'Cohort/State'].include?(filter['name'])
        filter['adhoc_filters'] = upstream.fetch('adhoc_filters')
        filter['adhoc_filters'].first['sqlExpression'] = filter['name']=='Your hospital' ? NUMERIC : NAMED
        filter['time_range'] = 'No filter'
        filter['controlValues']['enableEmptyFilter'] = upstream['controlValues']['enableEmptyFilter']
      end
      if filter['name']=='Hospital and state' && !fixture
        filter['description'] = 'Start with the cohort view, then choose an individual hospital to review its results.'
        filter['defaultDataMask']['extraFormData']['filters'].first['val'] = ['Cohort']
        filter['defaultDataMask']['filterState'].merge!('value'=>['Cohort'], 'label'=>'Cohort')
      end
      if filter['name']=='Your hospital' && !fixture
        filter['description'] = 'Choose one hospital to display the hospital-only comparison charts and all-time submission total.'
        # Superset treats enableEmptyFilter as required and disables the whole
        # Apply button while empty. The chart query guard enforces selection.
        filter['controlValues']['enableEmptyFilter'] = false
        filter.delete('defaultDataMask')
      end
      if filter['name']=='Location of Urine Culture Collection'
        filter['controlValues']['enableEmptyFilter'] = upstream['controlValues']['enableEmptyFilter']
      end
      if ['Time Period','Time Unit','Your hospital','Cohort/State'].include?(filter['name'])
        filter['scope']['excluded'] = (filter['scope']['excluded'] + [107]).uniq
      end
      filter['chartsInScope'] = (chart_ids - filter['scope']['excluded']).sort
      if fixture && ['Hospital and state','Your hospital'].include?(filter['name'])
        hospital = JSON.parse(File.read(File.join(ROOT,'data/profiles.json'))).fetch('edge-cases').fetch('openingHospital')
        filter['defaultDataMask']['extraFormData']['filters'].first['val'] = [hospital]
        filter['defaultDataMask']['filterState'].merge!('value'=>[hospital], 'label'=>hospital)
      end
    end
    write(dashboard_path, dashboard)

    # The two breakdown datasets need calendar rows too. Their original count
    # and top-three definitions remain intact inside csim_source; absent values
    # are NULL, never an invented zero.
    Dir[File.join(target, 'datasets/**/*.yaml')].each do |path|
      dataset = read(path)
      if File.basename(path).start_with?('UTI_Top_Abx_', 'UTI_Location_')
        dataset['sql'] = calendar_breakdown(dataset['sql'], antibiotic: File.basename(path).start_with?('UTI_Top_Abx_'))
        write(path, dataset)
      end
    end

    # Chart and dataset identities are independent of all previously delivered versions.
    files = Dir[File.join(target, '**/*.yaml')].sort
    mapping = files.map do |path|
      next if path.include?('/databases/')
      identity = read(path)['uuid']
      [identity, uuid(profile, identity)] if identity
    end.compact.to_h
    if fixture
      example_database = read(Dir[File.join(ROOT,'dashboard/examples/databases/*.yaml')].fetch(0))
      database = read(Dir[File.join(target,'databases/*.yaml')].fetch(0))
      mapping[database['uuid']] = example_database['uuid']
    end
    files.each do |path|
      text = File.read(path)
      mapping.each { |before, after| text = text.gsub(before, after) }
      text = text.gsub('csim_demo','csim_fixture').gsub('CSiM demo PostgreSQL','CSiM edge-case PostgreSQL') if fixture
      item = YAML.safe_load(text)
      item['table_name'] = (fixture ? 'September examples — ' : 'September — ') + item['table_name'] if path.include?('/datasets/')
      write(path,item)
    end
    File.write(File.join(target,'manifest.json'), JSON.pretty_generate({
      'profile'=>profile, 'charts'=>21, 'datasets'=>6, 'dateAxes'=>11,
      'source'=>'test-current-20260911', 'sourceSha256'=>JSON.parse(File.read(File.join(ROOT,'sources/exports/test-current-20260911/manifest.json')))['sha256'],
      'dataProfile'=>fixture ? 'edge-cases' : 'supplied-demo', 'slug'=>dashboard['slug']
    })+"\n")
  end
end

if $PROGRAM_NAME == __FILE__
  ReconciledDashboard.build('reconciled')
  ReconciledDashboard.build('reconciled-examples', fixture: true)
end
