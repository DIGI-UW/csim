import {test,expect} from '@playwright/test';

const names=['CSiM Hospitals and States','UTI Individual Historical','UTI Individual Current'];

test('Client upload sources have their production names and physical dataset registrations',async({page},info)=>{
  test.skip(process.env.CSIM_NATIVE_DATES!=='1','Official client-facing dataset list');
  for(const name of names){
    const query={filters:[{col:'table_name',opr:'eq',value:name}]};
    const response=await page.request.get('/api/v1/dataset/?q='+encodeURIComponent(JSON.stringify(query)));
    expect(response.ok()).toBe(true);
    const items=(await response.json()).result;
    expect(items).toHaveLength(1);
    const detailResponse=await page.request.get(`/api/v1/dataset/${items[0].id}`);
    expect(detailResponse.ok()).toBe(true);
    const detail=(await detailResponse.json()).result;
    expect(detail.sql||'').toBe('');
    expect(detail.schema).toBe('v1');
    const columns=detail.columns.map(c=>c.column_name);
    if(name.startsWith('UTI Individual'))expect(columns).toContain('record_id');
    if(name==='UTI Individual Current')expect(columns).toContain('redcap_repeat_instance');
  }
  await page.goto('/tablemodelview/list/?pageIndex=0&sortColumn=changed_on_delta_humanized&sortOrder=desc');
  for(const name of names){
    const row=page.getByRole('row').filter({has:page.getByRole('link',{name,exact:true})});
    await expect(row).toHaveCount(1);
    await expect(row.getByText('Physical',{exact:true})).toBeVisible();
  }
  // The list can render its rows underneath the initial loading fade.
  // Wait for readable, interactive rows before keeping screenshot evidence.
  await expect(page.locator('.ant-spin-spinning,.ant-spin-blur')).toHaveCount(0);
  const sourceLink=page.getByRole('link',{name:'UTI Individual Current',exact:true});
  await sourceLink.click({trial:true});
  await expect.poll(()=>sourceLink.evaluate(element=>{
    let opacity=1;
    for(let node=element;node;node=node.parentElement)opacity*=Number(getComputedStyle(node).opacity);
    return opacity;
  })).toBeGreaterThan(.95);
  await page.screenshot({path:info.outputPath('client-upload-sources.png')});
});
