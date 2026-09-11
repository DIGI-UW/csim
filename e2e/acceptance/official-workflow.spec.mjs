import {test,expect} from '@playwright/test';
import {profile,fixture,dataProfile} from '../acceptance.config.mjs';
import {openDashboard,timePeriod,timeUnit,hospital,allTrends,paintedLabels} from './dashboard.mjs';
import {scene,enableRecording} from './recording.mjs';

enableRecording(test);
test('10 Official Superset shows native controls and the explicit label tradeoff',async({page},info)=>{
  test.skip(!['standard','development'].includes(profile)||!process.env.CSIM_DASHBOARD_SLUG?.includes('sortable'));
  const watch=await openDashboard(page,profile);
  await hospital(page,dataProfile.representativeHospital);
  await timePeriod(page,'2025-11-01','2026-05-01');
  const expected={Month:['2025-11','2025-12','2026-01','2026-02','2026-03','2026-04'],Quarter:['2025 Q4','2026 Q1','2026 Q2'],Year:['2025','2026']};
  for(const grain of ['Month','Quarter','Year']){
    await timeUnit(page,grain);await allTrends(watch);
    await watch.trends[0].holder.scrollIntoViewIfNeeded();
    await expect.poll(()=>paintedLabels(watch.trends[0].plot)).toEqual(expected[grain]);
    await scene(page,info,`official-${grain}`,grain,
      grain==='Month'?'Official Superset uses year-first labels: 2025-11. All six selected months remain visible.':
      grain==='Quarter'?'Quarter labels read 2025 Q4 and 2026 Q1. This differs from the requested Q4 2025 wording.':
      'Year labels read 2025 and 2026. Grouping changes while the selected dates remain fixed.',
      grain==='Month'?'Native date labels':undefined);
  }
  await timePeriod(page,'2026-02-01','2026-04-01');
  await timeUnit(page,'Quarter');
  await page.getByRole('button',{name:'Time Period',exact:true}).click();
  const editor=page.getByRole('tooltip').filter({hasText:'Edit time range'});
  await expect(editor.getByText('2026-02-01 ≤ col < 2026-04-01',{exact:true})).toBeVisible();
  await scene(page,info,'official-date-editor','Time Period',
    'To include February and March, enter February 1 through April 1. This native editor excludes the end date.',
    'The native date-control difference');
  await editor.getByRole('button',{name:/^apply$/i}).click();
  const rows=await allTrends(watch);
  if(fixture){
    const values=rows[watch.trends[4].name].map(row=>Object.entries(row).filter(([key])=>!['month_date','period_label'].includes(key)).map(([,value])=>value));
    expect(values).toEqual([[10]]);
  }
  await watch.trends[4].holder.scrollIntoViewIfNeeded();
  await expect.poll(()=>paintedLabels(watch.trends[4].plot)).toEqual(['2026 Q1']);
  await scene(page,info,'official-partial-quarter','Quarter',fixture?
    'February and March contribute 10 submissions. January is excluded, even though the bucket is Q1.':
    'The quarter contains February and March only. January is excluded from the selected reporting window.');
  await watch.settle();expect(watch.failures).toEqual([]);
  await info.attach('official-partial-quarter',{body:Buffer.from(JSON.stringify(rows)),contentType:'application/json'});
});
