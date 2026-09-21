# Standalone admin chart outside the dashboard and its filter scopes.
require_relative 'prepare_reconciled'
module AggregateDownload
  def self.add(target, profile)
    dataset = ReconciledDashboard.read(File.join(target, 'datasets/PostgreSQL/UTI_Aggregate_ALL_DATA_40.yaml'))
    identity = ReconciledDashboard.uuid(profile, 'aggregate-all-data-download')
    columns = dataset.fetch('columns').map { |column| column.fetch('column_name') }
    first = %w[hosp_code hosp_num state location_name location_code month_date]
    columns = first + (columns - first)
    chart = {
      'slice_name'=>'Aggregate ALL DATA — Download',
      'description'=>'All rows calculated by UTI Aggregate ALL DATA, without an additional aggregation or dashboard filters. After uploading Current, refresh this chart and download CSV. The row limit is 100,000; verify the export count when the source grows.',
      'viz_type'=>'table', 'uuid'=>identity, 'version'=>'1.0.0', 'dataset_uuid'=>dataset.fetch('uuid'), 'query_context'=>nil,
      'params'=>{'datasource'=>'40__table', 'slice_id'=>109, 'viz_type'=>'table', 'query_mode'=>'raw',
        'all_columns'=>columns, 'groupby'=>[], 'metrics'=>[], 'adhoc_filters'=>[], 'time_range'=>'No filter',
        'time_grain_sqla'=>'P1M', 'order_by_cols'=>[], 'row_limit'=>100000, 'server_pagination'=>false,
        'page_length'=>50, 'include_search'=>true, 'show_totals'=>false, 'show_cell_bars'=>false,
        'extra_form_data'=>{}, 'dashboards'=>[]}
    }
    ReconciledDashboard.write(File.join(target, 'charts/Aggregate_ALL_DATA_Download.yaml'), chart)
    manifest_path = File.join(target, 'manifest.json')
    manifest = JSON.parse(File.read(manifest_path))
    manifest['standaloneCharts'] = [{'uuid'=>identity, 'sourceId'=>109, 'name'=>chart['slice_name']}]
    File.write(manifest_path, JSON.pretty_generate(manifest)+"\n")
  end
end
