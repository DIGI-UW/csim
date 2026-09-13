require 'minitest/autorun'
require_relative 'prepare_standard'

class StandardDashboardTest < Minitest::Test
  def test_standard_packages_preserve_queries_and_remove_custom_features
    %w[standard standard-examples development development-examples].each do |profile|
      root = File.join(ReconciledDashboard::ROOT, 'dashboard', profile)
      source = File.join(ReconciledDashboard::ROOT, 'dashboard', profile.end_with?('-examples') ? 'reconciled-examples' : 'reconciled')
      files = Dir[File.join(root, 'charts/*.yaml')]
      assert_equal 21, files.length
      assert_equal 6, Dir[File.join(root, 'datasets/**/*.yaml')].length
      files.each do |file|
        chart = ReconciledDashboard.read(file)
        original = ReconciledDashboard.read(File.join(source, 'charts', File.basename(file)))
        params = chart.fetch('params')
        assert_equal original['params']['adhoc_filters'], params['adhoc_filters']
        %w[metrics metric].each do |key|
          if original['params'][key].nil?
            assert_nil params[key]
          else
            assert_equal original['params'][key], params[key]
          end
        end
        refute params.key?('csim_hospital_selector')
        assert_nil chart['query_context']
      end
      Dir[File.join(root, 'datasets/**/*.yaml')].each do |file|
        relative = file.delete_prefix(root+'/')
        assert_equal ReconciledDashboard.read(File.join(source,relative))['sql'], ReconciledDashboard.read(file)['sql']
      end
      date_axes = files.map { |f| ReconciledDashboard.read(f)['params'] }.select { |p| p['x_axis']=='month_date' }
      assert_equal 11, date_axes.length
      assert date_axes.all? { |p| p['x_axis_time_format']=='smart_date' && !p.key?('tooltipTimeFormat') && p['xAxisLabelRotation']==90 }
      assert Dir[File.join(root,'**/*.yaml')].all? { |f| !File.read(f).match?(/csim_period|csim_hospital_selector|csimMonthRange/) }
      dashboard = ReconciledDashboard.read(Dir[File.join(root,'dashboards/*.yaml')].fetch(0))
      unit = dashboard['metadata']['native_filter_configuration'].find { |f| f['name']=='Time Unit' }
      assert_equal ['P1M','P3M','P1Y'], unit['time_grains'] if profile.start_with?('development')
    end
  end
end
