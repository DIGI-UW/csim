import {test,expect} from '@playwright/test';
import {execFileSync} from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import {root,recording} from '../acceptance.config.mjs';
import {scene,enableRecording} from '../acceptance/recording.mjs';

enableRecording(test);
test('13 Download Current and Historical individual records to CSV',async({page},info)=>{
  const query={filters:[{col:'slice_name',opr:'eq',value:'Individual records — Review and download'}]};
  const found=await page.request.get('/api/v1/chart/?q='+encodeURIComponent(JSON.stringify(query)));
  expect(found.ok()).toBeTruthy();const charts=(await found.json()).result;expect(charts).toHaveLength(1);
  const chart=charts[0];expect(chart.dashboards).toHaveLength(0);
  await page.goto('/explore/?slice_id='+chart.id);
  for(const name of ['source','record_ID','redcap_repeat_instance'])await expect(page.getByRole('columnheader',{name,exact:true})).toBeVisible();
  const table=page.getByRole('table').filter({has:page.getByRole('columnheader',{name:'record_ID',exact:true})});
  await expect(table.getByRole('cell',{name:'source',exact:true}).first()).toContainText('Current');
  const search=page.getByPlaceholder(/records\.\.\./);
  await expect(search).toBeVisible();
  await expect(page.locator('.ant-spin-spinning')).toHaveCount(0);
  info._csimScenes.push({publish:false,atSeconds:(Date.now()-info._csimStart)/1000});
  await scene(page,info,'current-identifiers','Review records','Current rows keep record_ID and redcap_repeat_instance. Each row is an individual submission.');

  await search.fill('Historical');
  await expect(table.getByRole('cell',{name:'source',exact:true}).first()).toContainText('Historical');
  await expect(table.getByRole('cell',{name:'redcap_repeat_instance',exact:true}).first()).toHaveText(/^(?:N\/A)?$/);
  await scene(page,info,'historical-identifiers','Review records','Historical rows keep record_ID. Their repeat-instance value is blank because that field is not in the source.');

  await search.fill('');
  await expect(table.getByRole('cell',{name:'source',exact:true}).first()).toContainText('Current');
  const fresh=page.waitForResponse(response=>response.url().includes('/api/v1/chart/data')&&response.request().method()==='POST');
  await page.getByRole('button',{name:'Update chart',exact:true}).click();
  const response=await fresh;expect(response.ok()).toBeTruthy();const body=await response.json();
  const result=body.result[0];expect(result.status).toBe('success');expect(result.error).toBeFalsy();expect(result.cache_timeout).toBe(-1);
  const rows=result.data;expect(rows.length).toBeGreaterThan(0);
  const sources=[...new Set(rows.map(row=>row.source))].sort();expect(sources).toEqual(['Current','Historical']);
  fs.writeFileSync(info.outputPath('refresh-verification.json'),JSON.stringify({responseStatus:response.status(),rows:rows.length,sources,isCached:result.is_cached,cacheTimeout:result.cache_timeout,requestForce:response.request().postDataJSON()?.force},null,2));
  await expect(page.locator('.ant-spin-spinning')).toHaveCount(0);
  await scene(page,info,'refresh-current-data','Refresh after an upload','Click Update chart to query the current source tables before downloading. No dashboard date or hospital filters are applied.','Refresh and download');

  await page.getByRole('button',{name:'Menu actions trigger',exact:true}).click();
  await page.getByRole('menuitem',{name:'Data Export Options right',exact:true}).press('ArrowRight');
  await page.getByRole('menuitem',{name:'Export All Data right',exact:true}).press('ArrowRight');
  const csvItem=page.getByRole('menuitem',{name:'file Export to .CSV',exact:true});
  await expect(csvItem).toBeVisible();
  if(recording)await page.waitForTimeout(2200);
  const menuShot=info.outputPath('export-all-data-menu.png');
  await page.screenshot({path:menuShot});await info.attach('export-all-data-menu',{path:menuShot,contentType:'image/png'});
  info._csimScenes.push({name:'export-all-data-menu',chapter:'Download CSV',caption:'Open ⋯ → Data Export Options → Export All Data → Export to .CSV.',atSeconds:(Date.now()-info._csimStart)/1000});
  const pending=page.waitForEvent('download');await csvItem.press('Enter');
  const download=await pending;expect(await download.failure()).toBeNull();
  const csv=info.outputPath('record-review.csv');await download.saveAs(csv);
  const oracle=info.outputPath('oracle.json');
  execFileSync('docker',['cp',`${process.env.CSIM_ORACLE_CONTAINER||'csim-standard-superset-1'}:/tmp/csim-record-review-oracle.json`,oracle]);
  const checked=execFileSync('python3',[path.join(root,'scripts/verify_record_csv.py'),oracle,csv],{encoding:'utf8'});
  const verified=JSON.parse(checked);expect(verified.allValuesMatch).toBe(true);expect(verified.rows).toBe(rows.length);
  fs.writeFileSync(info.outputPath('csv-verification.json'),checked);
  await scene(page,info,'download-complete','CSV downloaded',`${verified.rows.toLocaleString('en-US')} rows and ${verified.columns} columns downloaded. All values and duplicate submissions match the checked source records.`);
});
