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
