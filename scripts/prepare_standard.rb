#!/usr/bin/env ruby
# Standard application comparisons: shared queries, no custom frontend settings.
require_relative 'prepare_reconciled'

module StandardDashboard
  def self.build(profile, fixture: false, sortable: false, orientation: 'VERTICAL')
    source_profile = fixture ? 'reconciled-examples' : 'reconciled'
    source = File.join(ReconciledDashboard::ROOT, 'dashboard', source_profile)
    target = File.join(ReconciledDashboard::ROOT, 'dashboard', profile)
    FileUtils.rm_rf(target)
    FileUtils.cp_r(source, target)
    files = Dir[File.join(target, '**/*.yaml')].sort
    identities = files.reject { |path| path.include?('/databases/') }.map do |path|
      identity = ReconciledDashboard.read(path)['uuid']
      [identity, ReconciledDashboard.uuid(profile, identity)] if identity
    end.compact.to_h
    files.each do |path|
      text = File.read(path)
      identities.each { |before, after| text = text.gsub(before, after) }
      item = YAML.safe_load(text)
      if path.include?('/charts/')
        params = item.fetch('params')
        selector = params.delete('csim_hospital_selector')
        if selector
          item['description'] = "Choose one numeric hospital in #{selector}. Until then this panel has no hospital result."
        end
        if params['x_axis'] == 'month_date'
          params['x_axis_time_format'] = 'smart_date'
          params.delete('tooltipTimeFormat')
          params['xAxisLabelRotation'] = 90
          params['xAxisLabelInterval'] = 0
          params['x_axis_title_margin'] = sortable ? 60 : 75
          if sortable
            params['x_axis'] = 'period_label'
            params['xAxisForceCategorical'] = true
            params['x_axis_sort'] = 'name'
            params['x_axis_sort_asc'] = true
          end
        end
        # Saved query_context can contain old/custom settings independently of params.
        item['query_context'] = nil
      elsif path.include?('/datasets/') && sortable
        if item.fetch('columns').any? { |column| column['column_name']=='month_date' }
          item['columns'] << {
            'column_name'=>'period_label', 'is_dttm'=>false, 'type'=>'VARCHAR',
            'groupby'=>true, 'filterable'=>true,
            'expression'=>%q{to_char(month_date, '{{ {'P1M': 'YYYY-MM', 'P3M': 'YYYY "Q"Q', 'P1Y': 'YYYY'}.get(time_grain, 'YYYY-MM') }}')},
            'description'=>'Chronologically sortable reporting label; month_date remains the date filter.'
          }
        end
      elsif path.include?('/dashboards/')
        item['slug'] = fixture ? "csim-#{profile}" : "csim-individual-#{profile}"
        build = profile.start_with?('development') ? 'unmodified development' : 'standard 6.1.0'
        item['dashboard_title'] = "CSiM Individual Data — September / #{build}" + (fixture ? ' / known records' : '')
        item['description'] = 'Full September dashboard with standard Superset settings and prepared SQL. Native label and filter behavior is under comparison.'
        item['metadata']['filter_bar_orientation'] = orientation
        if orientation == 'HORIZONTAL'
          # The horizontal filters stay below the dashboard title while scrolling.
          # Fragment targets must clear both fixed rows, not only the title bar.
          item['css'] = item.fetch('css', '') + "\n[id^=\"HEADER-\"] { scroll-margin-top: 160px; }\n"
          %w[MARKDOWN-4LE_6MIsEUYEjgMUcvAyM MARKDOWN-WIofdf7GkSmIbs0pSuT-6].each do |id|
            item['position'].fetch(id).fetch('meta')['code'] =
              '**Choose Your hospital in the filter bar to display the hospital comparison panels.** ' \
              'Open More filters if the selector is hidden. Then choose Cohort/State for the comparison.'
          end
          # Keep date entry out of the nested More filters popover. Its popup
          # currently disappears when its range-type menu is clicked there.
          controls = item['metadata']['native_filter_configuration']
          order = ['Time Period', 'Time Unit', 'Hospital and state', 'Location of Urine Culture Collection', 'Your hospital', 'Cohort/State']
          item['metadata']['native_filter_configuration'] = order.map { |name| controls.find { |f| f['name']==name } }
        end
        if sortable
          item['dashboard_title'] += ' / sortable labels'
          item['description'] += ' Year-first labels are a proposed wording tradeoff; they are not the exact-format acceptance result.'
        end
        # Standard empty states accompany permanent instructions; no render hook.
        item['position'].fetch('MARKDOWN-8qLF0rtVZnycDfi3XPowe').fetch('meta')['code'] +=
          "\n\n**Choose an individual hospital in Hospital and state to populate the latest-month comparison tables.** Cohort remains available for the main charts."
        if profile.start_with?('development')
          unit = item['metadata']['native_filter_configuration'].find { |f| f['name'] == 'Time Unit' }
          unit['time_grains'] = ['P1M', 'P3M', 'P1Y']
        end
      end
      ReconciledDashboard.write(path, item)
    end
    forbidden = files.select { |path| File.read(path).match?(/csim_period|csim_hospital_selector|csimMonthRange/) }
    raise "Custom settings in standard package: #{forbidden.join(', ')}" unless forbidden.empty?
    manifest = JSON.parse(File.read(File.join(target, 'manifest.json')))
    manifest.merge!('profile'=>profile, 'sourceProfile'=>source_profile,
                    'application'=>'unmodified', 'nativeAxis'=>sortable ? 'sortable-period-label' : 'smart_date',
                    'filterOrientation'=>orientation,
                    'slug'=>fixture ? "csim-#{profile}" : "csim-individual-#{profile}")
    File.write(File.join(target, 'manifest.json'), JSON.pretty_generate(manifest)+"\n")
  end
  def self.build_all
    %w[standard development].each do |profile|
      build(profile)
      build("#{profile}-examples", fixture: true)
      build("#{profile}-sortable", sortable: true, orientation: 'HORIZONTAL')
      build("#{profile}-sortable-examples", fixture: true, sortable: true, orientation: 'HORIZONTAL')
    end
  end
end

StandardDashboard.build_all if $PROGRAM_NAME == __FILE__
