const { chromium } = require('playwright');
const fs = require('node:fs');
const { spawn } = require('node:child_process');

(async () => {
  const server = spawn('python3', ['-m', 'http.server', '8765', '--directory', 'staging'], {
    stdio: 'ignore', detached: true,
  });
  const browser = await chromium.launch({channel: 'chrome', headless: true,
    args: ['--no-sandbox', '--disable-dev-shm-usage']});
  const reports = [];
  try {
    fs.mkdirSync('qa-screenshots', { recursive: true });
    for (const [device, width, height] of [['mobile', 390, 844], ['desktop', 1440, 900]]) {
      const page = await browser.newPage({viewport: {width, height}, deviceScaleFactor: 1});
      const errors = [];
      page.on('pageerror', err => errors.push(err.message));
      await page.goto('http://127.0.0.1:8765/fitnessflex-app/', {waitUntil: 'domcontentloaded', timeout: 30000});
      await page.locator('flutter-view').first().waitFor({state:'attached',timeout: 30000});
      await page.waitForTimeout(5500); // Splash is two seconds, then onboarding.
      const detail = await page.evaluate(() => ({
        flutterViews: document.querySelectorAll('flutter-view').length,
        title: document.title,
        width: document.documentElement.scrollWidth,
        windowWidth: innerWidth,
      }));
      const screenshotPath = 'qa-screenshots/' + device + '.png';
      await page.screenshot({path: screenshotPath, fullPage: true});
      // Exercise actual canvas buttons in the compiled app, not just widget tests.
      // Three transitions: page 1 -> page 2 -> page 3 -> Login.
      const buttonX = width > 900 ? width / 2 + 458 : width - 62;
      for (let step = 0; step < 3; step++) {
        await page.mouse.click(buttonX, height - 38);
        await page.waitForTimeout(1150);
      }
      const loginPath = 'qa-screenshots/login-' + device + '.png';
      await page.screenshot({path: loginPath, fullPage: true});
      // The password reset screen is a real Flutter canvas route.
      // Check that the link opens without a JavaScript runtime exception.
      const forgotX = device === 'mobile' ? 275 : 875;
      await page.mouse.click(forgotX, 382);
      await page.waitForTimeout(900);
      const resetPath = 'qa-screenshots/reset-' + device + '.png';
      await page.screenshot({path: resetPath, fullPage: true});
      const browserInputs = await page.evaluate(() => ({
        inputs: document.querySelectorAll('input').length,
        semantics: !!document.querySelector('flt-semantics-host'),
      }));
      let interceptedResets = null;
      if (device === 'mobile') {
        // Exercise the actual compiled FlutterFire web bridge against a stubbed
        // Identity Toolkit response, never send an email from CI.
        interceptedResets = 0;
        await page.route('**/identitytoolkit.googleapis.com/**', async route => {
          if (route.request().url.includes('sendOobCode')) {
            interceptedResets++;
            await route.fulfill({
              status: 400, contentType: 'application/json',
              body: JSON.stringify({ error: { code: 400,
                message: 'TOO_MANY_ATTEMPTS_TRY_LATER' } }),
            });
          } else {
            await route.continue();
          }
        });
        await page.mouse.click(180, 485); // password-reset email input
        await page.keyboard.type('qa-test@example.com', {delay: 15});
        await page.waitForTimeout(300);
        await page.mouse.click(185, 565); // Send Reset Link
        await page.waitForTimeout(2400);
        await page.screenshot({path: 'qa-screenshots/reset-response-mobile.png', fullPage: true});
        if (interceptedResets !== 1) {
          throw new Error('Mocked Firebase password reset expected exactly one request, observed ' + interceptedResets);
        }
      }
      reports.push({device, ...detail, screenshot: screenshotPath,
        loginScreenshot: loginPath, resetScreenshot: resetPath,
        interceptedResets, browserInputs, pageErrors: errors});
      console.log(JSON.stringify(reports[reports.length-1]));
      if (errors.length) throw new Error('Runtime JavaScript exceptions on ' + device + ': ' + errors.join(' | '));
      if (detail.flutterViews < 1) throw new Error('Flutter view missing on ' + device);
      if (detail.width > detail.windowWidth + 5) throw new Error('Unexpected horizontal overflow on ' + device);
      await page.close();
    }
    fs.writeFileSync('qa-screenshots/results.json', JSON.stringify(reports, null, 2));
  } finally {
    await browser.close();
    process.kill(-server.pid, 'SIGTERM');
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
