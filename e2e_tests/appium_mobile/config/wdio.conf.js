exports.config = {
  runner: 'local',
  port: 4723, // Default Appium port
  path: '/',
  specs: [
    '../test_cases/**/*.test.js'
  ],
  exclude: [],
  maxInstances: 1,
  capabilities: [{
    platformName: 'Android',
    'appium:deviceName': 'Android Emulator',
    'appium:automationName': 'UiAutomator2',
    'appium:app': '../app-release.apk', // Path to the compiled StriveCampus APK
    'appium:appPackage': 'com.example.strive_campus',
    'appium:appActivity': 'com.example.strive_campus.MainActivity',
    'appium:noReset': false,
    'appium:fullReset': false,
    'appium:newCommandTimeout': 240
  }],
  logLevel: 'info',
  bail: 0,
  waitforTimeout: 10000,
  connectionRetryTimeout: 120000,
  connectionRetryCount: 3,
  services: ['appium'],
  framework: 'mocha',
  reporters: ['spec'],
  mochaOpts: {
    ui: 'bdd',
    timeout: 90000
  }
};
