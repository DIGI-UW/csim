import {test,expect} from '@playwright/test';
import {profile,fixture} from '../acceptance.config.mjs';
import {openDashboard,hospital,allTrends} from './dashboard.mjs';

test('Applying an edited range immediately preserves the entered dates',async({page})=>{
  test.skip(!fixture,'Uses known fixture records.');
  const watch=await openDashboard(page,profile);
  await hospital(page,'91');
  await page.getByRole('button',{name:'Time Period',exact:true}).click();
  const editor=page.getByRole('tooltip').filter({hasText:'Edit time range'});
  await editor.getByRole('combobox',{name:'Range type',exact:true}).press('ArrowDown');
  await page.getByRole('option',{name:'Advanced',exact:true}).click();
  await editor.getByRole('textbox').nth(0).fill('2026-02-01');
  await editor.getByRole('textbox').nth(1).fill('2026-04-01');
  await editor.getByRole('button',{name:/^apply$/i}).click();
  await page.getByRole('button',{name:'Apply filters',exact:true}).click();
  await expect(page.getByRole('button',{name:'Time Period',exact:true})).toContainText('2026-02-01');
  const results=await allTrends(watch);
  const values=results[watch.trends[4].name].map(row=>row[Object.keys(row).find(key=>key!=='month_date')]);
  expect(values).toEqual([null,10]);
});
