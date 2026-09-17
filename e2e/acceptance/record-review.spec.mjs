import {test,expect} from '@playwright/test';
import {execFileSync} from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import {root} from '../acceptance.config.mjs';

async function chart(page,name){
  const q={filters:[{col:'slice_name',opr:'eq',value:name}]};
  const r=await page.request.get('/api/v1/chart/?q='+encodeURIComponent(JSON.stringify(q)));
  expect(r.ok()).toBeTruthy();const rows=(await r.json()).result;expect(rows).toHaveLength(1);return rows[0];
}
test('Data and records shows source dependencies and the complete standalone record CSV',async({page},info)=>{
  test.skip(process.env.CSIM_NATIVE_DATES!=='1','Official supplied demo only');
  await page.goto('/superset/dashboard/csim-data-records/');
  await expect(page.getByText('Where the dashboard numbers come from',{exact:true})).toBeVisible();
  await expect(page.getByText('Uploaded records by source',{exact:true})).toBeVisible();
  await expect(page.getByText('Hospital coverage',{exact:true})).toBeVisible();
  await expect(page.getByText('Hospital missing from lookup',{exact:true}).first()).toBeVisible();
  await expect(page.locator('[data-test="chart-container"]')).toHaveCount(2);
  await expect(page.locator('.ant-spin-spinning')).toHaveCount(0);
  await page.screenshot({path:info.outputPath('data-and-records.png'),fullPage:true});
  const detail=await chart(page,'Individual records — Review and download');
  expect(detail.dashboards).toHaveLength(0);
  await page.getByRole('link',{name:'Open individual records and download CSV',exact:true}).click();
  await expect(page).toHaveURL(new RegExp('slice_id='+detail.id));
  await expect(page.getByRole('columnheader',{name:'record_ID',exact:true})).toBeVisible();
  await expect(page.getByRole('columnheader',{name:'redcap_repeat_instance',exact:true})).toBeVisible();
  await expect(page.getByRole('columnheader',{name:'source',exact:true})).toBeVisible();
  await expect(page.locator('.ant-spin-spinning')).toHaveCount(0);
  await page.screenshot({path:info.outputPath('individual-records.png')});
  await page.getByRole('button',{name:'Menu actions trigger',exact:true}).click();
  await page.getByRole('menuitem',{name:'Data Export Options right',exact:true}).press('ArrowRight');
  await page.getByRole('menuitem',{name:'Export All Data right',exact:true}).press('ArrowRight');
  const pending=page.waitForEvent('download');
  await page.getByRole('menuitem',{name:'file Export to .CSV',exact:true}).press('Enter');
  const file=info.outputPath('record-review.csv');await (await pending).saveAs(file);
  execFileSync('docker',['cp','csim-standard-superset-1:/tmp/csim-record-review-oracle.json',info.outputPath('oracle.json')]);
  const checked=execFileSync('python3',[path.join(root,'scripts/verify_record_csv.py'),info.outputPath('oracle.json'),file],{encoding:'utf8'});
  fs.writeFileSync(info.outputPath('csv-verification.json'),checked);
});

test('Maria can find the Current and Historical combination in the saved aggregate query',async({page},info)=>{
  test.skip(process.env.CSIM_NATIVE_DATES!=='1','Official query guide');
  const q={filters:[{col:'table_name',opr:'eq',value:'UTI Aggregate ALL DATA'}]};
  const response=await page.request.get('/api/v1/dataset/?q='+encodeURIComponent(JSON.stringify(q)));
  const datasets=(await response.json()).result;expect(datasets).toHaveLength(1);
  await page.goto('/explore/?datasource_type=table&datasource_id='+datasets[0].id);
  await page.getByRole('button',{name:'more',exact:true}).click();
  await page.getByRole('menuitem',{name:'Edit dataset',exact:true}).click();
  await expect(page.getByRole('dialog')).toBeVisible();
  fs.writeFileSync(info.outputPath('query-dialog.txt'),await page.getByRole('dialog').innerText());
  await expect(page.getByRole('dialog').locator('.ace_editor')).toBeVisible();
  await expect(page.getByRole('dialog').locator('.ace_line').filter({hasText:'UTI Individual Current'})).toBeVisible();
  await expect.poll(()=>page.getByRole('dialog').evaluate(el=>Number(getComputedStyle(el).opacity))).toBe(1);
  await page.screenshot({path:info.outputPath('aggregate-query-source.png')});
  await page.getByRole('dialog').locator('.ace_editor').hover();
  await page.mouse.wheel(0,155);
  await expect(page.getByRole('dialog').locator('.ace_line').filter({hasText:'UTI Individual Historical'})).toBeVisible();
  await page.screenshot({path:info.outputPath('aggregate-query-union.png')});
  await page.getByRole('button',{name:'Cancel',exact:true}).click();
});
