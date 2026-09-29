#!/usr/bin/env ruby
# Build destination-neutral Superset 6.1.0 UI imports for the CSiM client update.
require 'digest'
require 'fileutils'
require 'json'
require 'tmpdir'
require 'yaml'

ROOT = File.expand_path('..', __dir__)
SOURCE = File.join(ROOT, 'dashboard/client-update')
OUTPUT = File.join(ROOT, 'release/client-update/manual')
FIXED_TIME = Time.utc(1980, 1, 1)

PACKAGES = [
  ['01-csim-reporting-datasets.zip', 'SqlaTable', %w[databases datasets]],
  ['02-csim-dashboard-charts.zip', 'Slice', %w[databases datasets charts]],
  ['03-csim-dashboard.zip', 'Dashboard', %w[databases datasets charts dashboards]]
].freeze

def read(path)
  YAML.safe_load(File.read(path))
end

def write(path, value)
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, YAML.dump(value).gsub(/^ +'$/, "'").gsub(/: \n/, ":\n").gsub(/^(\s*-) +\n/, "\\1\n"))
end

def without_source_ids(value)
  case value
  when Hash
    value.each_with_object({}) do |(key, item), clean|
      clean[key] = without_source_ids(item) unless %w[slice_id dashboards].include?(key)
    end
  when Array then value.map { |item| without_source_ids(item) }
  else value
  end
end

def copy_definition(source, destination)
  value = read(source)
  if source.include?('/charts/')
    value['params'] = without_source_ids(value.fetch('params'))
    if value['query_context'].is_a?(String) && !value['query_context'].empty?
      value['query_context'] = JSON.generate(without_source_ids(JSON.parse(value['query_context'])))
    end
    write(destination, value)
  elsif source.include?('/dashboards/')
    metadata = value.fetch('metadata')
    metadata.fetch('native_filter_configuration').each { |filter| filter.delete('chartsInScope') }
    metadata.fetch('global_chart_configuration', {}).delete('chartsInScope')
    # Cross filtering is disabled in this dashboard. This saved block is a
    # source-instance cache whose keys and members are numeric chart IDs.
    metadata.delete('chart_configuration')
    write(destination, value)
  else
    FileUtils.mkdir_p(File.dirname(destination))
    FileUtils.cp(source, destination)
  end
end

def build(filename, type, directories)
  Dir.mktmpdir('csim-manual-') do |temporary|
    prefix = File.basename(filename, '.zip')
    root = File.join(temporary, prefix)
    FileUtils.mkdir_p(root)
    File.write(File.join(root, 'metadata.yaml'), <<~YAML)
      version: 1.0.0
      type: #{type}
      timestamp: '2026-09-17T16:30:29.547086+00:00'
    YAML
    directories.each do |directory|
      Dir[File.join(SOURCE, directory, '**/*.yaml')].sort.each do |source|
        copy_definition(source, source.sub(SOURCE, root))
      end
    end
    Dir[File.join(root, '**/*')].each { |path| File.utime(FIXED_TIME, FIXED_TIME, path) }
    destination = File.join(OUTPUT, filename)
    FileUtils.rm_f(destination)
    Dir.chdir(temporary) do
      files = Dir.glob("#{prefix}/**/*", File::FNM_DOTMATCH).select { |path| File.file?(path) }.sort
      abort 'zip failed' unless system('zip', '-X', '-q', destination, *files)
    end
    destination
  end
end

FileUtils.mkdir_p(OUTPUT)
files = PACKAGES.map { |package| build(*package) }
checksums = files.map { |path| "#{Digest::SHA256.file(path).hexdigest}  #{File.basename(path)}" }.join("\n") + "\n"
File.write(File.join(OUTPUT, 'SHA256SUMS'), checksums)
print checksums
