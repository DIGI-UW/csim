import {test,expect} from '@playwright/test';

test('Data guide explains the complete source and lookup update for a new hospital', async ({page}, info) => {
  await page.goto('/data-guide.html');
  await expect(page.getByRole('heading',{level:1})).toHaveText('Where the data comes from');
  await expect(page.locator('#uploads')).toContainText('two-table update');
  await expect(page.locator('#uploads')).toContainText('complete lookup file');
  await expect(page.locator('#uploads')).toContainText('exactly one lookup row');
  await expect(page.locator('#uploads')).toContainText('hosp_name');
  await expect(page.locator('#uploads')).toContainText('hosp_code');
  await page.setViewportSize({width:390,height:844});
  await page.locator('#uploads h2').scrollIntoViewIfNeeded();
  await expect(page.locator('#uploads h2')).toBeInViewport();
  expect(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth)).toBe(true);
  await page.screenshot({path:info.outputPath('new-hospital-guidance-phone.png')});
});
