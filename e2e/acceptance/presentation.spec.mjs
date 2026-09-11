import {test,expect} from '@playwright/test';
import {profile,fixture,dataProfile} from '../acceptance.config.mjs';
import {openDashboard,timePeriod,timeUnit,hospital,allTrends,paintedPeriodBounds,waitForChartPaint,filters} from './dashboard.mjs';

test('Date labels retain both ends without collision at dashboard widths',async({page},info)=>{
  const watch=await openDashboard(page,profile);
  await timePeriod(page,'2025-09-01','2026-10-01');
  // This gives the supplied-data test a complete calendar even when an
  // individual hospital has no observations at the beginning or end.
  await hospital(page,'Cohort');
  const report=[];
  for(const width of [1024,1280,1600]){
    await page.setViewportSize({width,height:1100});
    for(const grain of ['Month','Quarter','Year']){
      await timeUnit(page,grain);await allTrends(watch);
      for(const chart of watch.dateAxes){
        await chart.holder.scrollIntoViewIfNeeded();await watch.settle();
        await expect.poll(()=>watch.replies.get(chart.id)?.result).toBeTruthy();
        const rows=watch.replies.get(chart.id).result.data;
        if(!rows.length)continue;
        await expect.poll(async()=> (await paintedPeriodBounds(chart.plot)).length).toBeGreaterThan(0);
        await waitForChartPaint(chart.plot);
        const bounds=await paintedPeriodBounds(chart.plot);
        for(let i=0;i<bounds.length;i++){
          expect(bounds[i].left,`${chart.name}: left edge`).toBeGreaterThanOrEqual(8);
          expect(bounds[i].right,`${chart.name}: right edge`).toBeLessThanOrEqual(bounds[i].canvasWidth-8);
          if(i)expect(bounds[i].left-bounds[i-1].right,`${chart.name}: ${bounds[i-1].text} / ${bounds[i].text}`).toBeGreaterThanOrEqual(8);
        }
        const dates=rows.map(row=>Number(row.month_date)).filter(Number.isFinite);
        const period=value=>{
          const d=new Date(value),year=d.getUTCFullYear();
          if(grain==='Year')return String(year);
          if(grain==='Quarter')return `Q${Math.floor(d.getUTCMonth()/3)+1} ${year}`;
          return new Intl.DateTimeFormat('en-US',{month:'short',year:'numeric',timeZone:'UTC'}).format(d);
        };
        expect([bounds[0].text,bounds.at(-1).text],`${chart.name}: both endpoints`).toEqual([period(Math.min(...dates)),period(Math.max(...dates))]);
        const path=info.outputPath(`${width}-${grain}-${chart.id}.png`);
        await chart.holder.screenshot({path});
        await info.attach(`${width}px · ${grain} · ${chart.name}`,{path,contentType:'image/png'});
        report.push({width,grain,chart:chart.name,bounds,screenshot:path});
      }
    }
  }
  await info.attach('painted-label-layout',{body:Buffer.from(JSON.stringify(report)),contentType:'application/json'});
});

test('The opening demo has useful content in every chart',async({page},info)=>{
  test.skip(fixture&&!process.env.CSIM_DASHBOARD_SLUG?.includes('examples'),'The isolated numerical fixture exercises explicit selections; public example packages have their own defaults.');
  const watch=await openDashboard(page,profile);
  const selected=page.getByRole('combobox',{name:filters.hospital,exact:true}).locator('xpath=ancestor::*[contains(concat(" ",normalize-space(@class)," ")," ant-select ")][1]');
  await expect(selected).toContainText(dataProfile.openingHospital);
  const report=[];
  const links=page.locator('a[href*="slice_id="]');
  for(const link of await links.all()){
    const title=await link.innerText(),id=Number(new URL(await link.getAttribute('href'),'http://local').searchParams.get('slice_id'));
    const holder=page.locator(`.dashboard-chart-id-${id}`);
    await holder.scrollIntoViewIfNeeded();await watch.settle();
    await expect.poll(()=>watch.replies.get(id)?.result).toBeTruthy();
    const result=watch.replies.get(id).result;
    expect(result.error,title).toBeNull();expect(result.data.length,title).toBeGreaterThan(0);
    await expect(holder.getByText(/No results were returned|There is currently no information|No data after filtering|An error occurred/)).toHaveCount(0);
    const emptyOutsideTable=await holder.getByText('No data',{exact:true}).evaluateAll(nodes=>nodes.filter(node=>!node.closest('table,[role=grid]')).length);
    expect(emptyOutsideTable,`${title}: empty panel`).toBe(0);
    if(title.startsWith('Based on')){
      await expect(holder.locator('table,[role=grid]').first()).toBeVisible();
      if(!fixture)await expect(holder).toContainText('Mar 2026');
    }
    await waitForChartPaint(holder);
    const path=info.outputPath(`opening-${id}.png`);
    await holder.screenshot({path});
    await info.attach(title,{path,contentType:'image/png'});
    report.push({id,title,rows:result.data.length});
  }
  await info.attach('opening-view',{body:Buffer.from(JSON.stringify(report)),contentType:'application/json'});
});
