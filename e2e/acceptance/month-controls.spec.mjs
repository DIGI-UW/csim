import {scene,enableRecording} from './recording.mjs';
import {test,expect} from '@playwright/test';
import {profile,fixture,reconciled} from '../acceptance.config.mjs';
import {openDashboard,timeUnit,timePeriod,allTrends,hospital,location,filters,paintedLabels} from './dashboard.mjs';

enableRecording(test);
test('07 Inclusive month controls recover on the same page and never widen a partial quarter',async({page},info)=>{
 test.skip(process.env.CSIM_SIMPLE_CONTROLS!=='1','This dashboard is available only in the month-controls build.');
 const watch=await openDashboard(page,profile);
 const marker=await page.evaluate(()=>window.__monthDocument=crypto.randomUUID());
 const from=page.getByLabel('From month',{exact:true}),through=page.getByLabel('Through month (inclusive)',{exact:true});
 const apply=page.getByRole('button',{name:'Apply filters',exact:true});
 const now=new Date(),start=new Date(Date.UTC(now.getUTCFullYear()-1,now.getUTCMonth(),1)),end=new Date(Date.UTC(now.getUTCFullYear(),now.getUTCMonth()-1,1));
 await expect(from).toHaveValue(reconciled&&!fixture?start.toISOString().slice(0,7):'2025-11');
 await expect(through).toHaveValue(reconciled&&!fixture?end.toISOString().slice(0,7):'2026-04');
 if(fixture)await hospital(page,'91');
 const initial=await allTrends(watch);
 if(reconciled&&!fixture){
  const until=Date.UTC(now.getUTCFullYear(),now.getUTCMonth(),1);
  for(const rows of Object.values(initial))for(const row of rows){
   expect(Number(row.month_date)).toBeGreaterThanOrEqual(start.getTime());
   expect(Number(row.month_date)).toBeLessThan(until);
  }
 }
 await watch.trends[0].holder.scrollIntoViewIfNeeded();
 await scene(page,info,'month-fields','Reporting months','Choose the first and last reporting month. Both endpoints include the whole month.','Choose months and grouping');
 await timePeriod(page,'2026-02-01','2026-04-01');
 await timeUnit(page,'Quarter');
 await expect(page.getByRole('status').filter({hasText:'Partial quarters'})).toHaveText('Partial quarters — Q1 2026: Feb 2026 – Mar 2026 only.');
 const periodFirst=await allTrends(watch);
 if(fixture){
  const rows=periodFirst[watch.trends[4].name];expect(rows).toHaveLength(1);
  expect(Object.values(rows[0]).filter(v=>v!==Date.UTC(2026,0,1))).toEqual([10]);
 }
 await watch.trends[0].holder.scrollIntoViewIfNeeded();
 await expect.poll(()=>paintedLabels(watch.trends[0].plot)).toEqual(['Q1 2026']);
 await page.screenshot({path:info.outputPath('partial-quarter-controls.png')});
 await watch.trends[4].holder.scrollIntoViewIfNeeded();
 await scene(page,info,'inclusive-quarter','Quarter',fixture?'February through March gives Q1 with 10 submissions. January contributes none.':'Only February and March contribute to Q1. January is excluded.','A partial quarter');
 await timeUnit(page,'Year');
 await expect(from).toHaveValue('2026-02');await expect(through).toHaveValue('2026-03');
 await expect(page.getByRole('status').filter({hasText:'Partial years'})).toContainText('Feb 2026 – Mar 2026 only');
 const annual=await allTrends(watch);
 await watch.trends[4].holder.scrollIntoViewIfNeeded();
 await expect.poll(()=>paintedLabels(watch.trends[4].plot)).toEqual(['2026']);
 if(fixture)expect(annual[watch.trends[4].name].map(row=>Object.values(row).filter(v=>v!==row.month_date))).toEqual([[10]]);
 await scene(page,info,'inclusive-year','Year','Changing Group by keeps the same months. The note identifies the partial year.');
 await timePeriod(page,'2025-11-01','2026-05-01');
 await timeUnit(page,'Quarter');
 await timePeriod(page,'2026-02-01','2026-04-01');
 const unitFirst=await allTrends(watch);
 for(const [name,rows] of Object.entries(periodFirst)){
  expect(unitFirst[name]).toHaveLength(rows.length);
  rows.forEach((row,i)=>Object.entries(row).forEach(([key,v])=>typeof v==='number'&&!Number.isInteger(v)?expect(unitFirst[name][i][key]).toBeCloseTo(v,12):expect(unitFirst[name][i][key]).toEqual(v)));
 }
 const selected=JSON.stringify(unitFirst);
 await from.fill('2026-05');
 await expect(page.getByRole('alert').filter({hasText:'From month must'})).toBeVisible();
 await expect(apply).toBeDisabled();
 await page.screenshot({path:info.outputPath('invalid-range.png')});
 await scene(page,info,'invalid-months','Invalid range','A reversed or incomplete range cannot be applied. The displayed chart remains unchanged.','Correct and clear');
 expect(JSON.stringify(await allTrends(watch))).toBe(selected);
 await from.fill('2026-02');await through.fill('');await expect(apply).toBeDisabled();
 await through.fill('2026-03');
 if(await apply.isEnabled())await apply.click();
 await page.waitForLoadState('networkidle');
 await page.getByRole('button',{name:'Clear all',exact:true}).click();
 await expect(from).toHaveValue('');await expect(through).toHaveValue('');await expect(apply).toBeDisabled();
 await from.fill('2025-11');await through.fill('2026-04');
 await location(page,'All locations');
 // Stage a valid time range before applying the restored hospital selection.
 await hospital(page,fixture?'91':'31');
 await expect(page.getByRole('combobox',{name:filters.hospital,exact:true}).locator('xpath=ancestor::*[contains(concat(" ",normalize-space(@class)," ")," ant-select ")][1]')).toContainText(fixture?'91':'31');
 await timeUnit(page,'Month');
 const restored=await allTrends(watch);
 await expect(page.getByRole('combobox',{name:filters.hospital,exact:true}).locator('xpath=ancestor::*[contains(concat(" ",normalize-space(@class)," ")," ant-select ")][1]')).toContainText(fixture?'91':'31');
 expect(Object.values(restored).every(rows=>rows.length>0)).toBe(true);
 if(fixture)expect(restored[watch.trends[4].name].map(row=>Object.values(row).filter(v=>v!==row.month_date))).toEqual([[4],[8],[12],[null],[10],[5]]);
 expect(await page.evaluate(()=>window.__monthDocument)).toBe(marker);
 await watch.trends[0].holder.scrollIntoViewIfNeeded();
 await page.screenshot({path:info.outputPath('restored-month-controls.png')});
 await scene(page,info,'months-restored','Results return','After Clear all, reselect both months and a hospital. The charts recover on this same page.');
 await watch.settle();expect(watch.failures).toEqual([]);
 await info.attach('month-window-results',{body:Buffer.from(JSON.stringify({periodFirst,unitFirst})),contentType:'application/json'});
});
