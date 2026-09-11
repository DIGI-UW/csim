import {scene,enableRecording} from './recording.mjs';
import {test,expect} from '@playwright/test';
import {profile,dataProfile} from '../acceptance.config.mjs';
import {openDashboard,timeUnit,timePeriod,paintedLabels,hospital} from './dashboard.mjs';

enableRecording(test);
test('02 All eleven date axes keep real dates and display Month, Quarter and Year',async({page},info)=>{
  const watch=await openDashboard(page,profile);
  await hospital(page,dataProfile.representativeHospital);
  await hospital(page,dataProfile.representativeHospital,'NATIVE_FILTER-PsH68K-xwsp1NWi3i2HxI');
  await timePeriod(page,'2025-11-01','2026-05-01');
  for(const [name,grain,pattern] of [['Month','P1M',/^[A-Z][a-z]{2} 202[56]$/],['Quarter','P3M',/^Q[1-4] 202[56]$/],['Year','P1Y',/^202[56]$/]]){
    await timeUnit(page,name);
    for(const trend of watch.dateAxes){
      await page.mouse.move(0,0);
      await trend.holder.scrollIntoViewIfNeeded();
      await page.waitForLoadState('networkidle');
      await watch.settle();
      await expect.poll(()=>watch.replies.get(trend.id)?.request.queries[0].extras.time_grain_sqla).toBe(grain);
      const result=watch.replies.get(trend.id).result;
      expect(result.error).toBeNull();
      if(!watch.trends.includes(trend)&&result.data.length===0)continue;
      expect(result.data.length).toBeGreaterThan(0);
      await expect(trend.plot.locator('canvas')).toBeVisible();
      const dates=result.data.map(row=>row.month_date);
      expect(dates).toEqual([...dates].sort((a,b)=>a-b));
      await expect.poll(async()=>{
        const labels=await paintedLabels(trend.plot);
        return labels.length>0&&labels.every(label=>pattern.test(label));
      },{message:`${trend.name} must actually draw ${name} labels`}).toBe(true);
      const box=await trend.plot.boundingBox();
      await page.mouse.move(box.x+box.width*0.55,box.y+box.height*0.45);
      const tooltip=page.locator('.echarts-tooltip:visible');
      await expect.poll(async()=>{
        const texts=await tooltip.evaluateAll(elements=>elements.filter(el=>Number(getComputedStyle(el).opacity)>0.99).map(el=>el.innerText));
        return texts.length>0 && texts.every(text=>text.split('\n').some(line=>pattern.test(line.trim())));
      },{message:`${trend.name} hover must use ${name} format`}).toBe(true);
      const shot=info.outputPath(`${name}-${trend.id}.png`);
      await trend.plot.screenshot({path:shot});
      await info.attach(`${name}-${trend.id}`,{path:shot,contentType:'image/png'});
    }
    await watch.trends[0].holder.scrollIntoViewIfNeeded();
    await scene(page,info,`labels-${name}`,name,`${name} labels follow the grouping on the trend charts and additional date axes.`,name+' grouping');
  }
  await watch.settle();expect(watch.failures).toEqual([]);
  await info.attach('chart-results',{body:Buffer.from(JSON.stringify(Object.fromEntries(watch.replies))),contentType:'application/json'});
});
