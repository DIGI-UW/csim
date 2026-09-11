import {test,expect} from '@playwright/test';
import {profile} from '../acceptance.config.mjs';
import {openDashboard,timePeriod,timeUnit,allTrends,waitForChartPaint} from '../acceptance/dashboard.mjs';

test('Every section link stays in this dashboard and preserves all filter selections',async({page},info)=>{
  const watch=await openDashboard(page,profile);
  await timePeriod(page,'2025-11-01','2026-05-01');
  await timeUnit(page,'Quarter');
  await allTrends(watch);
  const original=new URL(page.url());
  const token=await page.evaluate(()=>window.__tocDocument=crypto.randomUUID());
  const selections=()=>page.getByRole('combobox').evaluateAll(inputs=>inputs.map(input=>({
    name:input.getAttribute('aria-label'),
    selection:input.closest('.ant-select')?.querySelector('.ant-select-selector')?.textContent,
  })));
  const before=await selections();
  const readRange=()=>process.env.CSIM_NATIVE_MONTHS==='1'
    ? Promise.all(['from_month','through_month'].map(name=>page.getByRole('combobox',{name:`NATIVE_FILTER-csim-${name}`,exact:true}).evaluate(input=>input.closest('.ant-select').querySelector('.ant-select-selection-item')?.textContent)))
    : process.env.CSIM_SIMPLE_CONTROLS==='1'
      ? Promise.all([page.getByLabel('From month',{exact:true}).inputValue(),page.getByLabel('Through month (inclusive)',{exact:true}).inputValue()])
      : page.getByRole('button',{name:'Time Period',exact:true}).innerText();
  const range=await readRange();
  const trendData=watch.trends.map(chart=>watch.replies.get(chart.id).result.data);
  const anchors=page.locator('a[href^="#HEADER-"]');
  await expect(anchors).toHaveCount(9);
  const links=await anchors.evaluateAll(items=>items.map(a=>({href:a.getAttribute('href'),text:a.textContent})));
  const navigations=[];
  page.on('request',request=>{if(request.isNavigationRequest()&&request.frame()===page.mainFrame())navigations.push(request.url());});
  for(const [i,link] of links.entries()){
    expect(link.href).toMatch(/^#HEADER-/);
    const anchor=page.locator(`a[href="${link.href}"]`);
    await anchor.scrollIntoViewIfNeeded();await anchor.click();
    const heading=page.locator(`[id="${link.href.slice(1)}"]`);
    await expect(heading).toBeInViewport();
    expect((await heading.boundingBox()).y,`${link.text}: heading clears the fixed toolbar`).toBeGreaterThanOrEqual(65);
    const current=new URL(page.url());
    expect([current.origin,current.pathname,current.search]).toEqual([original.origin,original.pathname,original.search]);
    expect(await page.evaluate(()=>window.__tocDocument)).toBe(token);
    expect(await selections()).toEqual(before);
    expect(await readRange()).toEqual(range);
    await page.waitForLoadState('networkidle');await watch.settle();await waitForChartPaint(page);
    const screenshot=info.outputPath(`section-${i+1}.png`);
    await page.screenshot({path:screenshot});
    await info.attach(link.text,{path:screenshot,contentType:'image/png'});
  }
  expect(navigations).toEqual([]);
  expect(watch.trends.map(chart=>watch.replies.get(chart.id).result.data)).toEqual(trendData);
  expect(watch.failures).toEqual([]);
  await info.attach('section-link-check',{body:Buffer.from(JSON.stringify({url:original.href,links,filterSelections:before,timePeriod:range,newDocumentRequests:navigations})),contentType:'application/json'});
});
