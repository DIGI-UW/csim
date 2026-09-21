import {randomUUID} from 'node:crypto';
import {test,expect} from '@playwright/test';
import {profile} from '../acceptance.config.mjs';
import {openDashboard,timePeriod,timeUnit,hospital,allTrends,waitForChartPaint} from '../acceptance/dashboard.mjs';

const host=`http://127.0.0.1:${process.env.CSIM_IFRAME_PORT||18781}`;
const snapshot=scope=>scope.getByRole('combobox').evaluateAll(inputs=>inputs.map(input=>({
  name:input.getAttribute('aria-label'),
  selection:input.closest('.ant-select')?.querySelector('.ant-select-selector')?.textContent,
})).sort((a,b)=>String(a.name).localeCompare(String(b.name))));

for(const mode of ['direct','iframe','iframe-kiosk'])test(`All nine section links preserve selections and scroll correctly: ${mode}`,async({page},info)=>{
  const watch=await openDashboard(page,profile);
  await hospital(page,process.env.CSIM_IFRAME_HOSPITAL||'53');
  await hospital(page,process.env.CSIM_IFRAME_HOSPITAL||'53','NATIVE_FILTER-PsH68K-xwsp1NWi3i2HxI');
  await timePeriod(page,'2025-11-01','2026-05-01');
  await timeUnit(page,'Quarter');
  const beforeRows=await allTrends(watch);
  expect(Object.values(beforeRows).some(rows=>rows?.length),'Selected hospital must have data for a meaningful regression').toBe(true);
  const beforeFilters=await snapshot(page);
  const beforeRange=await page.getByRole('button',{name:'Time Period',exact:true}).innerText();
  await expect.poll(()=>new URL(page.url()).searchParams.has('native_filters_key')).toBe(true);
  const saved=new URL(page.url());
  saved.hash='';
  let scope=page;
  if(mode!=='direct'){
    if(mode==='iframe-kiosk')saved.searchParams.set('standalone','2');
    // Load the exact shareable selection URL through an ordinary iframe.
    // A separate port makes this genuinely cross-origin, while the local
    // host remains same-site. It does not simulate third-party-cookie policy.
    const wrapper=new URL(host);wrapper.searchParams.set('dashboard',saved.href);
    watch.replies.clear();
    await page.goto(wrapper.href);
    const iframe=page.locator('iframe[title="CSiM dashboard"]');
    await expect(iframe).toBeVisible();
    const handle=await iframe.elementHandle();scope=await handle.contentFrame();
    expect(scope,'The embedded document must load').toBeTruthy();
    // standalone=2 intentionally hides the dashboard title toolbar.
    if(mode!=='iframe-kiosk')await expect(scope.locator('[data-test=dashboard-header-container]')).toBeVisible();
    await expect(scope.getByRole('button',{name:'Time Period',exact:true})).toBeVisible();
    await expect.poll(()=>snapshot(scope)).toEqual(beforeFilters);
    await expect(scope.getByRole('button',{name:'Time Period',exact:true})).toHaveText(beforeRange);
    watch.trends=watch.trends.map(chart=>({...chart,
      plot:scope.locator(`#chart-id-${chart.id}`),
      holder:scope.locator('[data-test=dashboard-component-chart-holder]').filter({has:scope.getByRole('link',{name:chart.name,exact:true})}),
    }));
    expect(await allTrends(watch)).toEqual(beforeRows);
  }
  const token=randomUUID();await scope.evaluate(value=>window.__csimTocDocument=value,token);
  const parentUrl=page.url(),documentUrl=new URL(scope.url());
  const anchors=scope.locator('a[href^="#HEADER-"]');
  await expect(anchors).toHaveCount(9);
  const links=await anchors.evaluateAll(items=>items.map(a=>({href:a.getAttribute('href'),text:a.textContent,target:a.getAttribute('target')})));
  const navigations=[],popups=[],checks=[];
  page.on('request',request=>{if(request.isNavigationRequest())navigations.push(request.url());});
  page.on('popup',popup=>popups.push(popup));
  for(const [index,link] of links.entries()){
    const anchor=scope.locator(`a[href="${link.href}"]`);
    await anchor.scrollIntoViewIfNeeded();await anchor.click();
    // A scroll can place a chart-title link under the pointer. Move away so
    // its hover tooltip cannot obscure the navigation evidence.
    await page.mouse.move(2,2);
    const heading=scope.locator(`[id="${link.href.slice(1)}"]`).locator('xpath=ancestor::*[contains(concat(" ",normalize-space(@class)," ")," dashboard-component-header ")][1]');
    await expect(heading,`${link.text}: section must appear in the visible frame`).toBeInViewport();
    await page.waitForLoadState('networkidle');await watch.settle();await waitForChartPaint(scope);
    const current=new URL(scope.url());
    expect([current.origin,current.pathname,current.search]).toEqual([documentUrl.origin,documentUrl.pathname,documentUrl.search]);
    if(mode!=='direct')expect(page.url()).toBe(parentUrl);
    expect(await scope.evaluate(()=>window.__csimTocDocument)).toBe(token);
    expect(await snapshot(scope)).toEqual(beforeFilters);
    await expect(scope.getByRole('button',{name:'Time Period',exact:true})).toHaveText(beforeRange);
    // Browser hit-testing is relative to this document's viewport, including
    // its fixed toolbar. Test the rendered heading, not its empty anchor.
    const surface=await heading.evaluate(el=>{
      const r=el.getBoundingClientRect();
      return {top:r.top,bottom:r.bottom,viewport:innerHeight,
        exposed:[r.top+4,r.bottom-4].map(y=>el.contains(document.elementFromPoint(r.left+8,y)))};
    });
    expect(surface.top,`${link.text}: heading is above frame top`).toBeGreaterThanOrEqual(0);
    expect(surface.bottom,`${link.text}: heading is below frame bottom`).toBeLessThanOrEqual(surface.viewport);
    expect(surface.exposed,`${link.text}: heading must not be hidden by a toolbar`).toEqual([true,true]);
    checks.push({...link,...surface});
    const screenshot=info.outputPath(`${mode}-section-${index+1}.png`);
    await page.screenshot({path:screenshot,animations:'disabled'});
    await info.attach(link.text,{path:screenshot,contentType:'image/png'});
  }
  expect(navigations,'Section links must not reload the dashboard or navigate the host').toEqual([]);
  expect(popups,'Section links must not open another tab').toEqual([]);
  expect(await allTrends(watch)).toEqual(beforeRows);
  expect(watch.failures).toEqual([]);
  await info.attach('iframe-navigation-evidence',{body:Buffer.from(JSON.stringify({mode,documentUrl:documentUrl.href,parentUrl,links:checks,selections:beforeFilters,timePeriod:beforeRange,newDocumentRequests:navigations,trendRowsUnchanged:true})),contentType:'application/json'});
});
