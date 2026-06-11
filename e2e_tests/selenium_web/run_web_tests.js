const { Builder } = require('selenium-webdriver');
const chrome = require('selenium-webdriver/chrome');
const fs = require('fs');
const path = require('path');
const runOnboardingTests = require('./test_cases/onboarding.test.js');
const { runLoginTests, runLogoutTests } = require('./test_cases/auth.test.js');
const runHRInterviewTests = require('./test_cases/hr_interview.test.js');
const { generateExcelReport } = require('./utils/excel_reporter');

async function main() {
  console.log('======================================================');
  console.log('🚀 Starting StriveCampus Selenium E2E Web Tests...');
  console.log('======================================================\n');

  // Configure ChromeDriver arguments
  const options = new chrome.Options();
  options.addArguments('--no-sandbox');
  options.addArguments('--disable-dev-shm-usage');
  options.addArguments('--disable-gpu');
  
  // Create screenshots directory if it doesn't exist
  const screenshotsDir = path.join(__dirname, 'screenshots');
  if (!fs.existsSync(screenshotsDir)) {
    fs.mkdirSync(screenshotsDir);
  }

  const driver = await new Builder()
    .forBrowser('chrome')
    .setChromeOptions(options)
    .build();

  const results = [];
  const startTime = Date.now();

  // Step runner and result logger
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
      
      // Capture screenshot on error
      try {
        const screenshot = await driver.takeScreenshot();
        const screenshotPath = path.join(screenshotsDir, `${testCase.replace(/\s+/g, '_')}_${stepName.replace(/\s+/g, '_')}_failed.png`);
        fs.writeFileSync(screenshotPath, screenshot, 'base64');
        console.log(`[SCREENSHOT] Saved failure state to: ${screenshotPath}\n`);
      } catch (screenshotErr) {
        console.error('[SCREENSHOT ERROR] Could not save screenshot: ', screenshotErr.message);
      }
    }
  }

  try {
    // 1. Run Onboarding flow (ends on Login page)
    await runOnboardingTests(driver, logStep);

    // 2. Run Login flow (ends on Home dashboard)
    await runLoginTests(driver, logStep);

    // 3. Run HR Interview flow (ends on Home dashboard)
    await runHRInterviewTests(driver, logStep);

    // 4. Run Logout flow (ends on Login page)
    await runLogoutTests(driver, logStep);

  } catch (error) {
    console.error('💥 Fatal Test Runner Exception: ', error);
  } finally {
    const totalDuration = Date.now() - startTime;
    console.log('🏁 E2E Web Tests complete! Quitting browser and generating report...');
    await driver.quit();

    try {
      await generateExcelReport(results, totalDuration);
    } catch (excelErr) {
      console.error('❌ Failed to compile Excel report: ', excelErr.message);
    }
  }
}

main();
