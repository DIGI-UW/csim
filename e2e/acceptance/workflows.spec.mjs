import {test,expect} from '@playwright/test';
import {profile} from '../acceptance.config.mjs';
import {openDashboard,timeUnit,timePeriod,paintedLabels} from './dashboard.mjs';

test('All five trends keep real dates and display Month, Quarter and Year',async({page},info)=>{
  const watch=await openDashboard(page,profile);
  await timePeriod(page,'2025-11-01','2026-05-01');
  for(const [name,grain,pattern] of [['Month','P1M',/^[A-Z][a-z]{2} 202[56]$/],['Quarter','P3M',/^Q[1-4] 202[56]$/],['Year','P1Y',/^202[56]$/]]){
    await timeUnit(page,name);
    for(const trend of watch.trends){
      await trend.plot.scrollIntoViewIfNeeded();
      await expect(trend.plot.locator('canvas')).toBeVisible();
      await expect.poll(()=>watch.replies.get(trend.id)?.request.queries[0].extras.time_grain_sqla).toBe(grain);
      const result=watch.replies.get(trend.id).result;
      expect(result.error).toBeNull();
      expect(result.data.length).toBeGreaterThan(0);
      const dates=result.data.map(row=>row.month_date);
      expect(dates).toEqual([...dates].sort((a,b)=>a-b));
      await expect.poll(async()=>{
        const labels=await paintedLabels(trend.plot);
        return labels.length>0&&labels.every(label=>pattern.test(label));
      },{message:`${trend.name} must actually draw ${name} labels`}).toBe(true);
      const shot=info.outputPath(`${name}-${trend.id}.png`);
      await trend.plot.screenshot({path:shot});
      await info.attach(`${name}-${trend.id}`,{path:shot,contentType:'image/png'});
    }
  }
  await watch.settle();expect(watch.failures).toEqual([]);
  await info.attach('chart-results',{body:Buffer.from(JSON.stringify(Object.fromEntries(watch.replies))),contentType:'application/json'});
});
