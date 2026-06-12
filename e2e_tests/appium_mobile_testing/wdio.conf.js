const excelReporter = require('./utils/excel_reporter');

exports.config = {
  runner: 'local',
  autoCompileOpts: {
    autoCompile: false
  },
  port: 4723,
  path: '/',
  specs: ['./test/specs/**/*.js'],
  maxInstances: 1,
  capabilities: [{
    platformName: 'Android',
    "appium:deviceName": "Android Device",
    "appium:automationName": "UiAutomator2",
    "appium:app": "./apk/app-debug.apk",
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
    // ensure report directory exists
    const fs = require('fs');
    if (!fs.existsSync('./reports')) fs.mkdirSync('./reports');
  },
  afterTest: async function (test, context, { error, result, duration, passed, retries }) {
    // On failure capture screenshot
    if (!passed) {
      const path = `./reports/screenshots/${test.title.replace(/\s+/g, '_')}.png`;
      await browser.saveScreenshot(path);
    }
    // Record result in Excel report
    await excelReporter.recordTest({ title: test.title, passed, duration, error });
  },
  onComplete: async function (exitCode, config, capabilities, results) {
    // Generate the Excel report after all tests finish
    await excelReporter.generateReport();
  }
};
