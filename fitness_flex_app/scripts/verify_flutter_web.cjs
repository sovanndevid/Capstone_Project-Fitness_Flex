const { chromium } = require('playwright');
const fs = require('node:fs');
const { spawn } = require('node:child_process');

// Test the compiled Flutter application from a temporary local HTTP server.
// No Firebase test account and no public deployment are required.
(async () => {
  const server = spawn('python3', ['-m', 'http.server', '8765', '--directory', 'staging'], {
    stdio: 'ignore', detached: true,
  });
  const browser = await chromium.launch({channel: 'chrome', headless: true,
    args: ['--no-sandbox', '--disable-dev-shm-usage']});
  const reports = [];
  try {
    fs.mkdirSync('qa-screenshots', { recursive: true });
    for (const [device,width,height] of [['mobile',390,844],['desktop',1440,900]]) {
      const page = await browser.newPage({viewport: {width,height},deviceScaleFactor: 1});
      const errors = [];
      page.on('pageerror',error=>errors.push(error.message));
      await page.goto('http://127.0.0.1:8765/fitnessflex-app/',{
        waitUntil: 'domcontentloaded',timeout: 30000,
      });
      await page.locator('flutter-view').first().waitFor({timeout: 30000});
      await page.waitForTimeout(2800);
      const started = await page.evaluate(()=>({
        width: document.documentElement.scrollWidth, viewport: innerWidth,
        flutterViews: document.querySelectorAll('flutter-view').length,
        title: document.title,
      }));
      await page.screenshot({path: 'qa-screenshots/login-'+device+'.png',fullPage:true});
      if(started.flutterViews!==1 || started.width>started.viewport+5)
        throw new Error('Flutter login startup or overflow failed: '+JSON.stringify(started));

      // Never create real Firebase accounts from CI: intercept anonymous sign-up.
      let anonymousRequests = 0;
      await page.route('**/identitytoolkit.googleapis.com/**', async route => {
        if (route.request().url().includes('accounts:signUp')) {
          anonymousRequests++;
          await route.fulfill({
            status: 400, contentType: 'application/json',
            headers: {'access-control-allow-origin':'*'},
            body: JSON.stringify({error:{code:400,message:'OPERATION_NOT_ALLOWED'}}),
          });
        } else {
          await route.continue();
        }
      });
      // Click the real "Continue as Guest" button. The route is allowed to
      // show its error state instead of entering /home when Firebase denies it.
      await page.mouse.click(width/2, 540);
      await page.waitForTimeout(2000);
      const guestUrl = page.url();
      await page.screenshot({path: 'qa-screenshots/guest-'+device+'.png',fullPage:true});
      if (anonymousRequests !== 1 || !guestUrl.includes('/guest')) {
        throw new Error('Guest access error-handling failed: '+
          JSON.stringify({anonymousRequests,guestUrl}));
      }
      const viewport = await page.evaluate(()=>({
        width: document.documentElement.scrollWidth, viewport: innerWidth,
      }));
      if(viewport.width>viewport.viewport+5)
        throw new Error('Guest horizontal overflow: '+JSON.stringify(viewport));
      if(errors.length)throw new Error('Uncaught browser exceptions: '+errors.join(' | '));
      const report={device, guestUrl, anonymousRequests, started, viewport, javascriptErrors:errors};
      reports.push(report);
      console.log(JSON.stringify(report));
      await page.close();
    }
    fs.writeFileSync('qa-screenshots/results.json',JSON.stringify(reports,null,2));
  } finally {
    await browser.close();
    process.kill(-server.pid,'SIGTERM');
  }
})().catch(error=>{console.error(error);process.exitCode=1;});
