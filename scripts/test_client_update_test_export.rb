#!/usr/bin/env ruby
# Run on its own: the baseline is chosen when prepare_client_update is loaded.
ENV['CSIM_CLIENT_BASELINE'] = 'test-september-2026'
ENV['CSIM_UPDATE_PROFILE'] = 'client-update-test'

require 'json'
require 'minitest/autorun'
require 'yaml'
require_relative 'prepare_client_update'

class ClientUpdateTestExportTest < Minitest::Test
  LATEST_CARD_UUID = '33866218-9d48-480a-94c9-75860633d428'

  def setup
    ClientUpdate.build
    @client = ClientUpdate::CLIENT
    @update = ClientUpdate::UPDATE
  end

  def read(path)
    YAML.safe_load(File.read(path))
  end

  def items(root, pattern, key)
    Dir[File.join(root, pattern)].to_h do |path|
      value = read(path)
      [value.fetch(key), value]
    end
  end

  def relations(root)
    Dir[File.join(root, 'datasets/**/*.yaml')].flat_map do |path|
      read(path)['sql'].to_s.scan(/"v1"\."([^"]+)"/).flatten
    end.uniq.sort
  end

  def test_writes_beside_the_production_package
    assert_equal 'client-update-test', File.basename(@update)
    assert_equal 'client-baseline-test', File.basename(ClientUpdate::BASELINE)
    manifest = JSON.parse(File.read(File.join(@update, 'manifest.json')))
    assert_equal 'test-september-2026', manifest['clientBaseline']
    assert_equal 21, manifest['charts']
  end

  def test_preserves_test_instance_identities_and_connection
    client_database = read(Dir[File.join(@client, 'databases/*.yaml')].fetch(0))
    assert_equal client_database, read(Dir[File.join(@update, 'databases/*.yaml')].fetch(0))

    client_dashboard = read(Dir[File.join(@client, 'dashboards/*.yaml')].fetch(0))
    update_dashboard = read(Dir[File.join(@update, 'dashboards/*.yaml')].fetch(0))
    %w[uuid dashboard_title slug].each do |key|
      client_dashboard[key].nil? ? assert_nil(update_dashboard[key], key) : assert_equal(client_dashboard[key], update_dashboard[key], key)
    end

    client_datasets = items(@client, 'datasets/**/*.yaml', 'table_name')
    update_datasets = items(@update, 'datasets/**/*.yaml', 'table_name')
    assert_equal client_datasets.keys.sort, update_datasets.keys.sort
    client_datasets.each do |name, source|
      assert_equal source['uuid'], update_datasets.fetch(name)['uuid'], name
      assert_equal client_database['uuid'], update_datasets.fetch(name)['database_uuid'], name
      assert_equal source['catalog'], update_datasets.fetch(name)['catalog'], name
    end
  end

  def test_replaces_the_latest_data_card_in_place
    client_charts = items(@client, 'charts/*.yaml', 'slice_name')
    update_charts = items(@update, 'charts/*.yaml', 'uuid')
    assert_equal 21, client_charts.length
    assert_equal client_charts.values.map { |chart| chart['uuid'] }.sort, update_charts.keys.sort
    assert_equal 'Date of most recent data', client_charts.values.find { |chart| chart['uuid'] == LATEST_CARD_UUID }['slice_name']
    assert_equal 'Latest Urine Culture Submission', update_charts.fetch(LATEST_CARD_UUID)['slice_name']
  end

  def test_keeps_the_test_source_tables_without_demo_connection
    client_relations = relations(@client)
    assert_equal client_relations, relations(@update)
    assert_includes client_relations, 'UTI Individual Historical'
    refute_includes relations(@update), 'UTI Individual Historical 2024-2025'
    Dir[File.join(@update, '**/*.yaml')].each do |path|
      refute_includes File.read(path), 'csim_demo', path
    end
  end

  def test_contains_reviewed_layout_and_filters
    dashboard = read(Dir[File.join(@update, 'dashboards/*.yaml')].fetch(0))
    assert_equal 21, dashboard['position'].values.count { |node| node.is_a?(Hash) && node['type'] == 'CHART' }
    filters = dashboard.dig('metadata', 'native_filter_configuration').select { |item| item['type'] == 'NATIVE_FILTER' }
    assert_equal 6, filters.length
  end
end
