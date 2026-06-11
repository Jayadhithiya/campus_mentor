const { execSync } = require('child_process');
const path = require('path');

/**
 * Triggers the WebdriverIO test suite runner for Appium mobile automation.
 */
function runMobileTests() {
  console.log('======================================================');
  console.log('🚀 Starting Appium Mobile Tests using WebdriverIO...');
  console.log('======================================================\n');
  
  try {
    const configPath = path.join(__dirname, 'config', 'wdio.conf.js');
    
    // Execute wdio test runner directly
    execSync(`npx wdio run "${configPath}"`, { stdio: 'inherit' });
    
    console.log('\n🏁 Appium Mobile Tests completed successfully!');
  } catch (err) {
    console.error('\n❌ Appium Mobile Tests execution encountered a failure.');
    process.exit(1);
  }
}

runMobileTests();
