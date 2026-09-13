import {test,expect} from '@playwright/test';
import {reconciled,fixture,dataProfile} from '../acceptance.config.mjs';
import {openDashboard,hospital,filters,waitForChartPaint} from './dashboard.mjs';
import {scene,enableRecording} from './recording.mjs';

enableRecording(test);
const lowerHospital='NATIVE_FILTER-PsH68K-xwsp1NWi3i2HxI';
const names=['Your hospital (abx)','Your hospital (UC location)','Your hospital (duration)','All-time UC submissions by your hospital'];
const values=result=>result.data.flatMap(row=>Object.entries(row)
  .filter(([key,value])=>typeof value==='number'&&!/month_date|timestamp/i.test(key)&&Math.abs(value)<1e11)
  .map(([,value])=>value));

test('09 Cohort opening, hospital totals, and clear/reselect',async({page},info)=>{
  test.skip(!reconciled||fixture,'Cohort opening belongs to the supplied-data September version.');
  const watch=await openDashboard(page);
  const select=id=>page.getByRole('combobox',{name:id,exact:true})
    .locator('xpath=ancestor::*[contains(concat(" ",normalize-space(@class)," ")," ant-select ")][1]');
  await expect(select(filters.hospital)).toContainText('Cohort');
  await expect(select(lowerHospital).locator('.ant-select-selection-item')).toHaveCount(0);
  const charts=[];
  for(const name of names){
    const link=page.getByRole('link',{name,exact:true});
    const id=Number(new URL(await link.getAttribute('href'),'http://local').searchParams.get('slice_id'));
    charts.push({name,id,holder:page.locator(`.dashboard-chart-id-${id}`)});
  }
  const checkEmpty=async()=>{
    for(const chart of charts){
      await chart.holder.scrollIntoViewIfNeeded();await watch.settle();
      await expect.poll(()=>watch.replies.get(chart.id)?.result).toBeTruthy();
      const result=watch.replies.get(chart.id).result;
      expect(result.error,chart.name).toBeNull();
      expect(values(result),`${chart.name}: no combined hospital values`).toEqual([]);
      await expect(chart.holder.getByText('Choose a hospital in “Your hospital”',{exact:true})).toBeVisible();
    }
  };
  await checkEmpty();
  await scene(page,info,'opening-selection','Choose a hospital for the lower comparisons','The main charts open with Cohort. The lower hospital panels wait for your hospital selection.','Hospital selection');
  const total=charts.at(-1);
  for(const phase of ['selected','reselected']){
    await hospital(page,dataProfile.openingHospital,lowerHospital);
    for(const chart of charts){
      await chart.holder.scrollIntoViewIfNeeded();await watch.settle();
      await expect.poll(()=>watch.replies.get(chart.id)?.result).toBeTruthy();
      const result=watch.replies.get(chart.id).result;
      expect(result.error,chart.name).toBeNull();
      expect(values(result).some(Number.isFinite),chart.name).toBe(true);
      await expect(chart.holder.getByText(/Choose a hospital in/)).toHaveCount(0);
      await waitForChartPaint(chart.holder);
    }
    // Independently counted from the supplied current and historical demo rows.
    expect(values(watch.replies.get(total.id).result)).toEqual([980]);
    await scene(page,info,`${phase}-hospital-total`,'Hospital 53: 980 all-time submissions','The total is for this hospital. Time Period changes the trends; this card keeps its labelled all-time scope.');
    if(phase==='reselected')break;
    await select(lowerHospital).hover();
    await select(lowerHospital).locator('.ant-select-clear').click();
    await page.getByRole('button',{name:'Apply filters',exact:true}).click();
    await page.waitForLoadState('networkidle');
    await checkEmpty();
    await scene(page,info,'cleared-hospital','Clearing returns to the selection prompt','No all-hospital total replaces the hospital value. Reselecting works on this same page.');
  }
  expect(watch.failures).toEqual([]);
});
