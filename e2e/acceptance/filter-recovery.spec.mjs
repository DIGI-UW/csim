import {randomUUID} from 'node:crypto';
import {scene,enableRecording} from './recording.mjs';
import {test,expect} from '@playwright/test';
import {profile,dataProfile,openingHospital,fixture,reconciled} from '../acceptance.config.mjs';
import {openDashboard,timeUnit,timePeriod,hospital,allTrends,filters,location,dashboardApply} from './dashboard.mjs';

enableRecording(test);
const first=dataProfile.representativeHospital;
function expectSameResults(actual,expected){
  expect(Object.keys(actual)).toEqual(Object.keys(expected));
  for(const [chart,rows] of Object.entries(expected)){
    expect(actual[chart]).toHaveLength(rows.length);
    rows.forEach((row,index)=>{
      expect(Object.keys(actual[chart][index])).toEqual(Object.keys(row));
      for(const [key,value] of Object.entries(row)){
        // PostgreSQL floating-point aggregates can differ at the last binary
        // digit. Dates, integer counts, nulls and row order remain exact.
        if(typeof value==='number'&&!Number.isInteger(value))expect(actual[chart][index][key]).toBeCloseTo(value,12);
        else expect(actual[chart][index][key]).toEqual(value);
      }
    });
  }
}
test('04 Time Period and Time Unit work in either selection order and recover without reloading',async({page},info)=>{
  const watch=await openDashboard(page,profile);
  await hospital(page,first);
  await timePeriod(page,'2025-11-01','2026-05-01');
  await timeUnit(page,'Month');
  const expectedRestored=await allTrends(watch);
  await timeUnit(page,'Quarter');
  const periodFirst=await allTrends(watch);
  await watch.trends[0].holder.scrollIntoViewIfNeeded();
  await scene(page,info,'period-first','Period then unit','The selected date window is grouped into quarters.','Selection order');
  await timeUnit(page,'Year');
  await timePeriod(page,'2025-01-01','2026-01-01');
  await timeUnit(page,'Quarter');
  await timePeriod(page,'2025-11-01','2026-05-01');
  const unitFirst=await allTrends(watch);
  expectSameResults(unitFirst,periodFirst);
  await info.attach('selection-order-results',{body:Buffer.from(JSON.stringify({periodFirst,unitFirst})),contentType:'application/json'});
  await watch.trends[0].holder.scrollIntoViewIfNeeded();
  await scene(page,info,'unit-first','Unit then period','The same final selections produce equivalent chart results.');
  const marker=await page.evaluate(value=>window.__csimDocumentMarker=value,randomUUID());
  await page.getByRole('button',{name:'Clear all',exact:true}).click();
  const apply=dashboardApply(page);
  if(await apply.isEnabled())await apply.click();
  await page.waitForLoadState('networkidle');
  await scene(page,info,'cleared','Clear all','Clear the dashboard filters, then select a hospital and time window again.','Clear and reselect');
  await location(page,'All locations');
  // Stage the hospital while required month inputs are blank. Apply becomes
  // available after the complete window is restored in the next interaction.
  await hospital(page,first,filters.hospital,{apply:false});
  await timePeriod(page,'2025-11-01','2026-05-01');
  await timeUnit(page,'Month');
  const restored=await allTrends(watch);
  const selected=page.getByRole('combobox',{name:filters.hospital,exact:true}).locator('xpath=ancestor::*[contains(concat(" ",normalize-space(@class)," ")," ant-select ")][1]');
  await expect(selected).toContainText(first);
  expectSameResults(restored,expectedRestored);
  expect(Object.values(restored).every(rows=>rows.length>0)).toBe(true);
  if(fixture)expect(restored[watch.trends[4].name].map(row=>Object.entries(row).filter(([key])=>!['month_date','period_label'].includes(key)).map(([,value])=>value))).toEqual([[4],[8],[12],[null],[10],[5]]);
  expect(await page.evaluate(()=>window.__csimDocumentMarker)).toBe(marker);
  await watch.trends[0].holder.scrollIntoViewIfNeeded();
  await scene(page,info,'reselected','Results return','The charts respond on the same page. No reload is used.');
  await watch.settle();expect(watch.failures).toEqual([]);
  await info.attach('recovered-results',{body:Buffer.from(JSON.stringify(restored)),contentType:'application/json'});
});

test('Opening afresh applies the saved hospital, date window and Month defaults',async({page})=>{
  const watch=await openDashboard(page,profile);
  for(const [id,label] of [[filters.hospital,reconciled&&!fixture?'Cohort':openingHospital],[filters.grain,'Month']]){
    const selected=await page.getByRole('combobox',{name:id,exact:true}).evaluate(el=>el.closest('[title]')?.getAttribute('title') || el.closest('.ant-select').querySelector('.ant-select-selection-item')?.getAttribute('title'));
    expect(selected).toBe(label);
  }
  if(process.env.CSIM_NATIVE_MONTHS==='1'){
    for(const [id,value] of [['from_month',fixture?'2025-11':'12 months ago'],['through_month',fixture?'2026-04':'Last complete month']]){
      const control=page.getByRole('combobox',{name:`NATIVE_FILTER-csim-${id}`,exact:true});
      await expect(control.locator('xpath=ancestor::*[contains(concat(" ",normalize-space(@class)," ")," ant-select ")][1]')).toContainText(value);
    }
  }else if(process.env.CSIM_SIMPLE_CONTROLS==='1'){
    const now=new Date();
    const from=reconciled&&!fixture?new Date(Date.UTC(now.getUTCFullYear()-1,now.getUTCMonth(),1)).toISOString().slice(0,7):'2025-11';
    const through=reconciled&&!fixture?new Date(Date.UTC(now.getUTCFullYear(),now.getUTCMonth()-1,1)).toISOString().slice(0,7):'2026-04';
    await expect(page.getByLabel('From month',{exact:true})).toHaveValue(from);
    await expect(page.getByLabel('Through month (inclusive)',{exact:true})).toHaveValue(through);
  }else await expect(page.getByRole('button',{name:'Time Period',exact:true})).toContainText('Last year');
  await allTrends(watch);
  await watch.settle();expect(watch.failures).toEqual([]);
});
