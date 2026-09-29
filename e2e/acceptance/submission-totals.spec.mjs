import fs from 'node:fs';
import {test,expect} from '@playwright/test';
import {openDashboard,hospital,timePeriod,waitForChartPaint} from './dashboard.mjs';

// Independently counted from the supplied demo's historical source records for
// hospital 53. There are no current-source rows for this hospital. Do not derive
// the expected values from the dashboard's aggregate query.
const observed={
  '2023-09':36,'2023-10':9,'2023-11':18,'2023-12':9,
  '2024-01':15,'2024-02':19,'2024-03':21,'2024-04':23,'2024-05':24,
  '2024-06':21,'2024-07':7,'2024-10':39,'2024-11':38,'2024-12':40,
  '2025-01':69,'2025-02':42,'2025-03':20,'2025-04':37,'2025-05':47,
  '2025-06':63,'2025-07':66,'2025-08':48,'2025-09':44,'2025-10':52,
  '2025-11':43,'2025-12':37,'2026-01':37,'2026-02':38,'2026-03':18,
};

test('Hospital 53 monthly submissions reconcile by date range while the all-time card remains 980',async({page},info)=>{
  test.skip(process.env.CSIM_NATIVE_DATES!=='1'||process.env.CSIM_DATA_PROFILE==='edge-cases','Supplied demo on the official dashboard');
  expect(Object.values(observed).reduce((a,b)=>a+b,0)).toBe(980);
  const watch=await openDashboard(page,'standard');
  await hospital(page,'53');
  await hospital(page,'53','NATIVE_FILTER-PsH68K-xwsp1NWi3i2HxI');
  const trend=watch.trends.find(c=>c.name==='UC submissions (time series)');
  const link=page.getByRole('link',{name:'All-time UC submissions by your hospital',exact:true});
  const card=page.locator('[data-test=dashboard-component-chart-holder]').filter({has:link});
  const cardId=Number(new URL(await link.getAttribute('href'),'http://local').searchParams.get('slice_id'));
  const cases=[];
  for(const range of [
    {name:'saved-period',from:'2025-09-01',until:'2026-09-01',total:269},
    {name:'all-observed-months',from:'2023-09-01',until:'2026-04-01',total:980},
    {name:'february-march',from:'2026-02-01',until:'2026-04-01',total:56},
  ]){
    if(range.name!=='saved-period')await timePeriod(page,range.from,range.until);
    await trend.holder.scrollIntoViewIfNeeded();
    await expect.poll(()=>watch.replies.get(trend.id)?.result?.status).toBe('success');
    const response=watch.replies.get(trend.id);
    const expected={};
    const cursor=new Date(range.from+'T00:00:00Z');
    while(cursor<new Date(range.until+'T00:00:00Z')){
      const month=cursor.toISOString().slice(0,7);
      expected[month]=observed[month]??null;
      cursor.setUTCMonth(cursor.getUTCMonth()+1);
    }
    const actual=Object.fromEntries(response.result.data.map(row=>[row.period_label,row['53']]));
    expect(actual).toEqual(expected);
    const total=Object.values(actual).reduce((sum,value)=>sum+(value??0),0);
    expect(total).toBe(range.total);
    await waitForChartPaint(trend.plot);
    await trend.holder.screenshot({path:info.outputPath(range.name+'-monthly.png')});
    await card.scrollIntoViewIfNeeded();
    await expect.poll(()=>watch.replies.get(cardId)?.result?.status).toBe('success');
    await expect(card).toContainText('980');
    await card.screenshot({path:info.outputPath(range.name+'-all-time.png')});
    cases.push({...range,monthlyValues:actual,monthlyTotal:total,allTime:980});
  }
  fs.writeFileSync(info.outputPath('submission-reconciliation.json'),JSON.stringify(cases,null,2));
  expect(watch.failures).toEqual([]);
});
