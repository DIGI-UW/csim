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

    # Section links stay on this dashboard and do not restore a saved filter state.
    headers = dashboard['position'].values.select { |node| node.is_a?(Hash) && node['type'] == 'HEADER' && node['meta']['text'].match?(/^\d+[.]/) }.sort_by { |node| node['meta']['text'].split(' ').first.split('.').map(&:to_i) }
    toc = headers.map do |node|
      text = node.fetch('meta').fetch('text')
      "- [#{text}](##{node.fetch('id')})"
    end
    dashboard['position']['MARKDOWN-kbpKudPZL01ntlPcgzEYI']['meta']['code'] = "### **Table of Contents**\n" + toc.join("\n")
    dashboard['position']['MARKDOWN-WIofdf7GkSmIbs0pSuT-6']['meta']['height'] = 7

    test_charts = Dir[File.join(source, 'charts/*.yaml')].to_h { |path| item = read(path); [item.fetch('uuid'), [path, item]] }
    Dir[File.join(target, 'charts/*.yaml')].each do |path|
      chart = read(path)
      original = test_charts.fetch(chart.fetch('uuid')).last
      chart['params']['y_axis_format'] = original['params']['y_axis_format'] if original['params']['y_axis_format'] == ',.0%'
      if chart['slice_name'].include?('stacked')
        chart['params']['adhoc_filters'].each do |filter|
          next unless filter['subject']=='hosp_code' && ['IN','NOT IN'].include?(filter['operator'])
          predicate = filter['operator']=='IN' ? NAMED : NUMERIC
          filter.merge!('expressionType'=>'SQL', 'sqlExpression'=>predicate, 'subject'=>nil,
                        'operator'=>nil, 'operatorId'=>nil, 'comparator'=>nil)
        end
      end
      write(path, chart)
    end
    latest_path, latest = test_charts.fetch(LATEST)
    latest['query_context'] = nil
    latest['description'] = 'Latest month with urine culture submissions for the selected hospital/state and collection location. Independent of Time Period, Time Unit and the lower comparison selectors.'
    latest['params'].merge!(
      'metric' => {'expressionType'=>'SQL', 'sqlExpression'=>'MAX(CASE WHEN ucsub > 0 THEN month_date END)', 'label'=>'Latest reporting month', 'hasCustomLabel'=>true},
      'time_grain_sqla'=>'P1M', 'time_format'=>'%b %Y', 'force_timestamp_formatting'=>true,
      'subtitle'=>'Latest month with submissions', 'header_font_size'=>0.7
    )
    write(File.join(target, 'charts', File.basename(latest_path)), latest)

    chart_ids = dashboard['position'].values.map { |node| node['meta']['chartId'] if node.is_a?(Hash) && node['type']=='CHART' }.compact
    metadata = dashboard.fetch('metadata')
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

ReconciledDashboard.build('reconciled')
ReconciledDashboard.build('reconciled-examples', fixture: true)
