#!/usr/bin/env ruby
require 'yaml'
require 'fileutils'
ROOT=File.expand_path('..',__dir__) unless defined?(ROOT)
def save(name,value)
  path=File.join(ROOT,'dashboard','hourly',name)
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path,YAML.dump(value).gsub(/: \n/, ":\n").gsub(/^(\s*-) +\n/, "\\1\n"))
end
base=File.join(ROOT,'dashboard','preview')
dbfile=Dir[File.join(base,'databases','*.yaml')].first
database=YAML.safe_load(File.read(dbfile))
dataset_uuid='b6ae8d10-9832-4ac4-a5b5-239d7e358c1d'
chart_uuid='7d2f40e4-1600-4e07-9d1a-2f14f34356c4'
dashboard_uuid='644b9948-4a34-4336-b028-a0625b37e85a'
save('metadata.yaml',{'version'=>'1.0.0','type'=>'Dashboard'})
save('databases/PostgreSQL.yaml',database)
save('datasets/PostgreSQL/hourly.yaml',{
  'table_name'=>'Hourly reporting example','uuid'=>dataset_uuid,'database_uuid'=>database['uuid'],
  'schema'=>'public','catalog'=>'csim_demo','main_dttm_col'=>'collected_at',
  'sql'=>"SELECT TIMESTAMP '2026-01-05' + n * INTERVAL '1 hour' AS collected_at, CASE WHEN n % 2 = 0 THEN 2 ELSE 4 END AS specimens FROM generate_series(0, 47) AS n",
  'columns'=>[{'column_name'=>'collected_at','type'=>'TIMESTAMP','is_dttm'=>true,'groupby'=>true,'filterable'=>true},{'column_name'=>'specimens','type'=>'INTEGER','is_dttm'=>false,'groupby'=>true,'filterable'=>true}],
  'metrics'=>[{'metric_name'=>'Specimens','expression'=>'SUM(specimens)'}],'version'=>'1.0.0'})
save('charts/hourly.yaml',{'slice_name'=>'Specimens by collection time','uuid'=>chart_uuid,'dataset_uuid'=>dataset_uuid,
  'viz_type'=>'echarts_timeseries_bar','version'=>'1.0.0','params'=>{
    'datasource'=>'9001__table','viz_type'=>'echarts_timeseries_bar','x_axis'=>'collected_at','granularity_sqla'=>'collected_at',
    'time_grain_sqla'=>'PT1H','time_range'=>'2026-01-05 : 2026-01-07','metrics'=>['Specimens'],'groupby'=>[],
    'adhoc_filters'=>[],'row_limit'=>1000,'order_desc'=>false,'show_legend'=>false,'x_axis_title'=>'Collection time',
    'x_axis_time_format'=>'smart_date','y_axis_format'=>',d','rich_tooltip'=>true,'color_scheme'=>'supersetColors'}})
save('dashboards/hourly.yaml',{'dashboard_title'=>'Hourly reporting — independent Time Unit choices','slug'=>'hourly-reporting-preview',
  'uuid'=>dashboard_uuid,'published'=>true,'version'=>'1.0.0','css'=>'','position'=>{
    'DASHBOARD_VERSION_KEY'=>'v2','ROOT_ID'=>{'id'=>'ROOT_ID','type'=>'ROOT','children'=>['GRID_ID']},
    'GRID_ID'=>{'id'=>'GRID_ID','type'=>'GRID','parents'=>['ROOT_ID'],'children'=>['NOTICE','ROW']},
    'HEADER_ID'=>{'id'=>'HEADER_ID','type'=>'HEADER','meta'=>{'text'=>'Hourly reporting'}},
    'NOTICE'=>{'id'=>'NOTICE','type'=>'MARKDOWN','parents'=>['ROOT_ID','GRID_ID'],'children'=>[],
      'meta'=>{'width'=>12,'height'=>14,'code'=>'This dashboard offers **Hour, Day and Week**. CSiM on this same Superset offers **Month, Quarter and Year**. These 48 hourly observations total **144 specimens**. Choosing Day gives **72 each day**.'}},
    'ROW'=>{'id'=>'ROW','type'=>'ROW','parents'=>['ROOT_ID','GRID_ID'],'children'=>['CHART'],'meta'=>{'background'=>'BACKGROUND_TRANSPARENT'}},
    'CHART'=>{'id'=>'CHART','type'=>'CHART','parents'=>['ROOT_ID','GRID_ID','ROW'],'children'=>[],
      'meta'=>{'chartId'=>9001,'uuid'=>chart_uuid,'sliceName'=>'Specimens by collection time','width'=>12,'height'=>70}}},
  'metadata'=>{'native_filter_configuration'=>[{
    'id'=>'NATIVE_FILTER-preview-hourly','name'=>'Time Unit','filterType'=>'filter_timegrain','type'=>'NATIVE_FILTER',
    'targets'=>[{'datasetUuid'=>dataset_uuid}],'scope'=>{'rootPath'=>['ROOT_ID'],'excluded'=>[]},'chartsInScope'=>[9001],
    'cascadeParentIds'=>[],'controlValues'=>{'enableEmptyFilter'=>false},'time_grains'=>['PT1H','P1D','P1W'],
    'defaultDataMask'=>{'extraFormData'=>{'time_grain_sqla'=>'PT1H'},'filterState'=>{'value'=>'PT1H','label'=>'Hour'}}
  }],'color_scheme'=>'supersetColors','cross_filters_enabled'=>false}})
