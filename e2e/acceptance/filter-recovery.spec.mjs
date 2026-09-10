import {test,expect} from '@playwright/test';
import {profile,dataProfile} from '../acceptance.config.mjs';
import {openDashboard,timeUnit,timePeriod,hospital,allTrends,filters,location} from './dashboard.mjs';

const first=dataProfile.representativeHospital;
test('Time Period and Time Unit work in either selection order and recover without reloading',async({page},info)=>{
  const watch=await openDashboard(page,profile);
  await timePeriod(page,'2025-11-01','2026-05-01');
  await timeUnit(page,'Quarter');
  const periodFirst=await allTrends(watch);
  await timeUnit(page,'Year');
  await timePeriod(page,'2025-01-01','2026-01-01');
  await timeUnit(page,'Quarter');
  await timePeriod(page,'2025-11-01','2026-05-01');
  expect(await allTrends(watch)).toEqual(periodFirst);
  const marker=await page.evaluate(()=>window.__csimDocumentMarker=crypto.randomUUID());
  await page.getByRole('button',{name:'Clear all',exact:true}).click();
  const apply=page.getByRole('button',{name:'Apply filters',exact:true});
  if(await apply.isEnabled())await apply.click();
  await page.waitForLoadState('networkidle');
  await location(page,'All locations');
  await hospital(page,first);
  await timePeriod(page,'2025-11-01','2026-05-01');
  await timeUnit(page,'Month');
  const restored=await allTrends(watch);
  expect(Object.values(restored).every(rows=>rows.length>0)).toBe(true);
  expect(await page.evaluate(()=>window.__csimDocumentMarker)).toBe(marker);
  await watch.settle();expect(watch.failures).toEqual([]);
  await info.attach('recovered-results',{body:Buffer.from(JSON.stringify(restored)),contentType:'application/json'});
});

test('Opening afresh applies saved Cohort, Last year and Month defaults',async({page})=>{
  const watch=await openDashboard(page,profile);
  for(const [id,label] of [[filters.hospital,'Cohort'],[filters.grain,'Month']]){
    const selected=await page.getByRole('combobox',{name:id,exact:true}).evaluate(el=>el.closest('[title]')?.getAttribute('title') || el.closest('.ant-select').querySelector('.ant-select-selection-item')?.getAttribute('title'));
    expect(selected).toBe(label);
  }
  await expect(page.getByRole('button',{name:'Time Period',exact:true})).toContainText('Last year');
  await allTrends(watch);
  await watch.settle();expect(watch.failures).toEqual([]);
});
