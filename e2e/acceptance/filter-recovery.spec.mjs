import {scene,enableRecording} from './recording.mjs';
import {test,expect} from '@playwright/test';
import {profile,dataProfile} from '../acceptance.config.mjs';
import {openDashboard,timeUnit,timePeriod,hospital,allTrends,filters,location} from './dashboard.mjs';

enableRecording(test);
const first=dataProfile.representativeHospital;
test('04 Time Period and Time Unit work in either selection order and recover without reloading',async({page},info)=>{
  const watch=await openDashboard(page,profile);
  await timePeriod(page,'2025-11-01','2026-05-01');
  await timeUnit(page,'Quarter');
  const periodFirst=await allTrends(watch);
  await watch.trends[0].holder.scrollIntoViewIfNeeded();
  await scene(page,info,'period-first','Period then unit','The selected date window is grouped into quarters.','Selection order');
  await timeUnit(page,'Year');
  await timePeriod(page,'2025-01-01','2026-01-01');
  await timeUnit(page,'Quarter');
  await timePeriod(page,'2025-11-01','2026-05-01');
  expect(await allTrends(watch)).toEqual(periodFirst);
  await watch.trends[0].holder.scrollIntoViewIfNeeded();
  await scene(page,info,'unit-first','Unit then period','The same final selections produce exactly the same chart results.');
  const marker=await page.evaluate(()=>window.__csimDocumentMarker=crypto.randomUUID());
  await page.getByRole('button',{name:'Clear all',exact:true}).click();
  const apply=page.getByRole('button',{name:'Apply filters',exact:true});
  if(await apply.isEnabled())await apply.click();
  await page.waitForLoadState('networkidle');
  await scene(page,info,'cleared','Clear all','Clear the dashboard filters, then select a hospital and time window again.','Clear and reselect');
  await location(page,'All locations');
  await hospital(page,first);
  await timePeriod(page,'2025-11-01','2026-05-01');
  await timeUnit(page,'Month');
  const restored=await allTrends(watch);
  expect(Object.values(restored).every(rows=>rows.length>0)).toBe(true);
  expect(await page.evaluate(()=>window.__csimDocumentMarker)).toBe(marker);
  await watch.trends[0].holder.scrollIntoViewIfNeeded();
  await scene(page,info,'reselected','Results return','The charts respond on the same page. No reload is used.');
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
