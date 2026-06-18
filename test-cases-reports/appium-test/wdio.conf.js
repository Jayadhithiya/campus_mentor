const path = require('path');
const excelReporter = require('./utils/excel_reporter');

exports.config = {
  runner: 'local',
  autoCompileOpts: {
    autoCompile: false
  },
  port: 4723,
  path: '/',
  specs: [path.join(__dirname, 'test/specs/**/*.js')],
  maxInstances: 1,
  capabilities: [{
    platformName: 'Android',
    "appium:deviceName": "Android Device",
    "appium:automationName": "UiAutomator2",
    "appium:app": path.join(__dirname, 'apk', 'app-debug.apk'),
    "appium:newCommandTimeout": 240,
    "appium:autoGrantPermissions": true
  }],
  logLevel: 'info',
  framework: 'mocha',
  mochaOpts: {
    ui: 'bdd',
    timeout: 60000
  },
  reporters: ['spec'],
  onPrepare: function (config, capabilities) {
    const fs = require('fs');
    const tempDir = path.join(__dirname, 'reports', 'temp_results');
    if (fs.existsSync(tempDir)) {
      try {
        const files = fs.readdirSync(tempDir);
        for (const file of files) {
          fs.unlinkSync(path.join(tempDir, file));
        }
        fs.rmdirSync(tempDir);
      } catch (e) {
        console.error('Failed to clean temp results in onPrepare:', e);
      }
    }
  },
  beforeSession: function (config, capabilities, specs) {
    // ensure report directories exist
    const fs = require('fs');
    const reportsDir = path.join(__dirname, 'reports');
    const screenshotsDir = path.join(__dirname, 'reports', 'screenshots');
    if (!fs.existsSync(reportsDir)) fs.mkdirSync(reportsDir, { recursive: true });
    if (!fs.existsSync(screenshotsDir)) fs.mkdirSync(screenshotsDir, { recursive: true });
  },
  afterTest: async function (test, context, { error, result, duration, passed, retries }) {
    // On failure capture screenshot
    if (!passed) {
      const screenshotPath = path.join(__dirname, 'reports', 'screenshots', `${test.title.replace(/\s+/g, '_')}.png`);
      await browser.saveScreenshot(screenshotPath);
    }
    // Try to extract test ID from test parent suite title, test title, or file name
    let testId = null;
    if (test.file) {
      const fileMatch = path.basename(test.file).match(/([A-Z]{2}\d{3})/);
      if (fileMatch) testId = fileMatch[1];
    }
    if (!testId && test.parent) {
      const suiteTitle = typeof test.parent === 'object' ? test.parent.title : String(test.parent);
      const suiteMatch = suiteTitle.match(/([A-Z]{2}\d{3})/);
      if (suiteMatch) testId = suiteMatch[1];
    }
    if (!testId && test.title) {
      const titleMatch = test.title.match(/([A-Z]{2}\d{3})/);
      if (titleMatch) testId = titleMatch[1];
    }
    // Record result in Excel report
    await excelReporter.recordTest({ testId, title: test.title, passed, duration, error });
  },
  onComplete: async function (exitCode, config, capabilities, results) {
    // Generate the Excel report after all tests finish
    await excelReporter.generateReport();
  }
};
