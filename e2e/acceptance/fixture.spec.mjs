import {test,expect} from '@playwright/test';
import {profile} from '../acceptance.config.mjs';
import {openDashboard,timeUnit,timePeriod,hospital,allTrends} from './dashboard.mjs';

test('Known observations distinguish a missing month, valid zero, and a partial quarter',async({page},info)=>{
  test.skip(!profile.includes('fixture'),'Numerical expectations belong only to the generated edge-case fixture.');
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
  function values(rows){return rows.map(row=>row[Object.keys(row).find(key=>key!=='month_date')]);}
  for(const [index,trend] of watch.trends.entries()){
    expect(values(monthly[trend.name]),trend.name).toEqual(expected[index]);
    const shot=info.outputPath(`missing-zero-${trend.id}.png`);
    await trend.plot.screenshot({path:shot});
    await info.attach(`missing-zero-${trend.id}`,{path:shot,contentType:'image/png'});
  }
  await timeUnit(page,'Quarter');
  const quarter=await allTrends(watch);
  const rate=values(quarter[watch.trends[0].name]);
  expect(rate[0]).toBeCloseTo(4/12,10);
  expect(rate[1]).toBeCloseTo(9/22,10);
  await timePeriod(page,'2026-02-01','2026-04-01');
  const partial=await allTrends(watch);
  expect(values(partial[watch.trends[0].name])).toEqual([0]);
  expect(values(partial[watch.trends[4].name])).toEqual([10]);
  await timePeriod(page,'2026-02-01','2026-03-01');
  const empty=await allTrends(watch);
  expect(Object.values(empty).every(rows=>rows.length===0)).toBe(true);
  await timePeriod(page,'2026-02-01','2026-04-01');
  expect(await allTrends(watch)).toEqual(partial);
  await watch.settle();expect(watch.failures).toEqual([]);
});
