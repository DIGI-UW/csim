#!/usr/bin/env ruby
require 'yaml'
require 'json'
ROOT=File.expand_path('..',__dir__)
report={}
%w[april-2026 test-september-2026 production-september-2026].each do |version|
  package=Dir[File.join(ROOT,'sources','exports',version,'unpacked','*')].first
  dashboard=YAML.safe_load(File.read(Dir[File.join(package,'dashboards','*.yaml')].first))
  ids=dashboard['position'].values.select{|node|node.is_a?(Hash)&&node['type']=='CHART'}.to_h{|node|[node['meta']['chartId'],node['meta']['uuid']]}
  remap=lambda{|list|list.map{|id|ids.fetch(id,"absent-from-export:#{id}")}.sort}
  report[version]=dashboard['metadata']['native_filter_configuration'].select{|filter|filter['type']=='NATIVE_FILTER'}.to_h do |filter|
    [filter['name'],{
      'id'=>filter['id'],'type'=>filter['filterType'],'targets'=>filter['targets'],
      'defaults'=>filter['defaultDataMask'],'controls'=>filter['controlValues'],
      'exclusions_by_chart_uuid'=>remap.call(filter['scope']['excluded']||[]),
      'cached_scope_by_chart_uuid'=>remap.call(filter['chartsInScope']||[]),
      'cascade_parent_ids'=>filter['cascadeParentIds']
    }]
  end
end
File.write(File.join(ROOT,'sources/comparison/filter-scopes.json'),JSON.pretty_generate(report)+"\n")
