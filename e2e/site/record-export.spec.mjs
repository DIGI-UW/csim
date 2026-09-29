import {test,expect} from '@playwright/test';
test('Record export guide has playable evidence and download instructions',async({page},info)=>{
  await page.goto('/record-export.html');
  await expect(page.getByRole('heading',{level:1})).toHaveText('Download individual records as CSV');
  await expect(page.locator('#steps')).toContainText('Update chart');
  await expect(page.locator('#steps')).toContainText('Export All Data');
  await expect(page.locator('#contents')).toContainText('separate from the main client dashboard update package');
  const media=page.locator('video');
  await expect.poll(()=>media.evaluate(v=>v.readyState)).toBeGreaterThanOrEqual(1);
  expect(await media.evaluate(v=>v.duration)).toBeGreaterThan(30);
  await media.evaluate(v=>v.play());
  await expect.poll(()=>media.evaluate(v=>v.currentTime)).toBeGreaterThan(1);
  await media.evaluate(v=>v.pause());
  for(const path of ['captions.vtt','verification.json','poster.png'])expect((await page.request.get('/evidence/record-export/'+path)).ok()).toBe(true);
  await page.screenshot({path:info.outputPath('export-guide-desktop.png'),fullPage:true});
  await page.setViewportSize({width:390,height:844});
  expect(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth)).toBe(true);
  await page.screenshot({path:info.outputPath('export-guide-phone.png'),fullPage:true});
});
