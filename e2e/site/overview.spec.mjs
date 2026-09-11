import {test,expect} from '@playwright/test';
test('Overview links each issue to a solution, evidence, and the matching instance',async({page})=>{
  await page.goto('/');
  await expect(page.getByRole('heading',{level:1})).toContainText('CSiM dashboard issues');
  const missing=await page.locator('a[href^="#"]').evaluateAll(links=>links.filter(link=>!document.getElementById(link.hash.slice(1))).map(link=>link.hash));
  expect(missing).toEqual([]);
  for(const [id,host] of [['demo-instance','dashboard.csim.uwdigi.org'],['snapshot-instance','preview.csim.uwdigi.org']]){
    const box=page.locator('#'+id);
    await expect(box.locator('a.instance-open')).toHaveAttribute('href',new RegExp('https://'+host+'/login/'));
    await expect(box).toContainText('Username:');
    await expect(box).toContainText('Password:');
  }
  await page.getByRole('link',{name:'3. Remaining issues',exact:true}).first().click();
  await expect(page.locator('#next-title')).toBeInViewport();
  const detail=page.locator('details').filter({has:page.locator('summary').filter({hasText:'How the source exports differ'})});
  await detail.locator('summary').click();
  await expect(detail).toContainText('20-chart');
});
test('Overview remains readable on a phone',async({page})=>{
  await page.setViewportSize({width:390,height:844});await page.goto('/');
  expect(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth)).toBe(true);
  const menu=page.locator('.mobile-nav');await menu.locator('summary').click();
  await menu.getByRole('link',{name:'Original issues',exact:true}).click();
  await expect(page.locator('#status')).toBeInViewport();
});
