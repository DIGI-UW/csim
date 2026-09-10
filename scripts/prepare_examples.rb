#!/usr/bin/env ruby
require 'digest'
require 'fileutils'
require 'yaml'
root=File.expand_path('..',__dir__)
source=File.join(root,'dashboard','corrected')
target=File.join(root,'dashboard','examples')
FileUtils.rm_rf(target)
FileUtils.cp_r(source,target)
files=Dir[File.join(target,'**','*.yaml')].sort
def example_uuid(source)
  hex=Digest::SHA256.hexdigest('https://csim.uwdigi.org/examples/'+source)[0,32]
  hex[12]='5';hex[16]='8'
  [hex[0,8],hex[8,4],hex[12,4],hex[16,4],hex[20,12]].join('-')
end
mapping=files.map{|path|item=YAML.safe_load(File.read(path));item['uuid']}.compact.to_h{|uuid|[uuid,example_uuid(uuid)]}
files.each do |path|
  text=File.read(path)
  mapping.each{|before,after|text=text.gsub(before,after)}
  text=text.gsub('csim_demo','csim_fixture').gsub('CSiM demo PostgreSQL','CSiM edge-case PostgreSQL')
  if path.include?('/datasets/')
    data=YAML.safe_load(text)
    data['table_name']='Examples — '+data['table_name']
    text=YAML.dump(data).gsub(/: \n/,":\n").gsub(/^(\s*-) +\n/,"\\1\n")
  end
  if path.include?('/dashboards/')
    data=YAML.safe_load(text)
    data['slug']='csim-filter-examples'
    data['dashboard_title']='CSiM date and filter examples — known test records'
    text=YAML.dump(data).gsub(/: \n/,":\n").gsub(/^(\s*-) +\n/,"\\1\n")
  end
  File.write(path,text)
end
