#!/usr/bin/env ruby
# frozen_string_literal: true

require 'digest'
require 'json'
require 'yaml'

ROOT = File.expand_path('..', __dir__)
EXPORTS = {
  'april-2026' => '77feeece79e20a833d347a77d0bd05b2f9d4e3449d1142a7123c4d9133ce380e',
  'test-september-2026' => 'e26150df97ed91545916440f186ae882a83d7fff0811049a80797fafe829e619',
  'production-september-2026' => '2fc2f69283ff72fe955952f939a712529b093262ad1a713c82c86f996327deec'
}.freeze
DUMP = '6726a084cc7b3b2daa288423ae9f8123b5f865867795278043ce5d9f77f542f9'

def digest(path)
  Digest::SHA256.file(path).hexdigest
end

report = { 'exports' => {}, 'demo_dump_sha256' => digest(File.join(ROOT, 'data', 'v1_schema_dump.sql')) }
EXPORTS.each do |name, expected|
  archive = File.join(ROOT, 'sources', 'exports', name, 'dashboard.zip')
  raise "checksum mismatch for #{name}" unless digest(archive) == expected
  roots = Dir[File.join(ROOT, 'sources', 'exports', name, 'unpacked', '*')]
  raise "expected one unpacked root for #{name}" unless roots.length == 1
  root = roots.first
  dashboards = Dir[File.join(root, 'dashboards', '*.yaml')]
  raise "expected one dashboard for #{name}" unless dashboards.length == 1
  dashboard = YAML.safe_load(File.read(dashboards.first), aliases: true)
  charts = Dir[File.join(root, 'charts', '*.yaml')]
  datasets = Dir[File.join(root, 'datasets', '**', '*.yaml')]
  report['exports'][name] = {
    'sha256' => expected,
    'dashboard_uuid' => dashboard['uuid'],
    'title' => dashboard['dashboard_title'],
    'charts' => charts.length,
    'datasets' => datasets.length,
    'timestamp' => YAML.safe_load(File.read(File.join(root, 'metadata.yaml')), aliases: true)['timestamp']
  }
end
raise 'demo dump checksum mismatch' unless report['demo_dump_sha256'] == DUMP
raise 'April baseline must contain exactly 20 charts' unless report['exports']['april-2026']['charts'] == 20
raise 'Test export must contain exactly 21 charts' unless report['exports']['test-september-2026']['charts'] == 21
raise 'Production export must contain exactly 20 charts' unless report['exports']['production-september-2026']['charts'] == 20
puts JSON.pretty_generate(report)
