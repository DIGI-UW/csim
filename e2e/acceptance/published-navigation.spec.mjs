import {test,expect} from '@playwright/test';
import {baseURL} from '../acceptance.config.mjs';
const overview=process.env.CSIM_OVERVIEW_URL;
const path='/superset/dashboard/csim-individual-standard-month-selectors/';
async function currentDashboard(page){
  await expect(page).toHaveURL(new RegExp(path));
  const period=page.getByRole('button',{name:'Time Period',exact:true});
  await expect(period).toBeVisible();
  const title=page.getByRole('textbox',{name:'Dashboard title',exact:true});
  const p=await period.boundingBox(),t=await title.boundingBox();
  expect(p.x+p.width).toBeLessThanOrEqual(t.x+20);
}
test('Published overview, existing login and old bookmarks open the current left-filter dashboard',async({page},info)=>{
  test.skip(!overview,'Public routes are checked after deployment');
  await page.goto(overview);
  await page.getByRole('link',{name:'Open recommended dashboard →',exact:true}).click();
  await currentDashboard(page);
  await page.screenshot({path:info.outputPath('overview-to-current.png')});
  for(const entry of ['/', '/login/?next='+encodeURIComponent(path),'/superset/dashboard/csim-individual-standard-sortable/?native_filters_key=old']){
    await page.goto(baseURL+entry);await currentDashboard(page);
  }
});
test('Signed-out overview entry preserves the intended dashboard through login',async({browser},info)=>{
  test.skip(!overview,'Public routes are checked after deployment');
  const context=await browser.newContext({storageState:{cookies:[],origins:[]},viewport:{width:1600,height:1100}});
  try{
    const page=await context.newPage();await page.goto(overview);
    await page.getByRole('link',{name:'Open recommended dashboard →',exact:true}).click();
    await expect(page.locator('#username')).toBeVisible();
    const destination=new URL(new URL(page.url()).searchParams.get('next'),baseURL);
    expect(destination.pathname).toBe(path);
    await page.locator('#username').fill(process.env.CSIM_USERNAME);
    await page.locator('#password').fill(process.env.CSIM_PASSWORD);
    await page.locator('[type=submit]').click();
    await currentDashboard(page);
    await page.screenshot({path:info.outputPath('login-to-current.png')});
  }finally{await context.close();}
});
test('Public dashboard gallery contains only the current dashboard and known-record example',async({page},info)=>{
  test.skip(!overview,'Public cleanup is checked after deployment');
  await page.goto(baseURL+path);
  await page.getByRole('button',{name:'Dashboards',exact:true}).click();
  const dashboards=page.locator('table a[href^="/superset/dashboard/"]');
  await expect(dashboards).toHaveCount(2);
  expect((await dashboards.evaluateAll(links=>links.map(a=>a.getAttribute('href')))).sort()).toEqual([
    path,'/superset/dashboard/csim-standard-month-selectors-examples/'
  ].sort());
  await page.screenshot({path:info.outputPath('current-dashboard-gallery.png')});
});
