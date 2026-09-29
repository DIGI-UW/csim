import {scene,enableRecording} from './recording.mjs';
import {test,expect} from '@playwright/test';
import {profile,dataProfile} from '../acceptance.config.mjs';
import {openDashboard,timeUnit,timePeriod,paintedLabels,paintedPeriodBounds,hospital,waitForChartPaint} from './dashboard.mjs';

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
      await waitForChartPaint(trend.plot);
      const format=value=>{
        const date=new Date(value),year=date.getUTCFullYear();
        return name==='Year'?String(year):name==='Quarter'?`Q${Math.floor(date.getUTCMonth()/3)+1} ${year}`:new Intl.DateTimeFormat('en-US',{month:'short',year:'numeric',timeZone:'UTC'}).format(date);
      };
      const populated=new Set(result.data.filter(row=>Object.entries(row).some(([key,value])=>key!=='month_date'&&typeof value==='number')).map(row=>format(row.month_date)));
      const box=await trend.plot.locator('canvas').first().boundingBox();
      const label=(await paintedPeriodBounds(trend.plot)).filter(item=>populated.has(item.text))
        .sort((a,b)=>Math.abs(a.x-box.width/2)-Math.abs(b.x-box.width/2))[0];
      expect(label,`${trend.name} must offer a visible populated period for the hover check`).toBeTruthy();
      // Endpoint ticks can lie exactly on the plot boundary. Hover just inside
      // the plot, preferring a populated interior period when one is available.
      const tooltip=page.locator('.echarts-tooltip:visible');
      let hoverTexts=[];
      // Chart heights and legend space differ. Search inside the rendered canvas
      // for the data region instead of assuming its midpoint lies in the plot.
      await expect.poll(async()=>{
        for(const fraction of [0.2,0.3,0.4,0.5,0.6]){
          await page.mouse.move(box.x+label.x+(label.x<box.width/2?2:-2),box.y+box.height*fraction);
          await page.waitForTimeout(120);
          hoverTexts=await tooltip.evaluateAll(elements=>elements.filter(el=>Number(getComputedStyle(el).opacity)>0.99).map(el=>el.innerText));
          if(hoverTexts.length>0 && hoverTexts.every(text=>text.split('\n').some(line=>line.trim()===label.text&&pattern.test(line.trim()))))return true;
        }
        return false;
      },{message:`${trend.name} hover must use ${name} format`}).toBe(true);
      await info.attach(`${name}-${trend.id}-hover`,{body:Buffer.from(JSON.stringify({period:label.text,texts:hoverTexts})),contentType:'application/json'});
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
