import fs from 'node:fs';
import {chromium,expect} from '@playwright/test';
import {env,baseURL,directory,authFile} from '../acceptance.config.mjs';
export default async function setup() {
  fs.mkdirSync(directory,{recursive:true});
  const browser=await chromium.launch();
  try {
    const page=await browser.newPage();
    await page.goto(baseURL+'/login/');
    await page.locator('#username').fill('demo');
    await page.locator('#password').fill(env.CSIM_ADMIN_PASSWORD);
    await page.locator('[type=submit]').click();
    await expect(page).not.toHaveURL(/\/login\//);
    await page.context().storageState({path:authFile});
  } finally {await browser.close();}
}
