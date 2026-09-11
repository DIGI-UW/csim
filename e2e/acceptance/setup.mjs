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
    await expect(page).toHaveURL(new RegExp('/(?:superset/)?dashboard/'+slug+'/'),{timeout:60000});
    await page.context().storageState({path:authFile});
  } finally {await browser.close();}
}
