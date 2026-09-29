import fs from 'node:fs';
import {chromium,expect} from '@playwright/test';
import {env,baseURL,directory,authFile,profile} from '../acceptance.config.mjs';
export default async function setup() {
  fs.mkdirSync(directory,{recursive:true});
  const browser=await chromium.launch();
  try {
    const page=await browser.newPage();
    const slug=process.env.CSIM_DASHBOARD_SLUG || `csim-individual-${profile.startsWith('preview')?'preview':'corrected'}`;
    await page.goto(baseURL+'/login/?next='+encodeURIComponent('/superset/dashboard/'+slug+'/'));
    await page.locator('#username').fill(process.env.CSIM_USERNAME || 'demo');
    await page.locator('#password').fill(process.env.CSIM_PASSWORD || env.CSIM_ADMIN_PASSWORD);
    await page.locator('[type=submit]').click();
    // Match the actual pathname, not a dashboard URL inside login's next parameter.
    await expect(page).toHaveURL(url=>url.pathname===`/superset/dashboard/${slug}/`||url.pathname===`/dashboard/${slug}/`,{timeout:60000});
    await expect(page.locator('[data-test=dashboard-header-container]')).toBeVisible();
    await page.context().storageState({path:authFile});
  } finally {await browser.close();}
}
