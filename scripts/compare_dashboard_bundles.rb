#!/usr/bin/env ruby
# Compare Superset YAML definitions by persistent UUID, independent of filenames.
# Read-only: writes its result to stdout. Metadata timestamps are not objects.
require 'yaml'
require 'json'
require 'date'
abort 'Usage: ruby scripts/compare_dashboard_bundles.rb BEFORE_ROOT AFTER_ROOT' unless ARGV.length == 2

def bundle(root)
  abort "No directory: #{root}" unless Dir.exist?(root)
  %w[dashboards charts datasets databases].to_h do |kind|
    objects = {}
    Dir[File.join(root, kind, '**', '*.yaml')].sort.each do |path|
      value = YAML.safe_load(File.read(path), permitted_classes: [Date, Time], aliases: true)
      uuid = value.fetch('uuid')
      abort "Duplicate #{kind} UUID: #{uuid}" if objects.key?(uuid)
      objects[uuid] = value
    end
    [kind, objects]
  end
end

def differences(before, after, path = '')
  if before.is_a?(Hash) && after.is_a?(Hash)
    (before.keys | after.keys).sort_by(&:to_s).flat_map do |key|
      differences(before[key], after[key], "#{path}/#{key}")
    end
  elsif before != after
    [{ 'path' => path, 'before' => before, 'after' => after }]
  else
    []
  end
end

before, after = ARGV.map { |root| bundle(root) }
report = before.keys.to_h do |kind|
  objects = (before[kind].keys | after[kind].keys).sort.to_h do |uuid|
    a, b = before[kind][uuid], after[kind][uuid]
    [uuid, {
      'name' => (b || a).values_at('slice_name', 'table_name', 'dashboard_title', 'database_name').compact.first,
      'status' => a.nil? ? 'added' : b.nil? ? 'removed' : 'retained',
      'changes' => differences(a, b)
    }]
  end
  [kind, {
    'before_count' => before[kind].size,
    'after_count' => after[kind].size,
    'shared_uuid_count' => (before[kind].keys & after[kind].keys).size,
    'objects' => objects
  }]
end
puts JSON.pretty_generate(report)
