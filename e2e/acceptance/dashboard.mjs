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
const selectTrigger=control=>control.locator('xpath=ancestor::*[contains(concat(" ",normalize-space(@class)," ")," ant-select ")][1]').locator(':scope > .ant-select-selector, :scope > .ant-select-content');
export const dashboardApply=page=>page.locator('[data-test="filter-bar__apply-button"]');
export async function revealFilter(page,control){
  if(await page.getByRole('button',{name:/More filters/}).count()){
    // Dismiss the previous overflow popover before locating the next control.
    // Its closing animation can otherwise leave a transient visible duplicate.
    await page.locator('[data-test="dashboard-header-container"]').click({position:{x:4,y:4}});
    await expect(page.locator('.ant-popover:visible')).toHaveCount(0);
    // The native overflow menu closes on any document scroll. Return to
    // the top before opening it, then let the visible charts finish loading.
    await page.evaluate(()=>window.scrollTo({top:0,behavior:'instant'}));
    await page.waitForLoadState('networkidle');
  }
  if(!await control.isVisible()){
    const more=page.getByRole('button',{name:/More filters/});
    if(await more.isVisible()){
      await more.scrollIntoViewIfNeeded();
      // Superset closes More filters on document scroll. Finish the browser's
      // positioning before opening it, so a late scroll cannot dismiss it.
      let previous;
      await expect.poll(async()=>{
        const position=await page.evaluate(()=>`${window.scrollX},${window.scrollY}`);
        const stable=position===previous;previous=position;return stable;
      },{intervals:[100,100]}).toBe(true);
      await more.click();
    }
  }
  await expect(control).toBeVisible();
  // Ant's overflow popover is mounted while its scale animation is still at
  // zero. Wait for the control's real, stationary position before clicking;
  // an intermediate click can scroll the document and dismiss the popover.
  // Measure the visible Select surface: its search input can be only a few
  // pixels wide when a value is already selected.
  const surface=await control.evaluate(el=>Boolean(el.closest('.ant-select')))
    ?selectTrigger(control):control;
  let previousBounds;
  await expect.poll(async()=>{
    const bounds=await surface.boundingBox();
    if(!bounds||bounds.height<20||bounds.width<20)return false;
    const position=[bounds.x,bounds.y,bounds.width,bounds.height].map(Math.round).join(',');
    const stable=position===previousBounds;previousBounds=position;
    return stable;
  },{message:'Filter must finish opening before interaction',intervals:[100,100]}).toBe(true);
}
export async function openDashboard(page,profile='corrected') {
  const replies=new Map(),failures=[],jobs=new Set(),latest=new Map(),network=[];
  page.on('request',request=>{
    if(!request.url().includes('/api/v1/chart/data') || request.method()!=='POST')return;
    const id=request.postDataJSON()?.form_data?.slice_id;
    if(id){latest.set(id,request);replies.delete(id);network.push({id,event:"request",at:Date.now()});}
  });
  page.on('requestfailed',request=>{
    if(!request.url().includes('/api/v1/chart/data') || request.method()!=='POST')return;
    network.push({id:request.postDataJSON()?.form_data?.slice_id,event:'failed',reason:request.failure()?.errorText,at:Date.now()});
  });
  page.on('response',response=>{
    if(!response.url().includes('/api/v1/chart/data'))return;
    const job=(async()=>{
      try{
        const request=response.request().postDataJSON();
        const id=request?.form_data?.slice_id;
        network.push({id,event:"response",status:response.status(),at:Date.now()});
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
  const links=page.locator('[data-test=dashboard-component-chart-holder] a[href*="slice_id="]');
  await expect(links).toHaveCount(chartCount);
  // Superset can keep unrelated background requests active after the dashboard
  // is usable. The controls and complete chart inventory establish page
  // readiness here; each workflow separately awaits its chart responses and
  // settled pixels before asserting results or taking evidence screenshots.
  const dateAxes=[];
  for(const name of [...trendNames,...additionalDateNames]){
    const link=page.getByRole('link',{name,exact:true});
    const href=await link.getAttribute('href');
    const id=Number(new URL(href,'http://local').searchParams.get('slice_id'));
    dateAxes.push({name,id,plot:page.locator(`#chart-id-${id}`),holder:page.locator('[data-test=dashboard-component-chart-holder]').filter({has:link})});
  }
  const trends=dateAxes.filter(item=>trendNames.includes(item.name));
  return {trends,dateAxes,replies,failures,network,settle:()=>Promise.all([...jobs])};
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
  return selectValue(page,name,filters.grain);
}
export async function timePeriod(page,from,until){
  if(process.env.CSIM_NATIVE_MONTHS==='1'){
    const end=new Date(until+'T00:00:00Z');end.setUTCMonth(end.getUTCMonth()-1);
    await selectValue(page,from.slice(0,7),'NATIVE_FILTER-csim-from_month');
    await selectValue(page,end.toISOString().slice(0,7),'NATIVE_FILTER-csim-through_month');
    return;
  }
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

export async function hospital(page,name,id=filters.hospital,options){
  return selectValue(page,name,id,options);
}

export async function selectValue(page,name,id,{apply:applySelection=true}={}){
  const control=page.getByRole('combobox',{name:id,exact:true});
  await revealFilter(page,control);
  const selection=control.locator('xpath=ancestor::*[contains(concat(" ",normalize-space(@class)," ")," ant-select ")][1]');
  const values=await selection.evaluate(el=>{
    const items=[...el.querySelectorAll('.ant-select-selection-item')].map(item=>item.getAttribute('title'));
    // Ant 6 single-select puts the saved value on the content element.
    const single=el.querySelector('.ant-select-content-has-value')?.getAttribute('title');
    return items.length?items:single?[single]:[];
  });
  if(values.length===1&&values[0]===name)return;
  const remove=selection.locator('.ant-select-selection-item-remove');
  while(await remove.count())await remove.first().click();
  if(await control.getAttribute('aria-expanded') !== 'true')await selectTrigger(control).click();
  await control.fill(name);
  const listId=await control.getAttribute('aria-controls');
  const menu=page.locator(`[id="${listId}"]`).locator('xpath=ancestor::*[contains(concat(" ",normalize-space(@class)," ")," ant-select-dropdown ")][1]');
  const option=menu.getByTitle(name,{exact:true});
  // Use a pointer at the visible option, without Playwright's automatic
  // scroll that dismisses Superset's overflow popover. Hit-testing still
  // requires an unobstructed option; this is not a forced DOM click.
  let previousOptionBounds;
  await expect.poll(async()=>{
    const bounds=await option.evaluate(el=>{
      const r=el.getBoundingClientRect();
      if(r.width<20||r.height<20||!el.contains(document.elementFromPoint(r.x+r.width/2,r.y+r.height/2)))return null;
      return [r.x,r.y,r.width,r.height].map(value=>Math.round(value*10)/10).join(',');
    });
    const stable=bounds!==null&&bounds===previousOptionBounds;
    previousOptionBounds=bounds;
    return stable;
  },{message:'Filter option must be stationary, visible and unobstructed',intervals:[100,100]}).toBe(true);
  const changed=!/ant-select-item-option-selected/.test(await option.getAttribute('class'));
  if(changed){
    const r=await option.boundingBox();
    await page.mouse.click(r.x+r.width/2,r.y+r.height/2);
  }
  // Leave search mode before inspecting the saved value. A horizontal
  // overflow panel can close after a selection; reveal it again using the
  // normal More filters control. This never changes or reapplies a value.
  if(await page.getByRole('button',{name:/More filters/}).count()){
    await revealFilter(page,control);
  }else{
    await control.locator('xpath=ancestor::*[.//h4][1]').locator('h4').click();
  }
  // The chosen menu row can be virtualized away. Verify the saved chip(s)
  // exactly, so an extra selection or the wrong hospital still fails.
  await expect.poll(()=>selection.evaluate(el=>{
    const items=[...el.querySelectorAll('.ant-select-selection-item')].map(item=>item.getAttribute('title'));
    const single=el.querySelector('.ant-select-content-has-value')?.getAttribute('title');
    return items.length?items:single?[single]:[];
  }),{message:'The filter must retain exactly the requested selection'}).toEqual([name]);
  if(!applySelection)return;
  const apply=dashboardApply(page);
  // A changed selection must reach pending filter state before Apply.
  // A one-time isEnabled check can skip the update on slower machines.
  if(changed)await expect(apply).toBeEnabled();
  else if(!await apply.isEnabled())return;
  await apply.click();
  await page.waitForLoadState('networkidle');
}
export async function allTrends(watch){
  const rows={};
  for(const trend of watch.trends){
    await trend.holder.scrollIntoViewIfNeeded();
    await trend.holder.page().waitForLoadState('networkidle');
    await watch.settle();
    try {
      await expect.poll(()=>watch.replies.get(trend.id)?.result).toBeTruthy();
    } catch(error) {
      console.error('Chart request diagnostics',JSON.stringify({chart:trend.name,id:trend.id,events:watch.network.filter(event=>event.id===trend.id)}));
      throw error;
    }
    await watch.settle();
    await waitForChartPaint(trend.plot);
    rows[trend.name]=watch.replies.get(trend.id).result.data;
  }
  return rows;
}

export async function location(page,name){
  return selectValue(page,name,'NATIVE_FILTER-BPP7wo77GPPbinIYZiwM8',{apply:false});
}
