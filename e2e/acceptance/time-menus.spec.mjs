import {test,expect} from '@playwright/test';
import {profile} from '../acceptance.config.mjs';
import {openDashboard,filters} from './dashboard.mjs';

test('Time Unit choices match this build and remain independent in the snapshot',async({page},info)=>{
  test.skip(profile.includes('fixture'),'Companion menu workflow runs on the supplied demo instance.');
  await openDashboard(page,profile);
  const grain=page.getByRole('combobox',{name:filters.grain,exact:true});
  await grain.press('ArrowDown');
  const menu=page.locator('.ant-select-dropdown:visible');
  await expect(menu.locator('.ant-select-item-option-content')).toHaveText(['Month','Quarter','Year']);
  await info.attach('csim-time-units',{body:await page.screenshot(),contentType:'image/png'});
  if(!profile.startsWith('preview'))return;
  await page.goto('/superset/dashboard/hourly-reporting-preview/');
  const control=page.getByRole('combobox',{name:'NATIVE_FILTER-preview-hourly',exact:true});
  await expect(control).toBeVisible();
  await control.press('ArrowDown');
  await expect(page.locator('.ant-select-dropdown:visible .ant-select-item-option-content')).toHaveText(['Hour','Day','Week']);
  await info.attach('hourly-time-units',{body:await page.screenshot(),contentType:'image/png'});
  const response=page.waitForResponse(r=>r.url().includes('/api/v1/chart/data')&&r.request().method()==='POST');
  await page.getByRole('option',{name:'Day',exact:true}).click();
  await page.getByRole('button',{name:'Apply filters',exact:true}).click();
  const body=await (await response).json();
  expect(body.result[0].data.map(row=>row.Specimens)).toEqual([72,72]);
  await page.goto('/superset/dashboard/csim-individual-preview/');
  await page.getByRole('combobox',{name:filters.grain,exact:true}).press('ArrowDown');
  await expect(page.locator('.ant-select-dropdown:visible .ant-select-item-option-content')).toHaveText(['Month','Quarter','Year']);
});
