import {test,expect} from '@playwright/test';
import {profile,fixture,dataProfile,reconciled} from '../acceptance.config.mjs';
import {openDashboard,timePeriod,timeUnit,hospital,allTrends,paintedPeriodBounds,waitForChartPaint,filters} from './dashboard.mjs';

test('Date labels retain both ends without collision at dashboard widths',async({page},info)=>{
  const watch=await openDashboard(page,profile);
  await timePeriod(page,'2025-09-01','2026-10-01');
  // This gives the supplied-data test a complete calendar even when an
  // individual hospital has no observations at the beginning or end.
  await hospital(page,'Cohort');
  await hospital(page,dataProfile.openingHospital,'NATIVE_FILTER-PsH68K-xwsp1NWi3i2HxI');
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
          expect.soft(bounds[i].left,`${chart.name}: left edge`).toBeGreaterThanOrEqual(8);
          expect.soft(bounds[i].right,`${chart.name}: right edge`).toBeLessThanOrEqual(bounds[i].canvasWidth-8);
          expect.soft(bounds[i].top,`${chart.name}: top edge`).toBeGreaterThanOrEqual(0);
          expect.soft(bounds[i].bottom,`${chart.name}: bottom edge`).toBeLessThanOrEqual(bounds[i].canvasHeight-8);
          if(i)expect.soft(bounds[i].left-bounds[i-1].right,`${chart.name}: ${bounds[i-1].text} / ${bounds[i].text}`).toBeGreaterThanOrEqual(8);
        }
        const dates=rows.map(row=>Number(row.month_date)).filter(Number.isFinite);
        const period=value=>{
          const d=new Date(value),year=d.getUTCFullYear();
          if(grain==='Year')return String(year);
          if(grain==='Quarter')return `Q${Math.floor(d.getUTCMonth()/3)+1} ${year}`;
          return new Intl.DateTimeFormat('en-US',{month:'short',year:'numeric',timeZone:'UTC'}).format(d);
        };
        const expected=[];
        const cursor=new Date(Math.min(...dates)),end=Math.max(...dates);
        while(cursor.getTime()<=end){expected.push(period(cursor.getTime()));cursor.setUTCMonth(cursor.getUTCMonth()+({Month:1,Quarter:3,Year:12}[grain]));}
        expect.soft(bounds.map(item=>item.text),`${chart.name}: complete ${grain} labels`).toEqual(expected);
        const path=info.outputPath(`${width}-${grain}-${chart.id}.png`);
        await chart.holder.screenshot({path});
        await info.attach(`${width}px · ${grain} · ${chart.name}`,{path,contentType:'image/png'});
        report.push({width,grain,chart:chart.name,bounds,screenshot:path});
      }
    }
  }
  await info.attach('painted-label-layout',{body:Buffer.from(JSON.stringify(report)),contentType:'application/json'});
});

test('The opening demo distinguishes cohort results from hospital selection states',async({page},info)=>{
  test.skip(fixture&&!process.env.CSIM_DASHBOARD_SLUG?.includes('examples'),'The isolated numerical fixture exercises explicit selections; public example packages have their own defaults.');
  const watch=await openDashboard(page,profile);
  const selected=page.getByRole('combobox',{name:filters.hospital,exact:true}).locator('xpath=ancestor::*[contains(concat(" ",normalize-space(@class)," ")," ant-select ")][1]');
  const expectedOpening=reconciled&&!fixture?'Cohort':dataProfile.openingHospital;
  await expect(selected).toContainText(expectedOpening);
  const lowerHospital=page.getByRole('combobox',{name:'NATIVE_FILTER-PsH68K-xwsp1NWi3i2HxI',exact:true})
    .locator('xpath=ancestor::*[contains(concat(" ",normalize-space(@class)," ")," ant-select ")][1]');
  if(reconciled&&!fixture){
    await expect(lowerHospital.locator('.ant-select-selection-item')).toHaveCount(0);
    const prompt=page.getByText(/Choose Your hospital in Filters and controls/).first();
    await prompt.scrollIntoViewIfNeeded();await expect(prompt).toBeVisible();
  }
  const report=[];
  const links=page.locator('a[href*="slice_id="]');
  for(const link of await links.all()){
    const title=await link.innerText(),id=Number(new URL(await link.getAttribute('href'),'http://local').searchParams.get('slice_id'));
    const holder=page.locator(`.dashboard-chart-id-${id}`);
    await holder.scrollIntoViewIfNeeded();await watch.settle();
    await expect.poll(()=>watch.replies.get(id)?.result).toBeTruthy();
    const result=watch.replies.get(id).result;
    expect(result.error,title).toBeNull();
    const intentionalHospitalState=reconciled&&!fixture&&(title.startsWith('Your hospital (')||title.startsWith('Based on')||title==='All-time UC submissions by your hospital');
    if(intentionalHospitalState)await expect(holder.getByText(/Choose a hospital in/)).toBeVisible();
    else expect(result.data.length,title).toBeGreaterThan(0);
    if(!intentionalHospitalState)await expect(holder.getByText(/No results were returned|There is currently no information|No data after filtering|An error occurred/)).toHaveCount(0);
    const emptyOutsideTable=await holder.getByText('No data',{exact:true}).evaluateAll(nodes=>nodes.filter(node=>!node.closest('table,[role=grid]')).length);
    if(!intentionalHospitalState)expect(emptyOutsideTable,`${title}: empty panel`).toBe(0);
    if(title.startsWith('Based on')&&!intentionalHospitalState){
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
