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
      assert_equal 22, charts.length
      assert_equal 7, datasets.length
      charts.reject { |path| File.basename(path) == 'Reporting_period.yaml' }.each do |path|
        chart = ReconciledDashboard.read(path)
        prior = ReconciledDashboard.read(File.join(original, 'charts', File.basename(path)))
        assert_equal prior['params'], chart['params'], chart['slice_name']
        refute_equal prior['uuid'], chart['uuid']
      end
      datasets.reject { |path| File.basename(path) == 'Reporting_period.yaml' }.each do |path|
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
  def test_summary_is_separate_and_only_receives_date_controls
    summaries = %w[standard-month-selectors standard-month-selectors-examples].map do |profile|
      root = File.join(ReconciledDashboard::ROOT, 'dashboard', profile)
      dataset = ReconciledDashboard.read(File.join(root, 'datasets/PostgreSQL/Reporting_period.yaml'))
      chart = ReconciledDashboard.read(File.join(root, 'charts/Reporting_period.yaml'))
      assert_equal 'table', chart['viz_type']
      assert_equal dataset['uuid'], chart['dataset_uuid']
      assert_empty dataset['metrics']
      assert_includes dataset['sql'], 'FROM bounds'
      refute_match(/UTI Individual|UTI Aggregate|patient_id/i, dataset['sql'])
      assert_equal 2, chart['params']['row_limit']
      dashboard = ReconciledDashboard.read(Dir[File.join(root, 'dashboards/*.yaml')].first)
      assert_equal 'ROW-csim-native-period', dashboard['position']['GRID_ID']['children'].first
      filters = dashboard['metadata']['native_filter_configuration']
      filters.each do |filter|
        if ['From month', 'Through month', 'Time Unit'].include?(filter['name'])
          assert_includes filter['chartsInScope'], 108
          refute_includes filter['scope']['excluded'], 108
        else
          assert_includes filter['scope']['excluded'], 108
        end
      end
      assert_equal ['NATIVE_FILTER-csim-from_month'], filters[1]['cascadeParentIds']
      expected = profile.end_with?('-examples') ? ['2025-11', '2026-04'] : ['12 months ago', 'Last complete month']
      assert_equal expected, filters.first(2).map { |filter| filter.dig('defaultDataMask', 'filterState', 'value', 0) }
      dataset
    end
    refute_equal summaries[0]['table_name'], summaries[1]['table_name']
    refute_equal summaries[0]['uuid'], summaries[1]['uuid']
  end

end
