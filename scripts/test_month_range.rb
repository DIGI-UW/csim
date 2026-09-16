#!/usr/bin/env ruby
require 'minitest/autorun'
require 'yaml'
require 'json'

class MonthRangeTest < Minitest::Test
  ROOT = File.expand_path('../dashboard', __dir__)
  def package(profile)
    Dir[File.join(ROOT, profile, '**/*.yaml')].reject { |p| p.include?('/databases/') }.map { |p| YAML.safe_load(File.read(p)) }
  end
  def test_full_content_and_isolation
    %w[reconciled reconciled-examples].each do |source|
      profile = source.sub('reconciled', 'reconciled-months')
      before, after = package(source), package(profile)
      refute_empty before
      assert_empty before.map { |o| o['uuid'] }.compact & after.map { |o| o['uuid'] }.compact
      source_datasets = before.select { |o| o['table_name'] }.to_h { |o| [o['table_name'], o['sql']] }
      target_datasets = after.select { |o| o['table_name'] }.to_h { |o| [o['table_name'], o['sql']] }
      assert_equal 6, target_datasets.length
      assert_empty source_datasets.keys & target_datasets.keys, 'Superset name matching must not merge the two dataset sets'
      assert_equal source_datasets, target_datasets.transform_keys { |name| name.delete_prefix('Month controls — ') }
      assert_equal before.select { |o| o['slice_name'] }.map { |o| o['slice_name'] }.sort,
                   after.select { |o| o['slice_name'] }.map { |o| o['slice_name'] }.sort
      dashboard = after.find { |o| o['dashboard_title'] }
      original = before.find { |o| o['dashboard_title'] }
      assert_equal 21, dashboard['position'].values.count { |n| n.is_a?(Hash) && n['type']=='CHART' }
      assert_equal original['position'].select { |_, n| %w[MARKDOWN HEADER].include?(n['type']) },
                   dashboard['position'].select { |_, n| %w[MARKDOWN HEADER].include?(n['type']) }
      filters = dashboard['metadata']['native_filter_configuration']
      period = filters.find { |f| f['filterType']=='filter_time' }
      grain = filters.find { |f| f['filterType']=='filter_timegrain' }
      assert_equal true, period.dig('controlValues', 'csimMonthRange')
      assert_equal grain['id'], period.dig('controlValues', 'csimGrainFilterId')
      assert_equal original['metadata']['native_filter_configuration'].find { |f| f['filterType']=='filter_time' }['chartsInScope'], period['chartsInScope']
      assert_includes period['chartsInScope'], 107, 'Latest reporting month must stay inside the selected reporting window'
      assert_equal %w[P1M P3M P1Y], grain['time_grains']
      assert_equal JSON.parse(File.read(File.join(ROOT, profile, 'manifest.json')))['defaultTimeRange'], period.dig('defaultDataMask','extraFormData','time_range')
    end
  end
end
