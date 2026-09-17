import {test,expect} from '@playwright/test';
import {openDashboard,hospital,waitForChartPaint} from './dashboard.mjs';

const enabled=process.env.CSIM_BETH_REVIEW==='1';

test('Beth review dashboard shows the bounded reporting month and identified comparison population',async({page},info)=>{
  test.skip(!enabled,'Beth review dashboard only');
  const watch=await openDashboard(page,'standard');

  await expect(page.getByRole('link',{name:'Aggregate ALL DATA — Download'})).toHaveCount(0);
  const latestLink=page.getByRole('link',{name:'Latest reporting month in selected period',exact:true});
  const latestId=Number(new URL(await latestLink.getAttribute('href'),'http://local').searchParams.get('slice_id'));
  const latest=page.locator('[data-test=dashboard-component-chart-holder]').filter({has:latestLink});
  await latest.scrollIntoViewIfNeeded();
  await expect.poll(()=>watch.replies.get(latestId)?.result?.status).toBe('success');
  expect(watch.replies.get(latestId).request.queries[0].time_range).toBe('2025-09-01T00:00:00 : 2026-09-01T00:00:00');
  await expect(latest).toContainText('Aug 2026');
  await expect(latest).not.toContainText('Feb 2030');
  await latest.screenshot({path:info.outputPath('latest-reporting-month-in-range.png')});

  await hospital(page,'53','NATIVE_FILTER-PsH68K-xwsp1NWi3i2HxI');
  const comparison=watch.dateAxes.find(chart=>chart.name==='Your hospital (abx)');
  await comparison.holder.scrollIntoViewIfNeeded();
  await expect.poll(()=>watch.replies.get(comparison.id)?.result?.status).toBe('success');
  const query=watch.replies.get(comparison.id).request.queries[0];
  expect(query.groupby || query.columns).toContain('hosp_code');
  await waitForChartPaint(comparison.plot);
  await comparison.holder.screenshot({path:info.outputPath('hospital-comparison-context.png')});

  await watch.settle();
  expect(watch.failures).toEqual([]);
});

test('Hospital guidance and nested contents preserve selections during section navigation',async({page},info)=>{
  test.skip(!enabled,'Beth review dashboard only');
  const watch=await openDashboard(page,'standard');
  await expect(page.getByText('SELECT YOUR HOSPITAL FIRST',{exact:true})).toBeVisible();
  await expect(page.getByText('HOSPITAL COMPARISONS',{exact:true})).toBeVisible();
  const toc=page.locator('#MARKDOWN-kbpKudPZL01ntlPcgzEYI');
  await expect(toc.locator('li ul a')).toHaveCount(4);
  for(const link of await toc.getByRole('link').all())expect(await link.getAttribute('href')).toMatch(/^#HEADER-/);
  await hospital(page,'53');
  await expect.poll(()=>watch.replies.get(watch.trends[0].id)?.result?.status).toBe('success');
  const filter=page.getByRole('combobox',{name:'NATIVE_FILTER-yTQKvlEARkQ8t2O7SfLEE',exact:true})
    .locator('xpath=ancestor::*[contains(concat(" ",normalize-space(@class)," ")," ant-select ")][1]');
  await expect(filter).toContainText('53');
  const period=await page.getByRole('button',{name:'Time Period',exact:true}).innerText();
  await toc.scrollIntoViewIfNeeded();
  await page.screenshot({path:info.outputPath('hospital-guidance-and-contents.png')});
  const link=toc.getByRole('link',{name:'4.2. Average Duration of Antibiotic Therapy (days)',exact:true});
  const anchor=await link.getAttribute('href');
  await link.click();
  expect(new URL(page.url()).hash).toBe(anchor);
  await expect(filter).toContainText('53');
  await expect(page.getByRole('button',{name:'Time Period',exact:true})).toHaveText(period);
  await expect(page.locator('#MARKDOWN-WIofdf7GkSmIbs0pSuT-6').getByText('The trend and latest-month table use Hospital and state.',{exact:true})).toBeInViewport();
  const therapy=watch.trends.find(chart=>chart.name==='Therapy duration (time series)');
  await expect.poll(()=>watch.replies.get(therapy.id)?.result?.status).toBe('success');
  await waitForChartPaint(therapy.plot);
  await page.screenshot({path:info.outputPath('therapy-section-guidance.png')});
  await watch.settle();
  expect(watch.failures).toEqual([]);
});
