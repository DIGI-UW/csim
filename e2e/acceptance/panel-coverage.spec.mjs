import fs from 'node:fs';
import {test,expect} from '@playwright/test';
import {openDashboard,hospital,timePeriod,timeUnit,waitForChartPaint} from './dashboard.mjs';
const enabled=process.env.CSIM_PANEL_COVERAGE==='1';
const plan=JSON.parse(fs.readFileSync('../dashboard/overlays/beth-panel-coverage.json','utf8'));
const original=JSON.parse(fs.readFileSync('../reports/filter-scope-query-evidence-2026-09-17.json','utf8'));
const known=JSON.parse(fs.readFileSync('../sources/live-review/2026-09-17T163028Z/inventory.json','utf8'));
const ids=new Map(known.charts.map(c=>[c.uuid,c.id]));

test('Seven panels label their own date coverage, exclude date controls, and retain their results',async({page},info)=>{
  test.skip(!enabled,'Approved September panel coverage update only');
  const watch=await openDashboard(page,'standard');
  await hospital(page,'53');
  const results=[];
  for(const [name,from,until,unit] of [['2024-month','2024-01-01','2025-01-01','Month'],['2025-2026-year','2025-09-01','2026-09-01','Year']]){
    await timePeriod(page,from,until);
    await timeUnit(page,unit);
    for(const panel of plan.panels){
      const id=ids.get(panel.uuid), holder=page.locator(`.dashboard-chart-id-${id}`);
      await holder.evaluate(el=>el.scrollIntoView({block:'center',behavior:'instant'}));
      let lastBounds;
      await expect.poll(async()=>{const b=await holder.boundingBox();const now=JSON.stringify(b);const stable=now===lastBounds;lastBounds=now;return stable&&b.y>=65&&b.y+b.height<=1100;}).toBe(true);
      await expect.poll(()=>watch.replies.get(id)?.result?.status).toBe('success');
      await expect(holder.getByRole('link',{name:panel.title,exact:true})).toBeVisible();
      const response=watch.replies.get(id);
      expect(response.result.data).toEqual(original.find(x=>x.chartId===id).cases[0].data);
      expect(response.request.queries[0].time_range || 'No filter').toBe('No filter');
      const count=[88,94].includes(id)?1:2;
      const indicator=holder.getByRole('button',{name:`Applied filters (${count})`,exact:true});
      await indicator.hover();
      await expect(indicator).toHaveAttribute('aria-describedby',/.+/);
      const tooltip=page.locator('#'+await indicator.getAttribute('aria-describedby'));
      await expect(tooltip).toBeVisible();
      await expect.poll(()=>tooltip.evaluate(el=>{for(let p=el;p;p=p.parentElement)if(Number(getComputedStyle(p).opacity)<1)return false;return true;})).toBe(true);
      await expect(tooltip).toContainText('Hospital and State');
      await expect(tooltip).not.toContainText('Time Period');
      await expect(tooltip).not.toContainText('Time Unit');
      if(count===2)await expect(tooltip).toContainText('Location of Urine Culture Collection');
      await waitForChartPaint(holder);
      if(name==='2024-month')await page.screenshot({path:info.outputPath(`panel-${id}-filters.png`)});
      results.push({case:name,id,title:panel.title,appliedFilters:await tooltip.innerText(),data:response.result.data});
      await page.mouse.move(100,20);
      await expect(tooltip).not.toBeVisible();
      if([88,94].includes(id)){
        await expect(holder.getByRole('columnheader',{name:/Month/})).toBeVisible();
        await expect(holder).toContainText('Mar 2026');
      }
    }
    const trend=watch.trends.find(c=>c.name==='Therapy duration (time series)');
    await trend.holder.scrollIntoViewIfNeeded();
    await expect.poll(()=>watch.replies.get(trend.id)?.result?.status).toBe('success');
    const result=watch.replies.get(trend.id);
    expect(result.request.queries[0].time_range).toContain(from);
    expect(result.result.data.length).toBeGreaterThan(0);
    results.push({case:name,id:trend.id,data:result.result.data,timeRange:result.request.queries[0].time_range});
    const indicator=trend.holder.getByRole('button',{name:'Applied filters (4)',exact:true});
    await indicator.hover();
    await expect(indicator).toHaveAttribute('aria-describedby',/.+/);
    const tooltip=page.locator('#'+await indicator.getAttribute('aria-describedby'));
    await expect(tooltip).toContainText('Time Period');await expect(tooltip).toContainText('Time Unit');
    await page.mouse.move(100,20);
  }
  const trendResults=results.filter(r=>r.id===90);
  expect(trendResults[0].data).not.toEqual(trendResults[1].data);
  const formula=page.locator('#'+plan.formulaNode);
  await formula.evaluate(el=>window.scrollTo({top:el.getBoundingClientRect().top+window.scrollY-190,behavior:'instant'}));
  await expect(page.locator('[role=tooltip]:visible').filter({hasText:'Applied filters'})).toHaveCount(0);
  await expect(formula).toContainText('Number of submissions with a positive urinalysis');
  await expect(formula).toContainText('Number of urine culture submissions');
  await expect(formula).not.toContainText('treated asymptomatic');
  await expect.poll(async()=>{const b=await formula.boundingBox();return b.y>=100&&b.y+b.height<700;}).toBe(true);
  await waitForChartPaint(page.locator('.dashboard-chart-id-98'));
  await page.screenshot({path:info.outputPath('section-4-1-correct-formula.png')});
  await watch.settle();expect(watch.failures).toEqual([]);
  fs.writeFileSync(info.outputPath('panel-results.json'),JSON.stringify(results,null,2));
});
