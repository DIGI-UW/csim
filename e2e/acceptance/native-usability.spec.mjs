import {test,expect} from '@playwright/test';
import {profile,fixture} from '../acceptance.config.mjs';
import {openDashboard,allTrends,selectValue,revealFilter,dashboardApply,waitForChartPaint,timeUnit,timePeriod,hospital} from './dashboard.mjs';

import {scene,enableRecording} from './recording.mjs';

enableRecording(test);
const fromId='NATIVE_FILTER-csim-from_month',throughId='NATIVE_FILTER-csim-through_month';
const selection=(page,id)=>page.getByRole('combobox',{name:id,exact:true}).locator('xpath=ancestor::*[contains(concat(" ",normalize-space(@class)," ")," ant-select ")][1]');
test('Native month presets follow the last twelve complete months',async({page},info)=>{
  test.skip(profile!=='standard'||process.env.CSIM_NATIVE_MONTHS!=='1'||fixture);
  const watch=await openDashboard(page,profile);
  await expect(selection(page,fromId)).toContainText('12 months ago');
  await expect(selection(page,throughId)).toContainText('Last complete month');
  const data=await allTrends(watch);
  const now=new Date(), first=new Date(Date.UTC(now.getUTCFullYear()-1,now.getUTCMonth(),1)), end=new Date(Date.UTC(now.getUTCFullYear(),now.getUTCMonth(),1));
  for(const rows of Object.values(data)){
    expect(rows.length).toBe(12);
    for(const row of rows){
      const value=String(row.period_label);
      expect(value>=first.toISOString().slice(0,7)&&value<end.toISOString().slice(0,7)).toBe(true);
    }
  }
  await page.evaluate(()=>scrollTo(0,0));
  await waitForChartPaint(page);await page.screenshot({path:info.outputPath('native-rolling-defaults.png')});
  expect(watch.failures).toEqual([]);
});
test('12 Native ending choices follow the starting month and preserve a valid endpoint',async({page},info)=>{
  test.skip(profile!=='standard'||process.env.CSIM_NATIVE_MONTHS!=='1');
  const watch=await openDashboard(page,profile);
  await page.evaluate(()=>window.__csimRangeRecoveryMarker='same-page');
  await selectValue(page,'2026-02',fromId);
  await selectValue(page,'2026-04',throughId);
  await selectValue(page,'2026-03',fromId);

  await expect(selection(page,throughId)).toContainText('2026-04');
  const control=page.getByRole('combobox',{name:throughId,exact:true});
  await revealFilter(page,control);await selection(page,throughId).locator('.ant-select-selector').click();
  await control.fill('2026-02');
  await expect(page.locator('.ant-select-dropdown:visible').getByTitle('2026-02',{exact:true})).toHaveCount(0);
  await page.screenshot({path:info.outputPath('native-ending-choices.png')});
  await control.press('Escape');
  await selectValue(page,'2026-05',fromId,{apply:false});
  await expect(selection(page,throughId)).not.toHaveClass(/ant-select-loading/);
  await page.locator('[data-test=dashboard-header-container]').click({position:{x:4,y:4}});
  await dashboardApply(page).click();
  const summary=page.locator('[data-test=dashboard-component-chart-holder]').filter({has:page.getByRole('link',{name:'Reporting period',exact:true})});
  await expect(summary.getByText('Choose a Through month on or after May 2026. The selected range is reversed.',{exact:true})).toBeVisible();
  const invalid=await allTrends(watch);expect(Object.values(invalid).every(rows=>rows.length===0)).toBe(true);
  await summary.scrollIntoViewIfNeeded();
  await waitForChartPaint(summary);
  await scene(page,info,'native-start-after-end','A reversed range',
    'From is later than Through. The summary asks for May 2026 or later; the empty charts do not represent zero.',
    'Recognize and correct a reversed range');
  await selectValue(page,'2026-06',throughId);
  await expect(summary.getByText('Both endpoint months are included.',{exact:false})).toBeVisible();
  const recovered=await allTrends(watch);
  for(const rows of Object.values(recovered))expect(rows.map(row=>row.period_label)).toEqual(['2026-05','2026-06']);
  expect(await page.evaluate(()=>window.__csimRangeRecoveryMarker)).toBe('same-page');
  await scene(page,info,'native-range-recovered','A valid range',
    'Through June now includes May and June. The dates and charts recover on this page, without reloading.');
  await watch.settle();expect(watch.failures).toEqual([]);
});

test('Native reporting period explains partial buckets and shows a readable warning at all review widths',async({page},info)=>{
  test.skip(profile!=='standard'||process.env.CSIM_NATIVE_MONTHS!=='1');
  const watch=await openDashboard(page,profile);
  if(fixture)await hospital(page,'91');
  await timePeriod(page,'2026-02-01','2026-04-01');
  await timeUnit(page,'Quarter');
  const summary=page.locator('[data-test=dashboard-component-chart-holder]').filter({has:page.getByRole('link',{name:'Reporting period',exact:true})});
  await expect(summary.getByText('Feb 2026',{exact:true})).toBeVisible();
  await expect(summary.getByText('Mar 2026',{exact:true})).toBeVisible();
  await expect(summary.getByText('Quarter',{exact:true})).toBeVisible();
  await expect(summary.getByText('Only the selected months contribute to each quarter.',{exact:false})).toBeVisible();
  const partial=await allTrends(watch);
  if(fixture)expect(partial[watch.trends[4].name]).toEqual([{'period_label':'2026 Q1','91':10}]);
  await summary.scrollIntoViewIfNeeded();
  await page.screenshot({path:info.outputPath('native-partial-summary.png')});
  await selectValue(page,'2026-05',fromId);
  const warning=summary.getByText('Choose a Through month on or after May 2026. The selected range is reversed.',{exact:true});
  for(const width of [1024,1280,1600]){
    await page.setViewportSize({width,height:1100});await summary.scrollIntoViewIfNeeded();
    await expect(warning).toBeVisible();
    const readable=await warning.evaluate(el=>{
      const range=document.createRange();range.selectNodeContents(el);
      const clip=el.closest('[data-test=dashboard-component-chart-holder]').getBoundingClientRect();
      return [...range.getClientRects()].every(r=>r.left>=clip.left&&r.right<=clip.right&&r.top>=clip.top&&r.bottom<=clip.bottom);
    });
    expect(readable,'The entire warning must fit inside the chart, without horizontal scrolling').toBe(true);
    await page.screenshot({path:info.outputPath(`native-warning-${width}.png`)});
  }
  await watch.settle();expect(watch.failures).toEqual([]);
});
