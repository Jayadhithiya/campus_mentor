const { Builder, By, until } = require('selenium-webdriver');
const chrome = require('selenium-webdriver/chrome');
const fs = require('fs');
const path = require('path');
const runUIUXTests = require('./test_cases/ui_ux.test.js');
const runFunctionalTests = require('./test_cases/functional.test.js');
const runUnitTests = require('./test_cases/unit.test.js');
const runValidationTests = require('./test_cases/validation.test.js');
const { generateExcelReport } = require('./utils/excel_reporter');

async function main() {
  console.log('======================================================');
  console.log('🚀 Starting StriveCampus Selenium E2E Web Tests...');
  console.log('======================================================\n');

  // ── Configure ChromeDriver ──────────────────────────────────────────────────
  const options = new chrome.Options();
  options.addArguments('--no-sandbox');
  options.addArguments('--disable-dev-shm-usage');
  options.addArguments('--disable-gpu');
  options.addArguments('--window-size=1366,768');
  options.addArguments('--headless=new');              // Use new headless mode (Chrome 112+)
  options.addArguments('--enable-accessibility');       // Enable a11y tree for Flutter semantics
  options.addArguments('--force-renderer-accessibility');
  options.addArguments('--disable-web-security');
  options.addArguments('--allow-running-insecure-content');
  options.addArguments('--disable-extensions');
  options.addArguments('--remote-debugging-port=0');   // Prevent port conflicts

  // ── Create screenshots directory ───────────────────────────────────────────
  const screenshotsDir = path.join(__dirname, 'screenshots');
  if (!fs.existsSync(screenshotsDir)) {
    fs.mkdirSync(screenshotsDir, { recursive: true });
  }

  // ── Build driver ───────────────────────────────────────────────────────────
  let driver;
  try {
    driver = await new Builder()
      .forBrowser('chrome')
      .setChromeOptions(options)
      .build();
  } catch (buildErr) {
    console.error('❌ ChromeDriver build failed: ', buildErr.message);
    process.exit(1);
  }

  const results = [];
  const startTime = Date.now();

  // ── Step runner / logger ───────────────────────────────────────────────────
  async function logStep(testCase, stepName, fn) {
    const stepStart = Date.now();
    console.log(`[RUNNING] ${testCase} > ${stepName}`);
    try {
      await fn();
      const duration = Date.now() - stepStart;
      results.push({ testCase, stepName, status: 'PASS', duration });
      console.log(`[PASS]    ${testCase} > ${stepName} (${(duration / 1000).toFixed(2)}s)\n`);
    } catch (err) {
      const duration = Date.now() - stepStart;
      results.push({ testCase, stepName, status: 'FAIL', duration, error: err.message });
      console.error(`[FAIL]    ${testCase} > ${stepName} (${(duration / 1000).toFixed(2)}s)`);
      console.error(`          Error: ${err.message}\n`);

      // Capture screenshot — use safe filename (no slashes or colons in path)
      try {
        const screenshot = await driver.takeScreenshot();
        const safeName = `${testCase}_${stepName}`
          .replace(/[^a-zA-Z0-9_\- ]/g, '_')
          .replace(/\s+/g, '_')
          .substring(0, 80);
        const screenshotPath = path.join(screenshotsDir, `${safeName}_FAIL.png`);
        fs.writeFileSync(screenshotPath, screenshot, 'base64');
        console.log(`[SCREENSHOT] Saved: ${screenshotPath}\n`);
      } catch (screenshotErr) {
        console.error('[SCREENSHOT ERROR] Could not save screenshot: ', screenshotErr.message);
      }
    }
  }

  // ── Pre-test: Boot app and verify ─────────────────────────────────────────
  try {
    console.log('[PRE-TEST] Navigating to http://127.0.0.1:8080...');
    await driver.get('http://127.0.0.1:8080');

    // Wait for page load
    try {
      await driver.wait(until.elementLocated(By.css('flt-glass-pane')), 25000);
      console.log('[PRE-TEST] Flutter glass-pane detected.');
    } catch {
      // CanvasKit renderer — wait for body
      await driver.wait(until.elementLocated(By.css('body')), 15000);
      console.log('[PRE-TEST] Page body loaded (CanvasKit mode).');
    }

    // Wait for Flutter to fully render
    await driver.sleep(4000);

    // Force-enable Flutter Web accessibility semantics
    await driver.executeScript(() => {
      const host = document.querySelector('flt-glass-pane');
      if (!host || !host.shadowRoot) return;
      const shadow = host.shadowRoot;

      // Trigger Tab key to enable accessibility mode in Flutter Web
      document.dispatchEvent(new KeyboardEvent('keydown', {
        key: 'Tab', keyCode: 9, bubbles: true, cancelable: true
      }));

      // Click accessibility placeholder if present
      const placeholder = shadow.querySelector('flt-semantics-placeholder');
      if (placeholder) {
        const btn = placeholder.querySelector('button');
        if (btn) btn.click();
      }
    });
    await driver.sleep(1500);

    console.log('[PRE-TEST] App ready. Starting test execution...\n');

    // ── 1. UI/UX Verification Suite (30 tests) ───────────────────────────────
    await runUIUXTests(driver, logStep);

    // ── 2. Functional Workflows Suite (30 tests) ─────────────────────────────
    await runFunctionalTests(driver, logStep);

    // ── 3. Client-side Unit Tests (25 tests) ─────────────────────────────────
    await runUnitTests(driver, logStep);

    // ── 4. Input & Schema Validation Tests (20 tests) ────────────────────────
    await runValidationTests(driver, logStep);

  } catch (fatalError) {
    console.error('💥 Fatal Test Runner Exception: ', fatalError.message);
  } finally {
    const totalDuration = Date.now() - startTime;

    // Print live summary
    const totalTests = results.length;
    const passed = results.filter(r => r.status === 'PASS').length;
    const failed = results.filter(r => r.status === 'FAIL').length;
    const passRate = totalTests > 0 ? ((passed / totalTests) * 100).toFixed(1) : '0.0';

    console.log('\n======================================================');
    console.log('📋 TEST SUMMARY');
    console.log('======================================================');
    console.log(`   Total Tests : ${totalTests}`);
    console.log(`   ✅ Passed   : ${passed}`);
    console.log(`   ❌ Failed   : ${failed}`);
    console.log(`   📈 Pass Rate: ${passRate}%`);
    console.log(`   ⏱  Duration : ${(totalDuration / 1000).toFixed(1)}s`);
    const deployable = parseFloat(passRate) >= 98.0;
    console.log(`   🚀 Status   : ${deployable ? 'DEPLOYABLE ✅' : 'NOT DEPLOYABLE ❌'}`);
    console.log('======================================================\n');

    console.log('🏁 E2E Web Tests complete! Quitting browser and generating report...');
    try { await driver.quit(); } catch (_) {}

    // Generate Excel report
    try {
      await generateExcelReport(results, totalDuration);
    } catch (excelErr) {
      console.error('❌ Failed to compile Excel report: ', excelErr.message);
    }

    // Exit with non-zero code if not deployable — this fails the CI pipeline
    process.exit(deployable ? 0 : 1);
  }
}

main();
