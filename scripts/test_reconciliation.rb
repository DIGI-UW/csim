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
      old[:datasets].each do |original|
        actual = item[:datasets].find { |d| d['table_name'].end_with?(original['table_name']) }
        if original['table_name'].match?(/UTI Top Abx|UTI Location/)
          assert_includes actual['sql'], original['sql'].gsub("\r\n", "\n").strip
          assert_includes actual['sql'], 'LEFT JOIN observed'
          refute_match(/COALESCE\(/i, actual['sql'])
        else
          assert_equal original['sql'], actual['sql']
        end
      end
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
      if node['type']=='MARKDOWN' && !%w[MARKDOWN-kbpKudPZL01ntlPcgzEYI MARKDOWN-4LE_6MIsEUYEjgMUcvAyM MARKDOWN-WIofdf7GkSmIbs0pSuT-6 MARKDOWN-8qLF0rtVZnycDfi3XPowe].include?(id)
        assert_equal node['meta']['code'],actual['meta']['code']
      end
      assert_operator actual['meta']['height'],:>,0 if actual.dig('meta','height')
    end
    filters = fresh[:dashboard]['metadata']['native_filter_configuration'].select { |f| f['type']=='NATIVE_FILTER' }
    filters.each do |filter|
      scoped = filter['chartsInScope'].include?(107)
      assert_equal ['Hospital and state','Location of Urine Culture Collection'].include?(filter['name']),scoped
    end
    card = fresh[:charts].find { |c| c['slice_name']=='Latest reporting month' }
    assert_equal 'MAX(CASE WHEN ucsub > 0 THEN month_date END)',card['params']['metric']['sqlExpression']
    toc = fresh[:dashboard]['position']['MARKDOWN-kbpKudPZL01ntlPcgzEYI']['meta']['code']
    refute_match %r{/dashboard/p/},toc
    assert_equal 9,toc.scan(/\]\(#HEADER-/).length
  end
  def test_cohort_first_hospital_guards_and_presentation
    fresh = package('reconciled')
    filters = fresh[:dashboard]['metadata']['native_filter_configuration'].select { |f| f['type']=='NATIVE_FILTER' }.to_h { |f| [f['name'],f] }
    assert_equal ['Cohort'],filters.fetch('Hospital and state').dig('defaultDataMask','filterState','value')
    refute filters.fetch('Your hospital').key?('defaultDataMask')
    assert_equal false,filters.fetch('Your hospital').dig('controlValues','enableEmptyFilter')
    assert_equal ['Cohort'],filters.fetch('Cohort/State').dig('defaultDataMask','filterState','value')

    guarded = fresh[:charts].select { |c| c['slice_name'].include?('own hospital stacked') }
    assert_equal 3,guarded.length
    guarded.each do |chart|
      assert_equal 'Your hospital',chart['params']['csim_hospital_selector']
      assert chart['params']['adhoc_filters'].any? { |f| f['sqlExpression']&.include?("filter_values('hosp_code') | length") }
    end
    total = fresh[:charts].find { |c| c['slice_name']=='Volume of UC submissions (own hospital)' }
    assert_equal 'SUM(ucsub)',total.dig('params','metric','sqlExpression')
    assert total['params']['adhoc_filters'].any? { |filter| filter['sqlExpression']=="hosp_code ~ '^[0-9]+([.][0-9]+)?$'" }

    percentage = fresh[:charts].find { |c| c['slice_name']=='Inappropriate UTI diagnosis (latest month comparison) - Ind' }
    assert_equal [',.0%'],percentage.dig('params','column_config').values.map { |config| config['d3NumberFormat'] }.compact.uniq
    note = fresh[:dashboard]['position']['MARKDOWN-WIofdf7GkSmIbs0pSuT-6']['meta']['code']
    assert_match(/Choose Your hospital/,note)
  end
  def test_live_source_checksum
    root = ROOT+'/sources/exports/test-current-20260911/'
    manifest = JSON.parse(File.read(root+'manifest.json'))
    assert_equal manifest['sha256'],Digest::SHA256.file(root+'dashboard.zip').hexdigest
  end
end
