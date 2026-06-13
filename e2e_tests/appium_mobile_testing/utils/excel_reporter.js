const Excel = require('exceljs');
const path = require('path');

class ExcelReporter {
  constructor() {
    this.workbook = new Excel.Workbook();
    this.sheet = null;
    this.results = [];
  }

  async init() {
    this.workbook = new Excel.Workbook();
    this.sheet = this.workbook.addWorksheet('Test Results');
    this.sheet.columns = [
      { header: 'Test ID', key: 'id', width: 10 },
      { header: 'Title', key: 'title', width: 40 },
      { header: 'Status', key: 'status', width: 10 },
      { header: 'Duration (ms)', key: 'duration', width: 15 },
      { header: 'Error', key: 'error', width: 40 }
    ];
  }

  async recordTest(testInfo) {
    if (!this.sheet) {
      await this.init();
    }
    const { title, passed, duration, error } = testInfo;
    const id = this.results.length + 1;
    this.results.push({ id, title, status: passed ? 'PASS' : 'FAIL', duration, error });
    this.sheet.addRow({ id, title, status: passed ? 'PASS' : 'FAIL', duration, error: error ? (error.message || String(error)) : '' });
  }

  async generateReport() {
    if (!this.sheet) {
      await this.init();
    }
    const fileName = `appium_android_test_report_final.xlsx`;
    const filePath = path.resolve(__dirname, '..', 'reports', fileName);
    await this.workbook.xlsx.writeFile(filePath);
    console.log('✅ Android test report generated:', filePath);
  }
}

module.exports = new ExcelReporter();
