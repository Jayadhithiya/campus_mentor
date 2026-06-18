const { execSync, spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

// Setup Android SDK Environment Variables
const sdkPath = 'C:\\Users\\Raman\\AppData\\Local\\Android\\Sdk';
process.env.ANDROID_HOME = sdkPath;
process.env.ANDROID_SDK_ROOT = sdkPath;
process.env.PATH = `${process.env.PATH};${sdkPath}\\platform-tools;${sdkPath}\\tools;${sdkPath}\\tools\\bin`;

// Clear NODE_OPTIONS to avoid loader conflicts in spawned workers
delete process.env.NODE_OPTIONS;

function log(msg) {
  console.log(`[run_android_tests] ${msg}`);
}

// 1. Verify device connected via adb
function checkDevice() {
  try {
    const result = execSync('adb devices', { encoding: 'utf8' });
    const lines = result.trim().split('\n');
    const devices = lines.slice(1).filter(l => l.trim() !== '' && l.includes('device'));
    if (devices.length === 0) {
      log('No Android device found. Please connect a device with USB debugging enabled.');
      process.exit(1);
    }
    log(`Device(s) found: ${devices.map(d => d.split('\t')[0]).join(', ')}`);
  } catch (e) {
    log('adb not found or failed to execute. Ensure Android SDK platform-tools are in PATH.');
    process.exit(1);
  }
}

// 2. Ensure APK exists
function checkApk() {
  const apkPath = path.resolve(__dirname, '..', 'apk', 'app-debug.apk');
  if (!fs.existsSync(apkPath)) {
    log(`APK not found at ${apkPath}. Please copy the built app-debug.apk there.`);
    process.exit(1);
  }
  log('APK found.');
}

// 3. Start Appium server (as a child process)
function startAppium() {
  log('Starting Appium server...');
  const appiumProc = spawn('npx', ['appium', '--log-level', 'info'], { stdio: 'inherit', shell: true });
  // Wait a few seconds for it to be ready
  return new Promise((resolve, reject) => {
    setTimeout(() => resolve(appiumProc), 5000);
  });
}

// 4. Run wdio tests
function runWdio() {
  log('Running WebDriverIO tests...');
  try {
    execSync('npx wdio wdio.conf.js', { stdio: 'inherit' });
  } catch (e) {
    log('WDIO tests failed.');
    // continue to cleanup
  }
}

async function main() {
  checkDevice();
  checkApk();
  const appiumProc = await startAppium();
  runWdio();
  // Cleanup Appium
  if (appiumProc && !appiumProc.killed) {
    log('Stopping Appium server...');
    appiumProc.kill();
  }
  log('Test run complete.');
}

main();
