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
    // Record result in Excel report
    await excelReporter.recordTest({ title: test.title, passed, duration, error });
  },
  onComplete: async function (exitCode, config, capabilities, results) {
    // Generate the Excel report after all tests finish
    await excelReporter.generateReport();
  }
};
