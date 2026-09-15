import {test,expect} from '@playwright/test';
import {openDashboard,dashboardApply,waitForChartPaint} from './dashboard.mjs';

const enabled=process.env.CSIM_NATIVE_DATES==='1';
test('Native specific dates open in Custom in the left sidebar and apply without changing grouping',async({page},testInfo)=>{
  test.skip(!enabled,'Specific-date dashboard only');
  const state=await openDashboard(page,'standard');
  const period=page.getByRole('button',{name:'Time Period',exact:true});
  const header=page.getByRole('textbox',{name:'Dashboard title',exact:true});
  const periodBounds=await period.boundingBox(),titleBounds=await header.boundingBox();
  expect(periodBounds.x+periodBounds.width).toBeLessThanOrEqual(titleBounds.x+20);
  await expect(page.getByRole('button',{name:/More filters/})).toHaveCount(0);
  await expect(page.getByRole('combobox',{name:'NATIVE_FILTER-KyTwDhtSKTATUbbB9Yka_'})).toBeVisible();
  await period.click();
  const editor=page.getByRole('tooltip').filter({hasText:'Edit time range'});
  const modeText=name=>editor.getByRole('combobox',{name,exact:true}).evaluate(el=>el.closest('.ant-select').textContent);
  expect(await modeText('Range type')).toContain('Custom');
  expect(await modeText('Start (inclusive)')).toContain('Specific Date/Time');
  expect(await modeText('End (exclusive)')).toContain('Specific Date/Time');
  const inputs=editor.getByRole('textbox',{name:'Select date',exact:true});
  const examples=process.env.CSIM_DATA_PROFILE==='edge-cases';
  await expect(inputs.nth(0)).toHaveValue(examples?'2025-11-01 00:00:00':'2025-09-01 00:00:00');
  await expect(inputs.nth(1)).toHaveValue(examples?'2026-05-01 00:00:00':'2026-09-01 00:00:00');
  await page.screenshot({path:testInfo.outputPath('opening-custom-left.png')});
  for(const [index,value] of ['2026-02-01 00:00:00','2026-04-01 00:00:00'].entries()){
    await inputs.nth(index).fill(value);
    await inputs.nth(index).press('Enter');
  }
  await expect(editor.getByText('2026-02-01 ≤ col < 2026-04-01',{exact:true})).toBeVisible();
  await editor.getByRole('button',{name:'APPLY',exact:true}).click();
  await dashboardApply(page).click();
  const summaryLink=page.getByRole('link',{name:'Reporting period',exact:true});
  const summary=page.locator('[data-test=dashboard-component-chart-holder]').filter({has:summaryLink});
  await expect(summary).toContainText('2026-02-01 00:00');
  await expect(summary).toContainText('2026-04-01 00:00');
  await expect(summary).toContainText('Month');
  const submissions=state.trends.find(t=>t.name==='UC submissions (time series)');
  await submissions.holder.scrollIntoViewIfNeeded();
  await expect.poll(()=>state.replies.get(submissions.id)?.result?.status).toBe('success');
  await waitForChartPaint(submissions.plot);
  await submissions.holder.screenshot({path:testInfo.outputPath('applied-date-range-chart.png')});
  expect(state.replies.get(submissions.id).request.queries[0].time_range).toBe('2026-02-01T00:00:00 : 2026-04-01T00:00:00');
  expect(state.replies.get(submissions.id).result.error).toBeFalsy();
  await period.click();
  expect(await modeText('Range type')).toContain('Custom');
  await expect(inputs.nth(0)).toHaveValue('2026-02-01 00:00:00');
  await expect(inputs.nth(1)).toHaveValue('2026-04-01 00:00:00');
  await page.screenshot({path:testInfo.outputPath('applied-custom-left.png')});
});
