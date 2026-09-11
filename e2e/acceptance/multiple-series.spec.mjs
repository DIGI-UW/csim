import {scene,enableRecording} from './recording.mjs';
import {test,expect} from '@playwright/test';
import {profile,fixture} from '../acceptance.config.mjs';
import {openDashboard,timeUnit,timePeriod,hospital,allTrends,paintedLabels,filters,revealFilter,dashboardApply} from './dashboard.mjs';

enableRecording(test);
test('06 Two hospital series stay chronological across the year boundary',async({page},info)=>{
  test.skip(!fixture,'Uses the two known fixture hospitals.');
  const watch=await openDashboard(page,profile);
  await hospital(page,'91');
  const control=page.getByRole('combobox',{name:filters.hospital,exact:true});
  await revealFilter(page,control);
  await control.press('ArrowDown');
  await control.fill('92');
  await page.locator('.ant-select-dropdown:visible').getByTitle('92',{exact:true}).click();
  await control.press('Escape');
  await dashboardApply(page).click();
  await timePeriod(page,'2025-11-01','2026-05-01');
  for(const name of ['Month','Quarter','Year']){
    await timeUnit(page,name);
    const rows=await allTrends(watch);
    const native=process.env.CSIM_DASHBOARD_SLUG?.includes('sortable');
    const periodKey=native?'period_label':'month_date';
    const periods={Month:['2025-11','2025-12','2026-01','2026-02','2026-03','2026-04'],Quarter:['2025 Q4','2026 Q1','2026 Q2'],Year:['2025','2026']};
    for(const trend of watch.trends){
      const values=rows[trend.name];
      if(native)expect(values.map(row=>row[periodKey])).toEqual(periods[name]);
      else expect(values.map(row=>row[periodKey])).toEqual(values.map(row=>row[periodKey]).sort((a,b)=>a-b));
      expect(Object.keys(values[0])).toEqual(expect.arrayContaining(['91','92',periodKey]));
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
