import {test,expect} from '@playwright/test';

test('Client installation guide links the tested package and explains safe installation',async({page},info)=>{
  await page.goto('/');
  await page.getByRole('link',{name:'Client installation →',exact:true}).first().click();
  await expect(page).toHaveURL(/\/install\.html$/);
  await expect(page.getByRole('heading',{level:1})).toHaveText('Update the CSiM dashboard on Superset 6.1.0');
  await expect(page.getByText('Rehearsal passed',{exact:true})).toBeVisible();
  await expect(page.getByText('Client installation pending',{exact:true})).toBeVisible();
  await expect(page.getByRole('link',{name:'Follow the update steps',exact:true})).toHaveAttribute('href','#install');
  await expect(page.getByRole('link',{name:'Download the dashboard update',exact:true})).toHaveAttribute('href','downloads/csim-client-update-dashboard.zip');
  await expect(page.locator('#artifacts')).toContainText('Object manifest');
  await expect(page.locator('#contents')).toContainText('It does not carry the rows stored in PostgreSQL');
  await expect(page.locator('#contents')).toContainText('omits the database connection object');
  await expect(page.locator('#before')).toContainText('ENABLE_TEMPLATE_PROCESSING');
  await expect(page.locator('#before')).toContainText('TIME_GRAIN_DENYLIST');
  await expect(page.locator('#before')).toContainText('No custom Superset build is required');
  await expect(page.locator('#install')).toContainText('git checkout d6351d954d5f265e0c0c3c5f66dbb96d612b5352');
  await expect(page.locator('#install')).toContainText('python scripts/dashboard_import.py import --profile client-update');
  await expect(page.locator('#limits')).toContainText('A manual ZIP upload is not a supported installation path');
  for(const width of [1280,390]){
    await page.setViewportSize({width,height:900});
    await page.goto('/install.html#verify');
    await page.locator('#verify h2').scrollIntoViewIfNeeded();
    await expect(page.locator('#verify h2')).toBeInViewport();
    expect(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth)).toBe(true);
    await page.screenshot({path:info.outputPath(`installation-${width}.png`),fullPage:true});
  }
});
