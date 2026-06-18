const excelReporter = require('../utils/excel_reporter');

async function main() {
  console.log('📊 Compiling Appium Android Test Report...');
  try {
    await excelReporter.generateReport();
    console.log('✅ Appium Android Test Report compilation successful.');
  } catch (err) {
    console.error('❌ Appium Report compilation failed:', err.message);
    process.exit(1);
  }
}

main();
