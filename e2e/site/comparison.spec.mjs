import {test,expect} from '@playwright/test';
test('The build comparison exposes matching links, logins and actual screenshot evidence',async({page,context},info)=>{
 await context.grantPermissions(['clipboard-read','clipboard-write']);
 for(const [name,file] of [['main','access.json'],['standard','standard-access.json']])await page.route(`**/${file}`,route=>route.fulfill({json:{username:name,password:`${name}-test`}}));
 await page.goto('/comparison.html');
 await expect(page.getByRole('heading',{level:1})).toHaveText('Does CSiM need custom Superset?');
 for(const [id,name,host] of [['custom','main','dashboard.csim.uwdigi.org'],['official','standard','standard.csim.uwdigi.org']]){
  const card=page.locator('#'+id);const url=new URL(await card.locator('a.button').getAttribute('href'));
  expect(url.hostname).toBe(host);expect(url.searchParams.get('next')).toContain('/superset/dashboard/csim-individual-');
  const copy=card.getByRole('button',{name:`Copy ${name} password`});await copy.click();expect(await page.evaluate(()=>navigator.clipboard.readText())).toBe(`${name}-test`);
 }
 await expect(page.locator('#official')).toContainText('No CSiM application patches');
 const images=page.locator('#screenshots img');await expect(images).toHaveCount(2);
 await expect.poll(()=>images.evaluateAll(nodes=>nodes.every(n=>n.complete&&n.naturalWidth>0))).toBe(true);
 await expect(page.locator('#handover')).toContainText('without GitHub');
 for(const width of [1280,390]){
  await page.setViewportSize({width,height:1000});await page.evaluate(()=>scrollTo(0,0));
  expect(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth)).toBe(true);
  await page.screenshot({path:info.outputPath(`comparison-${width}.png`),fullPage:true});
 }
});
