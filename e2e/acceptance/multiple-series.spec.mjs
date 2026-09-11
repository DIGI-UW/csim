import {scene,enableRecording} from './recording.mjs';
import {test,expect} from '@playwright/test';
import {profile,fixture} from '../acceptance.config.mjs';
import {openDashboard,timeUnit,timePeriod,hospital,allTrends,paintedLabels,filters} from './dashboard.mjs';

enableRecording(test);
test('06 Two hospital series stay chronological across the year boundary',async({page},info)=>{
  test.skip(!fixture,'Uses the two known fixture hospitals.');
  const watch=await openDashboard(page,profile);
  await hospital(page,'91');
  const control=page.getByRole('combobox',{name:filters.hospital,exact:true});
  await control.press('ArrowDown');
  await page.locator('.ant-select-dropdown:visible').getByTitle('92',{exact:true}).click();
  await control.press('Escape');
  await page.getByRole('button',{name:'Apply filters',exact:true}).click();
  await timePeriod(page,'2025-11-01','2026-05-01');
  for(const name of ['Month','Quarter','Year']){
    await timeUnit(page,name);
    const rows=await allTrends(watch);
    for(const trend of watch.trends){
      const values=rows[trend.name];
      expect(values.map(row=>row.month_date)).toEqual(values.map(row=>row.month_date).sort((a,b)=>a-b));
      expect(Object.keys(values[0])).toEqual(expect.arrayContaining(['91','92','month_date']));
      await trend.plot.scrollIntoViewIfNeeded();
      await expect.poll(async()=>{
        const labels=await paintedLabels(trend.plot);
        return labels.some(label=>label.includes('2025'))&&labels.some(label=>label.includes('2026'));
      }).toBe(true);
    }
    const shot=info.outputPath(`two-series-${name}.png`);
    await watch.trends[0].holder.scrollIntoViewIfNeeded();
    await watch.trends[0].holder.screenshot({path:shot});
    await info.attach(`two-series-${name}`,{path:shot,contentType:'image/png'});
    await scene(page,info,`two-series-${name}-screen`,name,'Hospitals 91 and 92 remain in chronological order across the year boundary.',name+' comparison');
  }
  await watch.settle();expect(watch.failures).toEqual([]);
});
