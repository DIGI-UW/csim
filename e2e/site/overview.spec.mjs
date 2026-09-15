import {test,expect} from '@playwright/test';

test('Copy icons copy the password for the matching dashboard',async({page,context},info)=>{
  await context.grantPermissions(['clipboard-read','clipboard-write']);
  for(const [name,file] of [['main','access.json'],['preview','preview-access.json'],['standard','standard-access.json']]){
    await page.route(`**/${file}`,route=>route.fulfill({json:{username:`${name}-viewer`,password:`${name}-copy-test`}}));
  }
  await page.goto('/#demo-access');
  for(const name of ['main','preview','standard']){
    const button=page.getByRole('button',{name:`Copy ${name} password`,exact:true});
    await expect(button).toBeEnabled();await expect(button.locator('svg')).toBeVisible();
    await button.click();
    expect(await page.evaluate(()=>navigator.clipboard.readText())).toBe(`${name}-copy-test`);
    await expect(button.locator('..').getByRole('status')).toHaveText('Copied');
  }
  for(const width of [1280,390]){
    await page.setViewportSize({width,height:900});
    await page.locator('#demo-access').scrollIntoViewIfNeeded();
    await page.locator('#demo-access').screenshot({path:info.outputPath(`login-${width}.png`)});
  }
});

test('Readers can open the September dashboard and find each matching login',async({page})=>{
  await page.goto('/');
  await expect(page.getByRole('heading',{level:1})).toContainText('Dashboard issues and solutions');
  const primary=page.getByRole('link',{name:'Open recommended dashboard →',exact:true});
  await expect(primary).toBeInViewport();
  const recommended=new URL(await primary.getAttribute('href'));
  expect(recommended.hostname).toBe('standard.csim.uwdigi.org');
  expect(recommended.searchParams.get('next')).toBe('/superset/dashboard/csim-individual-standard-month-selectors/');
  await page.locator('#start-here').getByRole('link',{name:'Login details',exact:true}).click();
  await expect(page.locator('#standard-instance a.instance-open')).toBeInViewport();
  for(const [id,host] of [['demo-instance','dashboard.csim.uwdigi.org'],['snapshot-instance','preview.csim.uwdigi.org']]){
    const box=page.locator('#'+id);
    await expect(box.locator('a.instance-open')).toHaveAttribute('href',new RegExp('https://'+host+'/login/'));
    await expect(box).toContainText('Customized');
    await expect(box).toContainText('Username:');
    await expect(box).toContainText('Password:');
  }
  const destination=new URL(await page.locator('#demo-instance a.instance-open').getAttribute('href'));
  expect(destination.searchParams.get('next')).toBe('/superset/dashboard/csim-individual-reconciled-months/');
});

test('Version comparison does not pass custom installations off as standard Superset',async({page})=>{
  await page.goto('/#versions');
  const rows=page.locator('#versions tbody tr');
  await expect(rows).toHaveCount(3);
  await expect(rows.nth(0)).toContainText('Standard release');
  await expect(rows.nth(1)).toContainText('Superset development');
  await expect(rows.nth(0).getByRole('link')).toHaveAttribute('href','comparison.html#official');
  await expect(rows.nth(1)).toContainText('Separate demo not available yet.');
  await expect(rows.nth(2)).toContainText('CSiM custom');
  await expect(rows.nth(2).locator('a')).toHaveCount(2);
  await expect(page.locator('#solution-labels')).toContainText('retain every monthly label');
  await expect(page.locator('#solution-filters .status')).toHaveText('Known gap in official Superset 6.1.0');
  await expect(page.locator('#solution-filters')).toContainText('Moving the controls left does not repair that defect');
  await expect(page.locator('#solution-calculation .status')).toContainText('No Superset code change needed');
  await expect(page.locator('#solution-calculation')).toContainText('It opens in Custom with Specific Date/Time for both endpoints');
  await expect(page.locator('#solution-calculation')).toContainText('the end is excluded');
  await expect(page.locator('#solution-time-menu')).toContainText('needs no CSiM code');
  await page.screenshot({path:test.info().outputPath('version-comparison.png')});
});

test('Issue navigation and older section links have valid destinations',async({page})=>{
  await page.goto('/');
  const missing=await page.locator('a[href^="#"]').evaluateAll(links=>links.filter(link=>!document.getElementById(link.hash.slice(1))).map(link=>link.hash));
  expect(missing).toEqual([]);
  const duplicates=await page.locator('[id]').evaluateAll(nodes=>nodes.map(n=>n.id).filter((id,i,all)=>all.indexOf(id)!==i));
  expect(duplicates).toEqual([]);
  await expect(page.locator('.issue')).toHaveCount(9);
  for(const issue of await page.locator('.issue').all()){
    await expect(issue.locator('.example')).toBeVisible();
    await expect(issue.locator('.issue-links a').first()).toHaveAttribute('href',/^(evidence\/|#|https:\/\/)/);
    await expect(issue.locator('details').first()).not.toHaveAttribute('open','');
  }
  await page.locator('.issue-index').getByRole('link',{name:'1. Labels for months, quarters and years'}).click();
  await expect(page.locator('#solution-labels h2')).toBeInViewport();
  await page.locator('#solution-labels summary').click();
  await expect(page.locator('#solution-labels')).toContainText('The official comparison also retains every month');
  await page.screenshot({path:test.info().outputPath('date-label-guidance.png')});
  await page.goto('/#month-controls');
  await expect(page.locator('#month-controls')).toBeInViewport();
  await expect(page.locator('#month-controls')).toContainText('Through month');
  await expect(page.locator('#dashboard-inventory tbody tr')).toHaveCount(4);
  await page.locator('#supporting-examples summary').click();
  await expect(page.locator('#supporting-examples tbody tr')).toHaveCount(5);
});

test('Page and mobile contents remain usable on a phone',async({page})=>{
  await page.setViewportSize({width:390,height:844});await page.goto('/');
  expect(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth)).toBe(true);
  await expect(page.getByRole('link',{name:'Open recommended dashboard →',exact:true})).toBeInViewport();
  await page.screenshot({path:test.info().outputPath('overview-phone.png')});
  const menu=page.locator('.mobile-nav');await menu.locator('summary').click();
  await menu.getByRole('link',{name:'Date labels',exact:true}).click();
  await expect(menu).not.toHaveAttribute('open','');
  await expect(page.locator('#solution-labels h2')).toBeInViewport();
  expect(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth)).toBe(true);
  await page.screenshot({path:test.info().outputPath('date-labels-phone.png')});
  await page.goto('/#demo-access');
  await expect(page.locator('#demo-instance a.instance-open')).toBeVisible();
  expect(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth)).toBe(true);
});
