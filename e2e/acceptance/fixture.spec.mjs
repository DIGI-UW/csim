import {scene,enableRecording} from './recording.mjs';
import {test,expect} from '@playwright/test';
import {profile,fixture} from '../acceptance.config.mjs';
import {openDashboard,timeUnit,timePeriod,hospital,allTrends} from './dashboard.mjs';

enableRecording(test);
test('03 Known observations distinguish a missing month, valid zero, and a partial quarter',async({page},info)=>{
  test.skip(!fixture,'Numerical expectations belong only to the generated edge-case fixture.');
  const watch=await openDashboard(page,profile);
  await hospital(page,'91');
  await timePeriod(page,'2025-11-01','2026-05-01');
  const monthly=await allTrends(watch);
  const expected=[
    [0.5,0.25,0.75,null,0,null],
    [0.5,0.25,0.75,null,0,null],
    [1,1,1,null,1,0],
    [6,6,6,null,6,null],
    [4,8,12,null,10,5],
  ];
  function values(rows){return rows.map(row=>row[Object.keys(row).find(key=>!['month_date','period_label'].includes(key))]);}
  for(const [index,trend] of watch.trends.entries()){
    expect(values(monthly[trend.name]),trend.name).toEqual(expected[index]);
    const shot=info.outputPath(`missing-zero-${trend.id}.png`);
    await trend.plot.screenshot({path:shot});
    await info.attach(`missing-zero-${trend.id}`,{path:shot,contentType:'image/png'});
  }
  await watch.trends[0].holder.scrollIntoViewIfNeeded();
  await scene(page,info,'missing-zero','Month','Hospital 91 has no February observations. March is a valid zero.','Missing periods and zero');
  await timeUnit(page,'Quarter');
  const quarter=await allTrends(watch);
  const rate=values(quarter[watch.trends[0].name]);
  expect(rate[0]).toBeCloseTo(4/12,10);
  expect(rate[1]).toBeCloseTo(9/22,10);
  await timePeriod(page,'2026-02-01','2026-04-01');
  const partial=await allTrends(watch);
  expect(values(partial[watch.trends[0].name])).toEqual([0]);
  expect(values(partial[watch.trends[4].name])).toEqual([10]);
  await watch.trends[4].holder.scrollIntoViewIfNeeded();
  await scene(page,info,'partial-quarter','Quarter','February–March contains 10 submissions. January contributes none.','Filter before grouping');
  await timePeriod(page,'2026-02-01','2026-03-01');
  const empty=await allTrends(watch);
  expect(Object.values(empty).every(rows=>rows.length===0)).toBe(true);
  await watch.trends[0].holder.scrollIntoViewIfNeeded();
  await scene(page,info,'empty-month','February only','This hospital has no February observations; the chart correctly reports no results.');
  await timePeriod(page,'2026-02-01','2026-04-01');
  expect(await allTrends(watch)).toEqual(partial);
  await watch.trends[0].holder.scrollIntoViewIfNeeded();
  await scene(page,info,'range-restored','February–March','The same page returns to a valid quarterly result after the empty selection.');
  await watch.settle();expect(watch.failures).toEqual([]);
});
