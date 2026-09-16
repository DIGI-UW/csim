import {test,expect} from '@playwright/test';
import {openDashboard,revealFilter,dashboardApply} from './dashboard.mjs';

const enabled=process.env.CSIM_BETH_REVIEW==='1';

test('Official 6.1.0 left sidebar documents the Clear all and reselect gap',async({page},info)=>{
  test.skip(!enabled,'Beth review dashboard only');
  await openDashboard(page,'standard');
  await page.getByRole('button',{name:'Clear all',exact:true}).click();
  const apply=dashboardApply(page);
  if(await apply.isEnabled())await apply.click();
  await page.waitForLoadState('networkidle');

  const control=page.getByRole('combobox',{name:'NATIVE_FILTER-yTQKvlEARkQ8t2O7SfLEE',exact:true});
  await revealFilter(page,control);
  const select=control.locator('xpath=ancestor::*[contains(concat(" ",normalize-space(@class)," ")," ant-select ")][1]');
  await select.locator('.ant-select-selector,.ant-select-content').first().click();
  await control.fill('31');
  const listId=await control.getAttribute('aria-controls');
  const option=page.locator(`[id="${listId}"]`).locator('xpath=ancestor::*[contains(concat(" ",normalize-space(@class)," ")," ant-select-dropdown ")][1]').getByTitle('31',{exact:true});
  await expect(option).toBeVisible();
  await option.click();

  // Current official 6.1.0 behavior: Clear all removes the visible state but
  // the next selection is combined with the stale saved Cohort value.
  await expect.poll(()=>select.locator('.ant-select-selection-item').evaluateAll(items=>items.map(item=>item.getAttribute('title')))).toEqual(['Cohort','31']);
  await expect(dashboardApply(page)).toBeEnabled();
  const latest=page.locator('[data-test=dashboard-component-chart-holder]').filter({has:page.getByRole('link',{name:'Latest reporting month in selected period',exact:true})});
  await latest.scrollIntoViewIfNeeded();
  await expect(latest).toContainText('Feb 2030');
  await page.screenshot({path:info.outputPath('clear-all-reselect-gap.png')});
  await info.attach('known-gap',{body:Buffer.from(JSON.stringify({
    application:'official Superset 6.1.0',
    action:'Clear all, then reselect hospital 31 in the left sidebar',
    observed:'Hospital 31 was combined with the stale Cohort value and the cleared date range exposed February 2030',
    status:'KNOWN_GAP_REPRODUCED',
  })),contentType:'application/json'});
});
