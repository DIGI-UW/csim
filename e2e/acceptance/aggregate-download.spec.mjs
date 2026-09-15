import {test,expect} from '@playwright/test';
import {execFileSync} from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import {randomUUID} from 'node:crypto';
import {root,fixture} from '../acceptance.config.mjs';
import {openDashboard,hospital,timePeriod} from './dashboard.mjs';

function command(args){
  const host=process.env.CSIM_TEST_HOST;
  return execFileSync(host?'ssh':'docker',host?[host,args.map(x=>"'"+x.replaceAll("'","'\\''")+"'").join(' ')]:args.slice(1),{encoding:'utf8',timeout:60000,maxBuffer:10*1024*1024});
}
function oracle(file,flags=[]){
  const remote='/tmp/csim-download-'+randomUUID()+'.json';
  command(['docker','exec','-e','CSIM_PROJECT_ROOT='+ (process.env.CSIM_REMOTE_PROJECT_ROOT||'/repro'),'csim-standard-superset-1','python',process.env.CSIM_ORACLE_SCRIPT||'/repro/scripts/download_oracle.py','--output',remote,...(fixture?['--fixture']:[]),...flags]);
  const text=command(['docker','exec','csim-standard-superset-1','cat',remote]);
  fs.writeFileSync(file,text);return JSON.parse(text);
}
async function download(page,testInfo,name,expected){
  await page.getByRole('button',{name:'Menu actions trigger',exact:true}).click();
  await page.getByRole('menuitem',{name:'Data Export Options right',exact:true}).press('ArrowRight');
  await page.getByRole('menuitem',{name:'Export All Data right',exact:true}).press('ArrowRight');
  const pending=page.waitForEvent('download');
  await page.getByRole('menuitem',{name:'file Export to .CSV',exact:true}).press('Enter');
  const file=testInfo.outputPath(name+'.csv');await (await pending).saveAs(file);
  const report=JSON.parse(execFileSync('python3',[path.join(root,'scripts/verify_download_csv.py'),expected,file],{encoding:'utf8'}));
  await testInfo.attach(name+'-verification',{body:Buffer.from(JSON.stringify(report)),contentType:'application/json'});
  return report;
}
async function refresh(page){
  const response=page.waitForResponse(r=>r.url().includes('/api/v1/chart/data')&&r.request().method()==='POST'&&r.request().postDataJSON()?.result_format!=='csv');
  await page.getByRole('button',{name:'Update chart',exact:true}).click();
  const result=await response;expect(result.ok()).toBe(true);
  const body=await result.json();expect(body.result[0].error).toBeNull();
  return body.result[0];
}
test('Aggregate download includes all calculated rows and refreshes after a fixture CSV upload',async({page},info)=>{
  test.skip(process.env.CSIM_NATIVE_DATES!=='1','Official standalone download only');
  test.setTimeout(240000);
  const beforePath=info.outputPath('before-oracle.json');const before=oracle(beforePath);
  await openDashboard(page,'standard');
  await hospital(page,fixture?'91':'53');
  await timePeriod(page,'2026-02-01','2026-04-01');
  const link=page.getByRole('link',{name:'Aggregate ALL DATA — Download',exact:true});
  const href=await link.getAttribute('href');
  expect(href).toMatch(/^\/explore\/\?slice_id=\d+$/);
  await link.click();
  await expect(page).toHaveURL(new RegExp('/explore/\\?slice_id=\\d+'));

  await expect(page.getByRole('textbox',{name:'Chart title',exact:true})).toHaveValue('Aggregate ALL DATA — Download');
  await expect(page.getByText('Not added to any dashboard',{exact:true})).toBeVisible();
  await expect(page.getByRole('radio',{name:'Raw records',exact:true})).toBeChecked();
  const result=await refresh(page);expect(result.rowcount).toBe(before.rowCount);
  await expect(page.getByRole('textbox',{name:`Search ${before.rowCount} records`,exact:true})).toBeVisible();
  await page.screenshot({path:info.outputPath('standalone-download.png')});
  await download(page,info,'complete-export',beforePath);
  if(fixture){
    let uploaded=false;
    try{
      const afterPath=info.outputPath('after-oracle.json');const after=oracle(afterPath,['--upload-fixture']);uploaded=true;
      expect(after.sourceCount).toBe(before.sourceCount+1);
      expect(after.rowCount).toBeGreaterThan(before.rowCount);
      const may=after.rows.find(r=>r.hosp_code==='91'&&r.location_code===0&&r.period_label==='2026-05');expect(Number(may.ucsub)).toBe(1);
      const fresh=await refresh(page);expect(fresh.rowcount).toBe(after.rowCount);
      const actualMay=fresh.data.find(r=>r.hosp_code==='91'&&r.location_code===0&&r.period_label==='2026-05');expect(Number(actualMay.ucsub)).toBe(1);
      await download(page,info,'after-upload-export',afterPath);
      await page.keyboard.press('Escape');
      await page.keyboard.press('Escape');
      await expect(page.getByRole('menuitem',{name:'file Export to .CSV',exact:true})).toHaveCount(0);
      await page.getByRole('textbox',{name:`Search ${after.rowCount} records`,exact:true}).fill('2026-05');
      await expect(page.getByRole('cell',{name:'month_date',exact:true})).toHaveText(Array(8).fill('2026-05-01 00:00:00'));
      await page.screenshot({path:info.outputPath('uploaded-month-visible.png')});
      await page.getByRole('textbox',{name:`Search ${after.rowCount} records`,exact:true}).fill('');
    }finally{
      if(uploaded){
        const cleaned=oracle(info.outputPath('cleaned-oracle.json'),['--cleanup-fixture']);
        expect(cleaned.sourceHash).toBe(before.sourceHash);expect(cleaned.sourceCount).toBe(before.sourceCount);
        expect((await refresh(page)).rowcount).toBe(before.rowCount);
      }
    }
  }
});
