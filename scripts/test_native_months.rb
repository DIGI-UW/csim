require 'minitest/autorun'
require_relative 'prepare_native_months'

class NativeMonthTest < Minitest::Test
  def test_same_content_and_separate_month_bounds
    %w[standard-month-selectors standard-month-selectors-examples].each do |profile|
      root = File.join(ReconciledDashboard::ROOT, 'dashboard', profile)
      fixture = profile.end_with?('-examples')
      original = File.join(ReconciledDashboard::ROOT, 'dashboard', fixture ? 'standard-sortable-examples' : 'standard-sortable')
      charts = Dir[File.join(root, 'charts/*.yaml')]
      datasets = Dir[File.join(root, 'datasets/**/*.yaml')]
      assert_equal 21, charts.length
      assert_equal 6, datasets.length
      charts.each do |path|
        chart = ReconciledDashboard.read(path)
        prior = ReconciledDashboard.read(File.join(original, 'charts', File.basename(path)))
        assert_equal prior['params'], chart['params'], chart['slice_name']
        refute_equal prior['uuid'], chart['uuid']
      end
      datasets.each do |path|
        item = ReconciledDashboard.read(path)
        prior = ReconciledDashboard.read(path.sub(root, original))
        assert_equal prior['metrics'], item['metrics']
        if prior['main_dttm_col'] == 'month_date'
          assert_includes item['sql'], prior['sql']
          assert_includes item['sql'], "to_datetime('%Y-%m')"
          assert_equal prior['columns'].length + 2, item['columns'].length
        else
          assert_equal prior['sql'], item['sql']
        end
      end
      dashboard = ReconciledDashboard.read(Dir[File.join(root, 'dashboards/*.yaml')].first)
      filters = dashboard['metadata']['native_filter_configuration']
      assert_equal 7, filters.length
      assert_equal ['From month','Through month'], filters.first(2).map { |f| f['name'] }
      assert_equal ['from_month','through_month'], filters.first(2).map { |f| f['targets'].first['column']['name'] }
      assert filters.first(2).all? { |f| !f['controlValues']['multiSelect'] && !f['controlValues']['creatable'] }
      assert_equal ['P1M'], filters.find { |f| f['filterType']=='filter_timegrain' }.dig('defaultDataMask','filterState','value')
      assert_empty filters.select { |f| f['filterType']=='filter_time' }
    end
  end
end
