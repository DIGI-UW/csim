import {test,expect} from '@playwright/test';

test('Shared catalogue is reachable and readable on desktop and mobile',async({page},info)=>{
  await page.goto('/');
  await page.getByRole('link',{name:'Filters and charts catalogue →',exact:true}).click();
  await expect(page).toHaveURL(/\/filter-guide\.html$/);
  await expect(page.getByRole('heading',{level:1})).toHaveText('Filters, charts and remaining issues');
  await expect(page.locator('#controls tbody tr')).toHaveCount(6);
  await expect(page.locator('#chart-map tbody tr')).toHaveCount(8);
  await expect(page.getByRole('link',{name:'Open the dashboard →',exact:true})).toHaveAttribute('href','https://standard.csim.uwdigi.org/superset/dashboard/csim-individual-standard-month-selectors/');
  for(const width of [1280,390]){
    await page.setViewportSize({width,height:900});
    await page.getByRole('link',{name:'Which charts they affect',exact:true}).click();
    await expect(page.locator('#chart-map h2')).toBeInViewport();
    expect(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth)).toBe(true);
    await page.screenshot({path:info.outputPath(`catalogue-map-${width}.png`)});
  }
  await page.locator('summary').click();
  const image=page.getByRole('img',{name:/Hospital 53 therapy table/});
  await expect(image).toBeVisible();
  expect(await image.evaluate(el=>el.complete&&el.naturalWidth>0)).toBe(true);
  await page.getByRole('link',{name:'See the known limitation.',exact:true}).click();
  await expect(page).toHaveURL(/beth-review\.html#clear-all$/);
  await expect(page.locator('#clear-all h2')).toBeInViewport();
});
