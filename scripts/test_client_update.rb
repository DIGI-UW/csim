#!/usr/bin/env ruby
require 'json'
require 'minitest/autorun'
require 'open3'
require 'set'
require 'yaml'
require_relative 'prepare_client_update'

class ClientUpdateTest < Minitest::Test
  ROOT = File.expand_path('..', __dir__)

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

  def test_preserves_client_identities_and_database_reference
    client_database = read(Dir[File.join(@client, 'databases/*.yaml')].fetch(0))
    update_database = read(Dir[File.join(@update, 'databases/*.yaml')].fetch(0))
    assert_equal client_database, update_database

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
    end

    client_charts = items(@client, 'charts/*.yaml', 'slice_name')
    update_charts = items(@update, 'charts/*.yaml', 'slice_name')
    assert_equal 20, client_charts.length
    assert_equal 21, update_charts.length
    client_charts.each { |name, source| assert_equal source['uuid'], update_charts.fetch(name)['uuid'], name }
    assert update_charts.key?('Latest Urine Culture Submission')
  end

  def test_release_bundle_omits_database_object_and_rehearsal_queries_connection
    bundle = File.join(ROOT, 'release/client-update/csim-client-update-dashboard.zip')
    entries, error, status = Open3.capture3('unzip', '-Z1', bundle)
    assert status.success?, error
    paths = entries.lines.map(&:strip)
    assert_equal 21, paths.count { |path| path.start_with?('csim/charts/') }
    assert_equal 6, paths.count { |path| path.start_with?('csim/datasets/') }
    refute paths.any? { |path| path.start_with?('csim/databases/') }

    receipt = JSON.parse(File.read(File.join(ROOT, 'release/client-update/rehearsal.json')))
    assert_equal false, receipt.fetch('databaseDefinitionIncludedInUpdateArchive')
    assert_equal true, receipt.fetch('databaseConnectionPreserved')
    assert_equal 'passed', receipt.fetch('databaseConnectionQueryBeforeUpdate')
    assert_equal 'passed', receipt.fetch('databaseConnectionQueryAfterEachUpdate')
    assert_equal [57], receipt.fetch('connectionCheckRows').values.uniq
  end

  def test_preserves_client_source_tables_without_demo_connection
    client_relations = Dir[File.join(@client, 'datasets/**/*.yaml')].flat_map do |path|
      read(path)['sql'].to_s.scan(/"v1"\."([^"]+)"/).flatten
    end.uniq.sort
    update_relations = Dir[File.join(@update, 'datasets/**/*.yaml')].flat_map do |path|
      dataset = read(path)
      refute_includes dataset['sql'].to_s, 'csim_demo'
      dataset['sql'].to_s.scan(/"v1"\."([^"]+)"/).flatten
    end.uniq.sort
    assert_equal client_relations, update_relations
    assert_includes update_relations, 'UTI Individual Historical 2024-2025'
  end

  def test_contains_reviewed_filters_layout_palette_and_panel_scope
    dashboard = read(Dir[File.join(@update, 'dashboards/*.yaml')].fetch(0))
    manifest = JSON.parse(File.read(File.join(@update, 'manifest.json')))
    assert_equal 21, dashboard['position'].values.count { |node| node.is_a?(Hash) && node['type'] == 'CHART' }
    assert_equal 9, dashboard.dig('position', 'MARKDOWN-kbpKudPZL01ntlPcgzEYI', 'meta', 'code').scan(/\]\(#HEADER-/).length
    assert_includes dashboard.dig('position', 'MARKDOWN-p6QkzNWJ4ubEsqJvrGV6b', 'meta', 'code'), 'Number of submissions with a positive urinalysis'
    filters = dashboard.dig('metadata', 'native_filter_configuration').select { |item| item['type'] == 'NATIVE_FILTER' }
    assert_equal 6, filters.length
    date_filters = filters.select { |item| %w[Time\ Period Time\ Unit].include?(item['name']) }
    panel_titles = JSON.parse(File.read(ClientUpdate::OVERLAY)).fetch('panels').map { |item| item['title'] }
    panel_nodes = dashboard['position'].values.select do |node|
      node.is_a?(Hash) && panel_titles.include?(node.dig('meta', 'sliceNameOverride'))
    end
    assert_equal 7, panel_nodes.length
    ids = panel_nodes.map { |node| node.dig('meta', 'chartId') }.to_set
    date_filters.each { |filter| assert ids.subset?(filter.dig('scope', 'excluded').to_set) }
    assert dashboard.dig('metadata', 'timed_refresh_immune_slices').is_a?(Array)
    assert dashboard.dig('metadata').key?('color_scheme')
    assert_equal false, manifest['reportingRowsIncluded']
  end
end
