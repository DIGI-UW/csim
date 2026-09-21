import {test,expect} from '@playwright/test';

test('Client installation guide links the tested package and explains safe installation',async({page},info)=>{
  await page.goto('/');
  await page.getByRole('link',{name:'Client installation →',exact:true}).first().click();
  await expect(page).toHaveURL(/\/install\.html$/);
  await expect(page.getByRole('heading',{level:1})).toHaveText('Update the CSiM dashboard on Superset 6.1.0');
  await expect(page.getByText('Manual bundle ready',{exact:true})).toBeVisible();
  await expect(page.getByText('Automated rehearsal passed',{exact:true})).toBeVisible();
  await expect(page.getByText('Record review is a separate setup',{exact:true})).toBeVisible();
  await expect(page.getByRole('link',{name:'Use the manual installation',exact:true})).toHaveAttribute('href','#manual-install');
  await expect(page.getByRole('link',{name:'Open the automated option',exact:true})).toHaveAttribute('href','#automated-install');
  await expect(page.getByRole('link',{name:'1. Reporting datasets',exact:true})).toHaveAttribute('href','downloads/01-csim-reporting-datasets.zip');
  await expect(page.getByRole('link',{name:'2. Dashboard charts',exact:true})).toHaveAttribute('href','downloads/02-csim-dashboard-charts.zip');
  await expect(page.getByRole('link',{name:'3. Dashboard',exact:true})).toHaveAttribute('href','downloads/03-csim-dashboard.zip');
  await expect(page.locator('#artifacts')).toContainText('Object manifest');
  await expect(page.locator('#contents')).toContainText('It does not carry the rows stored in PostgreSQL');
  await expect(page.locator('#contents')).toContainText("reuses its existing PostgreSQL connection");
  await expect(page.locator('#contents')).toContainText('database name, credentials');
  await expect(page.locator('#before')).toContainText('ENABLE_TEMPLATE_PROCESSING');
  await expect(page.locator('#before')).toContainText('TIME_GRAIN_DENYLIST');
  await expect(page.locator('#before')).toContainText('No custom Superset build is required');
  await expect(page.locator('#manual-install')).toContainText('Keep the order: datasets, charts, dashboard');
  await expect(page.locator('#manual-install')).toContainText('database named data');
  await expect(page.locator('#manual-install')).not.toContainText('Open and save each filter');
  await expect(page.locator('#automated-install')).toContainText('python scripts/dashboard_import.py import --profile client-update');
  await expect(page.locator('#record-review')).toContainText('No database connection is imported or edited');
  await expect(page.locator('#record-review')).toContainText('UTI Individual Historical 2024-2025');
  await expect(page.getByRole('link',{name:'Download the review SQL',exact:true})).toHaveAttribute('href','downloads/csim-record-review.sql');
  await expect(page.locator('#record-review')).toContainText('redcap_repeat_instance');
  await expect(page.locator('#record-review')).toContainText('100,000 rows or a lower server limit');
  for(const width of [1280,390]){
    await page.setViewportSize({width,height:900});
    await page.goto('/install.html#verify');
    await page.locator('#verify h2').scrollIntoViewIfNeeded();
    await expect(page.locator('#verify h2')).toBeInViewport();
    expect(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth)).toBe(true);
    await page.screenshot({path:info.outputPath(`installation-${width}.png`),fullPage:true});
    await page.goto('/install.html#record-review');
    await page.locator('#record-review h2').scrollIntoViewIfNeeded();
    await expect(page.locator('#record-review h2')).toBeInViewport();
    expect(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth)).toBe(true);
    await page.screenshot({path:info.outputPath(`record-review-setup-${width}.png`)});
  }
});
