import {test,expect} from '@playwright/test';
import {profile,reconciled,fixture} from '../acceptance.config.mjs';
import {openDashboard,timePeriod,timeUnit,hospital,waitForChartPaint} from './dashboard.mjs';
import {scene,enableRecording} from './recording.mjs';

enableRecording(test);
test('08 Beth’s September additions preserve context and comparison selections',async({page},info)=>{
  test.skip(!reconciled,'This workflow belongs to the separate September version.');
  const watch=await openDashboard(page,profile);
  if(!fixture)await hospital(page,'53');
  const latestLink=page.getByRole('link',{name:'Latest reporting month',exact:true});
  const id=Number(new URL(await latestLink.getAttribute('href'),'http://local').searchParams.get('slice_id'));
  const card=page.locator(`.dashboard-chart-id-${id}`);
  const expected=fixture?'Apr 2026':'Mar 2026';
  await card.scrollIntoViewIfNeeded();
  await expect(card).toContainText(expected);
  await scene(page,info,'september-opening','Beth’s September version',fixture?'Known hospital 91 is selected for these examples.':'Hospital 53 is selected to review its latest reporting month and comparisons.','September additions');
  const initial=watch.replies.get(id).result.data;
  await timePeriod(page,'2027-01-01','2028-01-01');
  await timeUnit(page,'Year');
  await card.scrollIntoViewIfNeeded();await watch.settle();
  await expect(card).toContainText(expected);
  expect(watch.replies.get(id).result.data).toEqual(initial);
  await scene(page,info,'latest-independent','Latest reporting month','The card still reports the latest month with submissions, even when the viewing window contains no observations.');
  await timePeriod(page,'2025-11-01','2026-05-01');
  await timeUnit(page,'Quarter');
  // Native anchors move within the same document; saved-filter permalinks do not.
  const token=await page.evaluate(()=>window.__reconciliationDocument=crypto.randomUUID());
  const destination=page.locator('a[href="#HEADER-eVOJ7CLoDLTv7Uc8Ct2eU"]');
  await destination.scrollIntoViewIfNeeded();await destination.click();
  await expect(page.locator('[id="HEADER-eVOJ7CLoDLTv7Uc8Ct2eU"]')).toBeInViewport();
  expect(await page.evaluate(()=>window.__reconciliationDocument)).toBe(token);
  if(process.env.CSIM_SIMPLE_CONTROLS==='1'){
    await expect(page.getByLabel('From month',{exact:true})).toHaveValue('2025-11');
    await expect(page.getByLabel('Through month (inclusive)',{exact:true})).toHaveValue('2026-04');
  }else await expect(page.getByRole('button',{name:'Time Period',exact:true})).toContainText('2025-11-01');
  const grain=page.getByRole('combobox',{name:'NATIVE_FILTER-KyTwDhtSKTATUbbB9Yka_',exact:true}).locator('xpath=ancestor::*[contains(concat(" ",normalize-space(@class)," ")," ant-select ")][1]');
  await expect(grain).toContainText('Quarter');
  await page.waitForLoadState('networkidle');await watch.settle();
  await expect(page.getByText(/Waiting on CSiM.*PostgreSQL/).filter({visible:true})).toHaveCount(0);
  await waitForChartPaint(page);
  await scene(page,info,'section-navigation','Section links keep your selections','Jump to antibiotic duration without resetting the reporting window or grouping.');
  const menuReport=[];
  for(const [filter,numeric] of [['NATIVE_FILTER-PsH68K-xwsp1NWi3i2HxI',true],['NATIVE_FILTER-E7fn9Wg9JfYAppl0ZHbXG',false]]){
    const input=page.getByRole('combobox',{name:filter,exact:true});await input.press('ArrowDown');
    const listId=await input.getAttribute('aria-controls');
    const optionNodes=page.locator(`[id="${listId}"]`).getByRole('option');
    await expect.poll(()=>optionNodes.count()).toBeGreaterThan(0);
    const options=await optionNodes.allTextContents();
    expect(options.length).toBeGreaterThan(0);
    for(const option of options)expect(/^[0-9]+([.][0-9]+)?$/.test(option),option).toBe(numeric);
    menuReport.push({numeric,options});
    await input.press('Escape');
  }
  if(fixture){
    await hospital(page,'Demo State','NATIVE_FILTER-E7fn9Wg9JfYAppl0ZHbXG');
    for(const name of ['Cohort/State (duration)','Cohort/State (abx)','Cohort/State (UC location)']){
      const chart=watch.dateAxes.find(c=>c.name===name);
      await chart.holder.scrollIntoViewIfNeeded();await watch.settle();
      await expect.poll(()=>watch.replies.get(chart.id)?.result?.data?.length, {message:`${name} supports the named state selection`}).toBeGreaterThan(0);
      await chart.holder.evaluate(el=>el.scrollIntoView({block:'center',behavior:'instant'}));
      await waitForChartPaint(chart.holder);
      const shot=info.outputPath(`named-state-${chart.id}.png`);await chart.holder.screenshot({path:shot});await info.attach(name,{path:shot,contentType:'image/png'});
      await scene(page,info,`named-state-${chart.id}`,name,'Demo State contains both known hospitals. The selected state produces comparison results.',name==='Cohort/State (duration)'?'Named-state comparisons':undefined);
    }
  }
  await card.scrollIntoViewIfNeeded();await expect(card).toContainText(expected);
  await scene(page,info,'comparison-context','Separate comparison selectors','Your hospital lists hospital codes. Cohort/State lists named groups. Neither changes the latest-data card.');
  await watch.settle();expect(watch.failures).toEqual([]);
  await info.attach('comparison-menus',{body:Buffer.from(JSON.stringify(menuReport)),contentType:'application/json'});
});
