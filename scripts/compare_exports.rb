#!/usr/bin/env ruby
# frozen_string_literal: true
require 'yaml'
require 'json'
require 'date'
require 'digest'
require 'fileutils'

ROOT = File.expand_path('..', __dir__)
VERSIONS = %w[april-2026 test-september-2026 production-september-2026].freeze
def read_yaml(path)
  YAML.safe_load(File.read(path), permitted_classes: [Date, Time], aliases: true)
end
def normalized(value)
  case value
  when Hash
    value.reject { |key, _| %w[id datasource slice_id dashboards created_on changed_on].include?(key) }
         .map { |key, child| [key, normalized(child)] }.to_h
  when Array then value.map { |child| normalized(child) }
  else value
  end
end
def differences(before, after, path = '')
  if before.is_a?(Hash) && after.is_a?(Hash)
    (before.keys | after.keys).sort.flat_map { |key| differences(before[key], after[key], "#{path}/#{key}") }
  elsif before != after
    [{ 'field' => path, 'april' => before, 'later' => after }]
  else []
  end
end

versions = VERSIONS.map do |name|
  root = File.join(ROOT, 'sources/exports', name)
  package = Dir[File.join(root, 'unpacked/*')].find { |path| File.directory?(path) }
  objects = %w[charts datasets dashboards].map do |type|
    [type, Dir[File.join(package, type, '**/*.yaml')].sort.map { |path| value=read_yaml(path); [value['uuid'], value] }.sort.to_h]
  end.to_h
  objects['sha256'] = Digest::SHA256.file(File.join(root, 'dashboard.zip')).hexdigest
  objects['export_metadata'] = read_yaml(File.join(package, 'metadata.yaml'))
  sql_dir = File.join(ROOT, 'sources/sql', name)
  FileUtils.mkdir_p(sql_dir)
  objects['datasets'].each do |uuid, dataset|
    File.write(File.join(sql_dir, "#{uuid}.sql"), dataset.fetch('sql', '').to_s.gsub("\r\n", "\n") + "\n")
  end
  [name, objects]
end.to_h
baseline = versions.fetch('april-2026')
raise 'April must contain 20 charts and 6 datasets' unless baseline['charts'].length == 20 && baseline['datasets'].length == 6
report = {'versions' => {}, 'comparisons' => {}}
versions.each do |name, objects|
  report['versions'][name] = {
    'sha256' => objects['sha256'], 'metadata' => objects['export_metadata'],
    'charts' => objects['charts'].transform_values { |chart| chart['slice_name'] },
    'datasets' => objects['datasets'].transform_values { |dataset| dataset['table_name'] },
    'dashboard_uuid' => objects['dashboards'].keys.first,
  }
  next if name == 'april-2026'
  report['comparisons'][name] = %w[charts datasets dashboards].map do |type|
    pairs = (baseline[type].keys | objects[type].keys).map do |uuid|
      before, after = baseline[type][uuid], objects[type][uuid]
      # Numeric chart and dataset ids are compared separately from definition
      # settings. Original files remain intact for complete reference checks.
      delta = differences(normalized(before), normalized(after))
      [uuid, {'name' => (after || before).values_at('slice_name', 'table_name', 'dashboard_title').compact.first, 'changes' => delta}]
    end.reject { |_, item| item['changes'].empty? }.to_h
    [type, pairs]
  end.to_h
end
FileUtils.mkdir_p(File.join(ROOT, 'sources/comparison'))
File.write(File.join(ROOT, 'sources/comparison/definitions.json'), JSON.pretty_generate(report) + "\n")
manifest = {
  'dashboard_uuid' => baseline['dashboards'].keys.first,
  'baseline' => 'april-2026', 'chart_count' => 20, 'dataset_count' => 6,
  'charts' => report['versions']['april-2026']['charts'],
  'datasets' => report['versions']['april-2026']['datasets'],
  'excluded_test_additions' => (versions['test-september-2026']['charts'].keys - baseline['charts'].keys).map { |uuid| {'uuid'=>uuid,'name'=>versions['test-september-2026']['charts'][uuid]['slice_name']} },
}
File.write(File.join(ROOT, 'sources/baseline-manifest.json'), JSON.pretty_generate(manifest) + "\n")
puts JSON.pretty_generate(report['comparisons'].transform_values { |objects| objects.transform_values { |items| items.transform_values { |item| item['changes'].map { |change| change['field'] } } } })
