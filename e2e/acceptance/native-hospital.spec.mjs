import {test,expect} from '@playwright/test';
import {profile,fixture} from '../acceptance.config.mjs';
import {openDashboard,hospital,revealFilter,dashboardApply,waitForChartPaint} from './dashboard.mjs';

test('Native hospital panels retain selection guidance and never combine unset hospitals',async({page},info)=>{
  test.skip(!['standard','development'].includes(profile)||fixture);
  const watch=await openDashboard(page,profile);
  const marker=await page.evaluate(()=>window.__nativeHospitalDocument=crypto.randomUUID());
  const control=page.getByRole('combobox',{name:'NATIVE_FILTER-PsH68K-xwsp1NWi3i2HxI',exact:true});
  const selection=control.locator('xpath=ancestor::*[contains(concat(" ",normalize-space(@class)," ")," ant-select ")][1]');
  const charts=[];
  for(const name of ['Your hospital (abx)','Your hospital (UC location)','Your hospital (duration)','All-time UC submissions by your hospital']){
    const link=page.getByRole('link',{name,exact:true});
    const id=Number(new URL(await link.getAttribute('href'),'http://local').searchParams.get('slice_id'));
    charts.push({name,id,holder:page.locator(`.dashboard-chart-id-${id}`)});
  }
  const numbers=result=>result.data.flatMap(row=>Object.entries(row)
    .filter(([key,value])=>!['month_date','period_label'].includes(key)&&typeof value==='number'&&Math.abs(value)<1e11)
    .map(([,value])=>value));
  for(const phase of ['opening','selected','cleared','reselected']){
    if(phase==='selected'||phase==='reselected')await hospital(page,'53','NATIVE_FILTER-PsH68K-xwsp1NWi3i2HxI');
    if(phase==='cleared'){
      await revealFilter(page,control);await selection.hover();
      await selection.locator('.ant-select-clear').click();
      await dashboardApply(page).click();await page.waitForLoadState('networkidle');
    }
    const empty=phase==='opening'||phase==='cleared';
    if(empty){
      await expect(selection.locator('.ant-select-selection-item')).toHaveCount(0);
      // The native candidate uses permanent instructions beside its standard
      // empty-state panels. It does not claim the custom inline prompt exists.
      const guidance=page.getByText(/Choose Your hospital in the filter bar/).first();
      await guidance.scrollIntoViewIfNeeded();await expect(guidance).toBeVisible();
      await page.waitForLoadState('networkidle');await watch.settle();
      await waitForChartPaint(page);
      await page.screenshot({path:info.outputPath(`${phase}-selection-guidance.png`)});
    }
    for(const chart of charts){
      await chart.holder.scrollIntoViewIfNeeded();await watch.settle();
      await expect.poll(()=>watch.replies.get(chart.id)?.result).toBeTruthy();
      const result=watch.replies.get(chart.id).result;
      expect(result.error,chart.name).toBeNull();
      if(empty){
        expect(numbers(result),chart.name).toEqual([]);
        await expect(chart.holder.getByText(/No results were returned for this query|^No data$/).first()).toBeVisible();
      }else{
        expect(numbers(result).some(Number.isFinite),chart.name).toBe(true);
        if(chart===charts.at(-1))expect(numbers(result)).toEqual([980]);
      }
      await waitForChartPaint(chart.holder);
      await chart.holder.screenshot({path:info.outputPath(`${phase}-${chart.id}.png`)});
    }
  }
  expect(await page.evaluate(()=>window.__nativeHospitalDocument)).toBe(marker);
  expect(watch.failures).toEqual([]);
});
