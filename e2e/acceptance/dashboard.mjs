import {chartCount} from '../acceptance.config.mjs';
import {expect} from '@playwright/test';
export const trendNames=[
  'Inappropriate UTI diagnosis (time series)',
  'Inappropriate UTI+ASPN diagnosis (time series)',
  'Positive UA (time series)',
  'Therapy duration (time series)',
  'UC submissions (time series)',
];
export const additionalDateNames=['Your hospital (abx)','Cohort/State (abx)','Your hospital (UC location)','Cohort/State (UC location)','Your hospital (duration)','Cohort/State (duration)'];
export const filters={hospital:'NATIVE_FILTER-yTQKvlEARkQ8t2O7SfLEE',grain:'NATIVE_FILTER-KyTwDhtSKTATUbbB9Yka_'};
export const dashboardApply=page=>page.locator('[data-test="filter-bar__apply-button"]');
export async function revealFilter(page,control){
  if(await page.getByRole('button',{name:/More filters/}).count()){
    // Dismiss the previous overflow popover before locating the next control.
    // Its closing animation can otherwise leave a transient visible duplicate.
    await page.locator('[data-test="dashboard-header-container"]').click({position:{x:4,y:4}});
    await expect(page.locator('.ant-popover:visible')).toHaveCount(0);
  }
  if(!await control.isVisible()){
    const more=page.getByRole('button',{name:/More filters/});
    if(await more.isVisible())await more.click();
  }
  await expect(control).toBeVisible();
}
export async function openDashboard(page,profile='corrected') {
  const replies=new Map(),failures=[],jobs=new Set(),latest=new Map();
  page.on('request',request=>{
    if(!request.url().includes('/api/v1/chart/data') || request.method()!=='POST')return;
    const id=request.postDataJSON()?.form_data?.slice_id;
    if(id){latest.set(id,request);replies.delete(id);}
  });
  page.on('response',response=>{
    if(!response.url().includes('/api/v1/chart/data'))return;
    const job=(async()=>{
      try{
        const request=response.request().postDataJSON();
        const id=request?.form_data?.slice_id;
        const body=await response.json();
        if(!response.ok()||body.result?.some(r=>r.error))failures.push({id,status:response.status(),body});
        if(id && latest.get(id)===response.request())replies.set(id,{request,result:body.result?.[0]});
      }catch(error){if(!/No resource|No data found|aborted/i.test(error.message))failures.push({error:error.message});}
    })();jobs.add(job);job.finally(()=>jobs.delete(job));
  });
  await page.addInitScript(()=>{
    const proto=CanvasRenderingContext2D.prototype,fill=proto.fillText,clear=proto.clearRect;
    proto.clearRect=function(...args){if(args[0]===0&&args[1]===0)this.canvas.__periodLabels=[];return clear.apply(this,args);};
    proto.fillText=function(text,x,y,...rest){
      // Capture wrong native labels too. The acceptance assertion still requires
      // Jan 2025 / Q1 2025 / 2025; this observer must not hide contrary evidence.
      if(/^(?:\d{4}(?: Q[1-4]|-\d{2}(?: \([A-Z][a-z]{2}\))?)?|Q[1-4] \d{4}|(?:Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)(?: \d{4})?)$/.test(String(text))){
        const point=new DOMPoint(x,y).matrixTransform(this.getTransform());
        const metrics=this.measureText(text),matrix=this.getTransform();
        const corners=[x-metrics.actualBoundingBoxLeft,x+metrics.actualBoundingBoxRight]
          .flatMap(px=>[y-metrics.actualBoundingBoxAscent,y+metrics.actualBoundingBoxDescent]
            .map(py=>new DOMPoint(px,py).matrixTransform(matrix)));
        (this.canvas.__periodLabels ||= []).push({text:String(text),x:point.x,y:point.y,
          left:Math.min(...corners.map(p=>p.x)),right:Math.max(...corners.map(p=>p.x)),
          top:Math.min(...corners.map(p=>p.y)),bottom:Math.max(...corners.map(p=>p.y))});
      }return fill.call(this,text,x,y,...rest);
    };
  });
  const slug=process.env.CSIM_DASHBOARD_SLUG || `csim-individual-${profile.startsWith('preview')?'preview':profile==='baseline'?'baseline':'corrected'}`;
  await page.goto(`/superset/dashboard/${slug}/`);
  await expect(dashboardApply(page)).toBeVisible();
  const links=page.locator('a[href*="slice_id="]');
  await expect(links).toHaveCount(chartCount);
  await page.waitForLoadState('networkidle');
  const dateAxes=[];
  for(const name of [...trendNames,...additionalDateNames]){
    const link=page.getByRole('link',{name,exact:true});
    const href=await link.getAttribute('href');
    const id=Number(new URL(href,'http://local').searchParams.get('slice_id'));
    dateAxes.push({name,id,plot:page.locator(`#chart-id-${id}`),holder:page.locator('[data-test=dashboard-component-chart-holder]').filter({has:link})});
  }
  const trends=dateAxes.filter(item=>trendNames.includes(item.name));
  return {trends,dateAxes,replies,failures,settle:()=>Promise.all([...jobs])};
}

// Canvas animations can continue after the data response and axis text arrive.
// Wait for unchanged pixels before accepting or capturing the visible result.
export async function waitForChartPaint(scope){
  const canvases=scope.locator('canvas');
  if(!await canvases.count())return;
  let previous='';
  await expect.poll(async()=>{
    const current=await canvases.evaluateAll(items=>items.map(c=>c.toDataURL()).join('|'));
    const stable=current===previous;previous=current;return stable;
  },{message:'Chart pixels must settle before screenshot validation',intervals:[200,250,350]}).toBe(true);
}

export async function paintedPeriodBounds(plot){
  return plot.locator('canvas').evaluateAll(canvases=>canvases.flatMap(canvas=>{
    const scale=canvas.clientWidth/canvas.width;
    const labels=[...new Map((canvas.__periodLabels||[]).map(label=>[label.text,label])).values()];
    return labels.map(label=>({...label,x:label.x*scale,y:label.y*scale,left:label.left*scale,right:label.right*scale,top:label.top*scale,bottom:label.bottom*scale,canvasWidth:canvas.clientWidth,canvasHeight:canvas.clientHeight}));
  }).sort((a,b)=>a.x-b.x));
}
export async function timeUnit(page,name){
  const control=page.getByRole('combobox',{name:filters.grain,exact:true});
  await revealFilter(page,control);
  const current=await control.evaluate(el=>el.closest('[title]')?.getAttribute('title') || el.closest('.ant-select').querySelector('.ant-select-selection-item')?.getAttribute('title'));
  if(current===name)return;
  await control.press('ArrowDown');
  await page.getByRole('option',{name,exact:true}).click();
  await dashboardApply(page).click();
  await page.waitForLoadState('networkidle');
}
export async function timePeriod(page,from,until){
  if(process.env.CSIM_SIMPLE_CONTROLS==='1'){
    const end=new Date(until+'T00:00:00Z');end.setUTCMonth(end.getUTCMonth()-1);
    await page.getByLabel('From month',{exact:true}).fill(from.slice(0,7));
    await page.getByLabel('Through month (inclusive)',{exact:true}).fill(end.toISOString().slice(0,7));
    const apply=dashboardApply(page);
    if(await apply.isEnabled())await apply.click();
    await page.waitForLoadState('networkidle');
    return;
  }
  await revealFilter(page,page.getByRole('button',{name:'Time Period',exact:true}));
  await page.getByRole('button',{name:'Time Period',exact:true}).click();
  const editor=page.getByRole('tooltip').filter({hasText:'Edit time range'});
  const rangeType=editor.getByRole('combobox',{name:'Range type',exact:true});
  const selectedType=await rangeType.evaluate(el=>el.closest('.ant-select')?.textContent);
  if(!selectedType?.includes('Advanced')){
    await rangeType.press('ArrowDown');
    await page.getByRole('option',{name:'Advanced',exact:true}).click();
  }
  const boxes=editor.getByRole('textbox');
  await boxes.nth(0).fill(from);
  await boxes.nth(1).fill(until);
  await expect(editor.getByText(`${from} ≤ col < ${until}`,{exact:true})).toBeVisible();
  await editor.getByRole('button',{name:/^apply$/i}).click();
  await expect(page.getByRole('button',{name:'Time Period',exact:true})).toContainText(from);
  await dashboardApply(page).click();
  await page.waitForLoadState('networkidle');
}
export async function paintedLabels(plot){
  return plot.locator('canvas').evaluateAll(canvases=>{
    const unique=new Map(canvases.flatMap(c=>c.__periodLabels||[]).map(label=>[label.text,label]));
    return [...unique.values()].sort((a,b)=>a.x-b.x).map(label=>label.text);
  });
}

export async function hospital(page,name,id=filters.hospital){
  const control=page.getByRole('combobox',{name:id,exact:true});
  await revealFilter(page,control);
  const remove=control.locator('xpath=ancestor::*[contains(concat(" ",normalize-space(@class)," ")," ant-select ")][1]').locator('.ant-select-selection-item-remove');
  while(await remove.count())await remove.first().click();
  if(await control.getAttribute('aria-expanded') !== 'true')await control.press('ArrowDown');
  await control.fill(name);
  const listId=await control.getAttribute('aria-controls');
  const menu=page.locator(`[id="${listId}"]`).locator('xpath=ancestor::*[contains(concat(" ",normalize-space(@class)," ")," ant-select-dropdown ")][1]');
  await menu.getByTitle(name,{exact:true}).click();
  await control.press('Escape');
  const apply=dashboardApply(page);
  if(await apply.isEnabled())await apply.click();
  await page.waitForLoadState('networkidle');
}
export async function allTrends(watch){
  const rows={};
  for(const trend of watch.trends){
    await trend.holder.scrollIntoViewIfNeeded();
    await trend.holder.page().waitForLoadState('networkidle');
    await watch.settle();
    await expect.poll(()=>watch.replies.get(trend.id)?.result).toBeTruthy();
    await watch.settle();
    await waitForChartPaint(trend.plot);
    rows[trend.name]=watch.replies.get(trend.id).result.data;
  }
  return rows;
}

export async function location(page,name){
  const control=page.getByRole('combobox',{name:'NATIVE_FILTER-BPP7wo77GPPbinIYZiwM8',exact:true});
  await revealFilter(page,control);
  await control.press('ArrowDown');
  await page.getByRole('option',{name,exact:true}).click();
}
