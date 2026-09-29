import {test,expect} from '@playwright/test';
import {profile,fixture} from '../acceptance.config.mjs';
import {openDashboard,timePeriod,timeUnit,hospital,allTrends,paintedLabels} from './dashboard.mjs';
import {scene,enableRecording} from './recording.mjs';

enableRecording(test);
test('11 Native month choices include both endpoints and keep grouping separate',async({page},info)=>{
  test.skip(profile!=='standard'||process.env.CSIM_NATIVE_MONTHS!=='1'||!fixture);
  const watch=await openDashboard(page,profile);
  await hospital(page,'91');
  await timePeriod(page,'2025-11-01','2026-05-01');
  await timeUnit(page,'Month');
  const monthly=await allTrends(watch);
  const values=rows=>rows.map(row=>row[Object.keys(row).find(key=>!['month_date','period_label'].includes(key))]);
  expect(values(monthly[watch.trends[4].name])).toEqual([4,8,12,null,10,5]);
  await page.evaluate(()=>scrollTo(0,0));
  await expect(page.getByText('From month',{exact:true})).toBeVisible();
  await expect(page.getByText('Through month',{exact:true})).toBeVisible();
  await scene(page,info,'native-month-choices','Choose months',
    'From 2025-11 through 2026-04 includes November and April. Time Unit controls grouping separately.',
    'Month choices in official Superset');
  await watch.trends[0].holder.scrollIntoViewIfNeeded();
  await expect.poll(()=>paintedLabels(watch.trends[0].plot)).toEqual(['2025-11','2025-12','2026-01','2026-02','2026-03','2026-04']);
  expect(values(monthly[watch.trends[0].name])).toEqual([0.5,0.25,0.75,null,0,null]);
  await scene(page,info,'native-month-labels','Month',
    'February has no observations. March is a measured zero. Native labels use year-first wording.');
  await timePeriod(page,'2026-02-01','2026-04-01');
  await timeUnit(page,'Quarter');
  const quarter=await allTrends(watch);
  expect(values(quarter[watch.trends[4].name])).toEqual([10]);
  await watch.trends[4].holder.scrollIntoViewIfNeeded();
  await expect.poll(()=>paintedLabels(watch.trends[4].plot)).toEqual(['2026 Q1']);
  await scene(page,info,'native-partial-quarter','Quarter',
    'February–March contributes 10 submissions to Q1. January stays excluded.',
    'The range stays fixed when grouping changes');
  await timeUnit(page,'Year');
  const year=await allTrends(watch);
  expect(values(year[watch.trends[4].name])).toEqual([10]);
  await watch.trends[4].holder.scrollIntoViewIfNeeded();
  await expect.poll(()=>paintedLabels(watch.trends[4].plot)).toEqual(['2026']);
  await scene(page,info,'native-partial-year','Year',
    'Year still includes only February–March: 10 submissions. The bucket does not expand the date range.');
  await watch.settle();expect(watch.failures).toEqual([]);
});
