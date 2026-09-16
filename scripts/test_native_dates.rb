require 'minitest/autorun'
require_relative 'prepare_native_dates'

class NativeDateTest < Minitest::Test
  def test_yao_palette_is_preserved_with_hospital_legend_context
    april = ReconciledDashboard.read(Dir[File.join(ReconciledDashboard::ROOT, 'sources/exports/april-2026/unpacked/*/dashboards/*.yaml')].fetch(0))
    original = april.fetch('metadata').fetch('label_colors')
    %w[standard-month-selectors standard-month-selectors-examples].each do |profile|
      dashboard = ReconciledDashboard.read(Dir[File.join(ReconciledDashboard::ROOT, 'dashboard', profile, 'dashboards/*.yaml')].fetch(0))
      colors = dashboard.fetch('metadata').fetch('label_colors')
      assert_equal original, colors.select { |label, _| original.key?(label) }
      assert_equal '#1A5276', colors['53, Ceftriaxone']
      assert_equal '#1A5276', colors['Cohort, Ceftriaxone']
      assert_equal '#0000FC', colors['OR, Fluoroquinolone']
      assert_equal '#FC24FC', colors['31, Inpatient']
      assert_equal '#990000', colors['>7 days, 53']
      assert_equal '#1E8449', colors['<=3 days, Cohort']
      assert_equal '#1A5276', colors['91, Ceftriaxone'] if profile.end_with?('-examples')
    end
  end

  def test_preserves_reporting_content_and_uses_native_dates
    %w[standard-month-selectors standard-month-selectors-examples].each do |profile|
      root = File.join(ReconciledDashboard::ROOT, 'dashboard', profile)
      source = File.join(ReconciledDashboard::ROOT, 'dashboard', profile.end_with?('-examples') ? 'standard-sortable-examples' : 'standard-sortable')
      assert_equal 23, Dir[File.join(root, 'charts/*.yaml')].length
      assert_equal 7, Dir[File.join(root, 'datasets/**/*.yaml')].length
      Dir[File.join(source, 'charts/*.yaml')].each do |path|
        old = ReconciledDashboard.read(path)
        item = ReconciledDashboard.read(path.sub(source, root))
        assert_equal old['params'], item['params']
        assert_equal ReconciledDashboard.uuid(profile, old['uuid']), item['uuid']
      end
      Dir[File.join(source, 'datasets/**/*.yaml')].each do |path|
        old = ReconciledDashboard.read(path)
        item = ReconciledDashboard.read(path.sub(source, root))
        %w[sql columns metrics].each { |key| assert_equal old[key], item[key] }
        expected_name = if profile.end_with?('-examples')
          old['table_name'].sub(/^September examples — /, 'Known-record example — ')
        else
          old['table_name'].sub(/^September — /, '')
        end
        assert_equal expected_name, item['table_name']
      end
      dashboard = ReconciledDashboard.read(Dir[File.join(root, 'dashboards/*.yaml')].first)
      assert_equal 'VERTICAL', dashboard['metadata']['filter_bar_orientation']
      filters = dashboard['metadata']['native_filter_configuration']
      assert_equal 6, filters.length
      download = ReconciledDashboard.read(File.join(root,'charts/Aggregate_ALL_DATA_Download.yaml'))
      dataset = ReconciledDashboard.read(File.join(root,'datasets/PostgreSQL/UTI_Aggregate_ALL_DATA_40.yaml'))
      assert_equal dataset['uuid'], download['dataset_uuid']
      assert_equal 'raw', download['params']['query_mode']
      assert_equal dataset['columns'].map { |c| c['column_name'] }.sort, download['params']['all_columns'].sort
      assert_equal 'No filter', download['params']['time_range']
      assert_empty download['params']['adhoc_filters']
      assert_empty download['params']['metrics']
      assert_empty download['params']['groupby']
      assert_empty download['params']['dashboards']
      assert_equal 100000, download['params']['row_limit']
      refute dashboard['position'].values.any? { |node| node.dig('meta','uuid') == download['uuid'] if node.is_a?(Hash) }
      refute_includes dashboard['position'].fetch('MARKDOWN-8qLF0rtVZnycDfi3XPowe').dig('meta','code'), 'Aggregate ALL DATA'
      assert_equal ['Hospital and state', 'Location of Urine Culture Collection', 'Time Period', 'Time Unit', 'Your hospital', 'Cohort/State'], filters.map { |f| f['name'] }
      period = filters.find { |f| f['name']=='Time Period' }
      expected = profile.end_with?('-examples') ? '2025-11-01T00:00:00 : 2026-05-01T00:00:00' : '2025-09-01T00:00:00 : 2026-09-01T00:00:00'
      assert_equal 'filter_time', period['filterType']
      assert_equal expected, period.dig('defaultDataMask','filterState','value')
      assert_equal expected, period.dig('defaultDataMask','extraFormData','time_range')
      assert_includes period['chartsInScope'], 107
      refute_includes period['scope']['excluded'], 107
      latest = Dir[File.join(root,'charts/*.yaml')].map { |p| ReconciledDashboard.read(p) }.find { |c| c['slice_name']=='Latest reporting month in selected period' }
      assert_equal 'Latest reporting month in selected period', latest['slice_name']
      assert_includes latest['description'], 'not an upload timestamp'
      stacked = Dir[File.join(root,'charts/*.yaml')].map { |p| ReconciledDashboard.read(p) }.select { |c| ReconciledDashboard::COMPARISON_STACKED.include?(c['slice_name']) }
      assert_equal 6, stacked.length
      stacked.each { |chart| assert_equal 'hosp_code', chart.dig('params','groupby',0) }
      filters.each do |filter|
        if ['Time Period','Time Unit'].include?(filter['name'])
          assert_includes filter['chartsInScope'],108
          refute_includes filter['scope']['excluded'],108
        else
          assert_includes filter['scope']['excluded'],108
        end
      end
      summary = ReconciledDashboard.read(File.join(root,'datasets/PostgreSQL/Reporting_period.yaml'))
      assert_includes summary['sql'], 'remove_filter=True'
      refute_match(/UTI Individual|UTI Aggregate|patient_id/, summary['sql'])
      refute_match(/from_month|through_month/, summary['sql'])
      assert Dir[File.join(root,'**/*.yaml')].all? { |p| !File.read(p).match?(/csim_period|csim_hospital_selector|csimMonthRange/) }
    end
  end
end
