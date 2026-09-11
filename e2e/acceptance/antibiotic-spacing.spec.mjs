import {test,expect} from '@playwright/test';
import {profile,dataProfile,reconciled} from '../acceptance.config.mjs';
import {openDashboard,timePeriod,timeUnit,hospital,waitForChartPaint} from './dashboard.mjs';

const title='Number of antibiotic prescriptions';
for(const width of [1024,1280,1600])test(`Antibiotic axis titles stay below the legend at ${width}px`,async({page},info)=>{
  test.skip(!reconciled&&!['standard','development'].includes(profile));
  await page.setViewportSize({width,height:1100});
  await page.addInitScript(()=>{
    const proto=CanvasRenderingContext2D.prototype,fill=proto.fillText,clear=proto.clearRect;
    proto.clearRect=function(...args){if(args[0]===0&&args[1]===0)this.canvas.__spacingText=[];return clear.apply(this,args);};
    proto.fillText=function(text,x,y,...rest){
      const metrics=this.measureText(text),matrix=this.getTransform();
      const corners=[x-metrics.actualBoundingBoxLeft,x+metrics.actualBoundingBoxRight]
        .flatMap(px=>[y-metrics.actualBoundingBoxAscent,y+metrics.actualBoundingBoxDescent]
          .map(py=>new DOMPoint(px,py).matrixTransform(matrix)));
      (this.canvas.__spacingText ||= []).push({text:String(text),
        left:Math.min(...corners.map(p=>p.x)),right:Math.max(...corners.map(p=>p.x)),
        top:Math.min(...corners.map(p=>p.y)),bottom:Math.max(...corners.map(p=>p.y)),
        horizontal:Math.abs(matrix.b)<0.01});
      return fill.call(this,text,x,y,...rest);
    };
  });
  const watch=await openDashboard(page,profile);
  await timePeriod(page,'2025-09-01','2026-10-01');
  await hospital(page,dataProfile.openingHospital,'NATIVE_FILTER-PsH68K-xwsp1NWi3i2HxI');
  await timeUnit(page,'Month');
  const report=[];
  const charts=watch.dateAxes.filter(item=>item.name.endsWith('(abx)'));
  for(const chart of charts){
      await chart.holder.scrollIntoViewIfNeeded();
      await page.waitForLoadState('networkidle');await watch.settle();
      await expect.poll(()=>watch.replies.get(chart.id)?.result?.data.length).toBeGreaterThan(0);
      await expect.poll(async()=>chart.plot.locator('canvas').evaluateAll(items=>items.every(canvas=>{
        const plot=canvas.closest('[data-test=dashboard-component-chart-holder]');
        const bounds=canvas.getBoundingClientRect(),available=plot.getBoundingClientRect();
        return bounds.left>=available.left-1&&bounds.right<=available.right+1;
      })),{message:'Resized canvas must fit inside the chart'}).toBe(true);
      await waitForChartPaint(chart.plot);
      const texts=await chart.plot.locator('canvas').evaluateAll(canvases=>canvases.flatMap(canvas=>{
        const scale=canvas.clientWidth/canvas.width;
        const offset=canvas.getBoundingClientRect().top-canvas.closest('[data-test=dashboard-component-chart-holder]').getBoundingClientRect().top;
        return [...new Map((canvas.__spacingText||[]).map(item=>[item.text,item])).values()]
          .map(item=>({...item,canvasTop:item.top*scale,top:item.top*scale+offset,bottom:item.bottom*scale+offset}));
      }));
      const axis=texts.find(item=>item.text===title);
      // Development renders its legend in the DOM; 6.1 renders it on canvas.
      // Measure both in holder coordinates so the same spacing rule applies.
      const domLegend=chart.holder.locator('[data-test="timeseries-custom-legend"] button');
      const legend=await domLegend.count()?await domLegend.evaluateAll(items=>items.map(el=>{
        const r=el.getBoundingClientRect(),holder=el.closest('[data-test=dashboard-component-chart-holder]').getBoundingClientRect();
        return {text:el.textContent,top:r.top-holder.top,bottom:r.bottom-holder.top};
      })):texts.filter(item=>item.horizontal&&item.canvasTop<30&&!/^\d/.test(item.text));
      expect(axis,`${chart.name}: title rendered`).toBeTruthy();
      expect(legend.length,`${chart.name}: legend rendered`).toBeGreaterThan(0);
      const gap=axis.top-Math.max(...legend.map(item=>item.bottom));
      expect.soft(gap,`${width}px ${chart.name}: title-to-legend gap`).toBeGreaterThanOrEqual(8);
      const screenshot=info.outputPath(`${width}-${chart.id}.png`);
      await chart.holder.screenshot({path:screenshot});
      await info.attach(`${width}px ${chart.name}`,{path:screenshot,contentType:'image/png'});
      report.push({width,chartWidth:(await chart.holder.boundingBox()).width,chart:chart.name,axis,legend,gap,screenshot});
  }
  expect(watch.failures).toEqual([]);
  await info.attach('title-spacing',{body:Buffer.from(JSON.stringify(report)),contentType:'application/json'});
});
