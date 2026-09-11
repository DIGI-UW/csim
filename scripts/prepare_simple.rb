#!/usr/bin/env ruby
# A separate dashboard copy; shared dataset SQL and the original dashboards stay intact.
require 'digest'
require 'fileutils'
require 'yaml'
root=File.expand_path('..',__dir__)
[['preview','simple','csim-individual-simple'],['examples','simple-examples','csim-month-examples']].each do |source,profile,slug|
  target=File.join(root,'dashboard',profile)
  FileUtils.rm_rf(target)
  FileUtils.cp_r(File.join(root,'dashboard',source),target)
  paths=Dir[File.join(target,'charts','*.yaml')]+Dir[File.join(target,'dashboards','*.yaml')]
  mapping=paths.to_h do |path|
    uuid=YAML.safe_load(File.read(path)).fetch('uuid')
    hex=Digest::SHA256.hexdigest('https://csim.uwdigi.org/month-controls/'+uuid)[0,32]
    hex[12]='5';hex[16]='8'
    [uuid,[hex[0,8],hex[8,4],hex[12,4],hex[16,4],hex[20,12]].join('-')]
  end
  paths.each do |path|
    text=File.read(path)
    mapping.each{|before,after|text=text.gsub(before,after)}
    data=YAML.safe_load(text)
    if path.include?('/dashboards/')
      data['slug']=slug
      data['dashboard_title']=profile=='simple' ? 'CSiM Individual Data — month range controls' : 'CSiM month controls — known test records'
      data['description']='Choose From month and Through month inclusive, then group by Month, Quarter or Year. Only observations in the selected months contribute.'
      filters=data.fetch('metadata').fetch('native_filter_configuration')
      grain=filters.find{|filter|filter['filterType']=='filter_timegrain'}
      grain['name']='Group by'
      grain['time_grains']=%w[P1M P3M P1Y]
      period=filters.find{|filter|filter['filterType']=='filter_time'}
      period['name']='Reporting months'
      period['description']='Both endpoints include their entire reporting month. Changing Group by does not widen the reporting window.'
      period['controlValues']={'enableEmptyFilter'=>true,'csimMonthRange'=>true,'csimGrainFilterId'=>grain.fetch('id')}
      period['defaultDataMask']={'extraFormData'=>{'time_range'=>'2025-11-01 : 2026-05-01'},'filterState'=>{'value'=>'2025-11-01 : 2026-05-01'}}
    end
    File.write(path,YAML.dump(data).gsub(/: \n/,":\n").gsub(/^(\s*-) +\n/,"\\1\n"))
  end
end
