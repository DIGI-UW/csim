import {scene,enableRecording} from './recording.mjs';
import {test,expect} from '@playwright/test';
import {profile} from '../acceptance.config.mjs';
import {openDashboard,timePeriod,waitForChartPaint} from './dashboard.mjs';

enableRecording(test);
test('01 All twenty baseline charts load or report legitimate empty results',async({page},info)=>{
  const watch=await openDashboard(page,profile);
  await timePeriod(page,'2025-11-01','2026-05-01');
  const links=page.locator('a[href*="slice_id="]');
  const report=[];
  for(let i=0;i<20;i++){
    const link=links.nth(i),title=await link.innerText();
    const id=Number(new URL(await link.getAttribute('href'),'http://local').searchParams.get('slice_id'));
    const holder=page.locator(`.dashboard-chart-id-${id}`);
    await holder.scrollIntoViewIfNeeded();
    await page.waitForLoadState('networkidle');await watch.settle();
    await expect.poll(()=>watch.replies.get(id)?.result).toBeTruthy();
    const result=watch.replies.get(id).result;
    expect(result.error).toBeNull();
    expect(result.status).toBe('success');
    await expect(holder.getByText('Waiting on CSiM demo PostgreSQL',{exact:true})).toHaveCount(0);
    await expect(holder.getByText('Data error',{exact:true})).toHaveCount(0);
    await expect(holder.getByText(/An error occurred while rendering/)).toHaveCount(0);
    if(title.includes('latest comparison')&&result.data.length>0)await expect(holder.locator('table,[role=grid]').first()).toBeVisible();
    await waitForChartPaint(holder);
    const shot=info.outputPath(`chart-${id}.png`);
    await holder.screenshot({path:shot});
    await info.attach(`chart-${id}`,{path:shot,contentType:'image/png'});
    report.push({id,title,rows:result.data.length,status:result.status});
    if([0,4,8,12,16,19].includes(i))await scene(page,info,`section-${i}`,title,'The full April dashboard retains all 20 charts with their original measures and layout.',i===0?'Full dashboard':undefined);
  }
  await watch.settle();expect(watch.failures).toEqual([]);
  await info.attach('full-dashboard-inventory',{body:Buffer.from(JSON.stringify(report)),contentType:'application/json'});
});
