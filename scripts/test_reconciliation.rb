#!/usr/bin/env ruby
require 'minitest/autorun'
require 'yaml'
require 'json'
require 'digest'

class ReconciliationTest < Minitest::Test
  ROOT = File.expand_path('..', __dir__)
  def package(name)
    root = File.join(ROOT,'dashboard',name)
    {
      dashboard: YAML.safe_load(File.read(Dir[root+'/dashboards/*.yaml'].fetch(0))),
      charts: Dir[root+'/charts/*.yaml'].map { |p| YAML.safe_load(File.read(p)) },
      datasets: Dir[root+'/datasets/**/*.yaml'].map { |p| YAML.safe_load(File.read(p)) }
    }
  end
  def test_separate_identities_and_preserved_sql
    old = package('corrected')
    fresh = package('reconciled')
    examples = package('reconciled-examples')
    [fresh, examples].each do |item|
      assert_equal 21,item[:charts].length
      assert_equal 6,item[:datasets].length
      assert_equal old[:datasets].map { |d| d['sql'] }.sort,item[:datasets].map { |d| d['sql'] }.sort
      assert_equal 11,item[:charts].count { |c| c['params']['x_axis_time_format']=='csim_period' }
      assert_equal 21,item[:dashboard]['position'].values.count { |n| n.is_a?(Hash) && n['type']=='CHART' }
    end
    sets = %w[corrected examples reconciled reconciled-examples].map do |name|
      item = package(name)
      ([item[:dashboard]] + item[:charts] + item[:datasets]).map { |o| o.fetch('uuid') }
    end
    sets.combination(2) { |left,right| assert_empty left & right }
  end
  def test_test_source_content_and_latest_card_scope
    root = Dir[ROOT+'/sources/exports/test-current-20260911/unpacked/*'].fetch(0)
    source = YAML.safe_load(File.read(Dir[root+'/dashboards/*.yaml'].fetch(0)))
    fresh = package('reconciled')
    source['position'].each do |id,node|
      next unless node.is_a?(Hash)
      actual = fresh[:dashboard]['position'].fetch(id)
      assert_equal node['meta']['text'],actual['meta']['text'] if node['type']=='HEADER'
      if node['type']=='MARKDOWN' && id!='MARKDOWN-kbpKudPZL01ntlPcgzEYI'
        assert_equal node['meta']['code'],actual['meta']['code']
      end
      assert_operator actual['meta']['height'],:>,0 if actual.dig('meta','height')
    end
    filters = fresh[:dashboard]['metadata']['native_filter_configuration'].select { |f| f['type']=='NATIVE_FILTER' }
    filters.each do |filter|
      scoped = filter['chartsInScope'].include?(107)
      assert_equal ['Hospital and state','Location of Urine Culture Collection'].include?(filter['name']),scoped
    end
    card = fresh[:charts].find { |c| c['slice_name']=='Date of most recent data' }
    assert_equal 'MAX(CASE WHEN ucsub > 0 THEN month_date END)',card['params']['metric']['sqlExpression']
    toc = fresh[:dashboard]['position']['MARKDOWN-kbpKudPZL01ntlPcgzEYI']['meta']['code']
    refute_match %r{/dashboard/p/},toc
    assert_equal 9,toc.scan(/\]\(#HEADER-/).length
  end
  def test_live_source_checksum
    root = ROOT+'/sources/exports/test-current-20260911/'
    manifest = JSON.parse(File.read(root+'manifest.json'))
    assert_equal manifest['sha256'],Digest::SHA256.file(root+'dashboard.zip').hexdigest
  end
end
