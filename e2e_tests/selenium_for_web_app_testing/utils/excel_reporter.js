const ExcelJS = require('exceljs');
const path = require('path');

/**
 * Generates a styled Excel sheet with Dashboard Summary and Detailed Log tables.
 */
async function generateExcelReport(results, durationMs) {
  const workbook = new ExcelJS.Workbook();
  workbook.creator = 'StriveCampus E2E Automator';
  workbook.created = new Date();

  // ==========================================
  // SHEET 1: SUMMARY DASHBOARD
  // ==========================================
  const dashboard = workbook.addWorksheet('Summary Dashboard');
  dashboard.views = [{ showGridLines: true }];

  // Merge title banner
  dashboard.mergeCells('B2:G2');
  const titleCell = dashboard.getCell('B2');
  titleCell.value = 'STRIVECAMPUS WEB E2E TEST SUMMARY';
  titleCell.font = { name: 'Segoe UI', size: 16, bold: true, color: { argb: 'FFFFFFFF' } };
  titleCell.alignment = { vertical: 'middle', horizontal: 'center' };
  titleCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF45B08C' } }; // Brand Green

  dashboard.getRow(2).height = 40;

  const totalSteps = results.length;
  const passedSteps = results.filter(r => r.status === 'PASS').length;
  const failedSteps = results.filter(r => r.status === 'FAIL').length;
  const passPercent = totalSteps > 0 ? (passedSteps / totalSteps) * 100 : 0;
  const successRate = passPercent.toFixed(1) + '%';
  const totalDuration = (durationMs / 1000).toFixed(2) + 's';
  const deployableStatus = passPercent >= 98.0 ? 'DEPLOYABLE (PASS RATE >= 98%)' : 'NOT DEPLOYABLE (PASS RATE < 98%)';

  const metrics = [
    { label: 'Total Test Steps', val: totalSteps },
    { label: 'Steps Passed', val: passedSteps },
    { label: 'Steps Failed', val: failedSteps },
    { label: 'Success Rate', val: successRate },
    { label: 'Total Duration', val: totalDuration },
    { label: 'Deployable Status', val: deployableStatus }
  ];

  // Setup summary table
  dashboard.getCell('B4').value = 'Metric Name';
  dashboard.getCell('B4').font = { name: 'Segoe UI', bold: true, color: { argb: 'FFFFFFFF' } };
  dashboard.getCell('B4').fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF1A1A2E' } };
  dashboard.getCell('B4').alignment = { horizontal: 'left', vertical: 'middle' };

  dashboard.getCell('C4').value = 'Value';
  dashboard.getCell('C4').font = { name: 'Segoe UI', bold: true, color: { argb: 'FFFFFFFF' } };
  dashboard.getCell('C4').fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF1A1A2E' } };
  dashboard.getCell('C4').alignment = { horizontal: 'center', vertical: 'middle' };
  
  dashboard.getRow(4).height = 24;

  metrics.forEach((m, idx) => {
    const rowNum = 5 + idx;
    dashboard.getRow(rowNum).height = 20;

    dashboard.getCell(`B${rowNum}`).value = m.label;
    dashboard.getCell(`B${rowNum}`).font = { name: 'Segoe UI' };

    dashboard.getCell(`C${rowNum}`).value = m.val;
    dashboard.getCell(`C${rowNum}`).font = { name: 'Segoe UI', bold: true };
    dashboard.getCell(`C${rowNum}`).alignment = { horizontal: 'center' };

    // Special styling for highlights
    if (m.label === 'Steps Failed') {
      dashboard.getCell(`C${rowNum}`).font = { name: 'Segoe UI', bold: true, color: { argb: m.val > 0 ? 'FFFF0000' : 'FF000000' } };
    } else if (m.label === 'Success Rate') {
      dashboard.getCell(`C${rowNum}`).font = { name: 'Segoe UI', bold: true, color: { argb: 'FF008000' } };
    } else if (m.label === 'Deployable Status') {
      const isDeployable = passPercent >= 98.0;
      dashboard.getCell(`C${rowNum}`).font = { name: 'Segoe UI', bold: true, color: { argb: isDeployable ? 'FF008000' : 'FFFF0000' } };
    }
  });

  // Apply borders to table
  for (let r = 4; r <= 10; r++) {
    for (let c = 2; c <= 3; c++) {
      const cell = dashboard.getCell(r, c);
      cell.border = {
        top: { style: 'thin', color: { argb: 'FFCCCCCC' } },
        bottom: { style: 'thin', color: { argb: 'FFCCCCCC' } },
        left: { style: 'thin', color: { argb: 'FFCCCCCC' } },
        right: { style: 'thin', color: { argb: 'FFCCCCCC' } }
      };
    }
  }

  // ==========================================
  // CATEGORY SUMMARY BREAKDOWN
  // ==========================================
  const categories = [
    'UI/UX Verification',
    'Functional Workflows',
    'Unit Tests',
    'Input & Schema Validation'
  ];

  dashboard.getCell('E4').value = 'Category';
  dashboard.getCell('E4').font = { name: 'Segoe UI', bold: true, color: { argb: 'FFFFFFFF' } };
  dashboard.getCell('E4').fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF1A1A2E' } };
  dashboard.getCell('E4').alignment = { horizontal: 'left', vertical: 'middle' };

  dashboard.getCell('F4').value = 'Total';
  dashboard.getCell('F4').font = { name: 'Segoe UI', bold: true, color: { argb: 'FFFFFFFF' } };
  dashboard.getCell('F4').fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF1A1A2E' } };
  dashboard.getCell('F4').alignment = { horizontal: 'center', vertical: 'middle' };

  dashboard.getCell('G4').value = 'Pass Rate';
  dashboard.getCell('G4').font = { name: 'Segoe UI', bold: true, color: { argb: 'FFFFFFFF' } };
  dashboard.getCell('G4').fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF1A1A2E' } };
  dashboard.getCell('G4').alignment = { horizontal: 'center', vertical: 'middle' };

  categories.forEach((cat, idx) => {
    const rowNum = 5 + idx;
    const catResults = results.filter(r => r.testCase === cat);
    const catTotal = catResults.length;
    const catPassed = catResults.filter(r => r.status === 'PASS').length;
    const catRate = catTotal > 0 ? ((catPassed / catTotal) * 100).toFixed(1) + '%' : '0%';

    dashboard.getCell(`E${rowNum}`).value = cat;
    dashboard.getCell(`E${rowNum}`).font = { name: 'Segoe UI' };

    dashboard.getCell(`F${rowNum}`).value = catTotal;
    dashboard.getCell(`F${rowNum}`).font = { name: 'Segoe UI' };
    dashboard.getCell(`F${rowNum}`).alignment = { horizontal: 'center' };

    dashboard.getCell(`G${rowNum}`).value = catRate;
    dashboard.getCell(`G${rowNum}`).font = { name: 'Segoe UI', bold: true };
    dashboard.getCell(`G${rowNum}`).alignment = { horizontal: 'center' };
  });

  for (let r = 4; r <= 8; r++) {
    for (let c = 5; c <= 7; c++) {
      const cell = dashboard.getCell(r, c);
      cell.border = {
        top: { style: 'thin', color: { argb: 'FFCCCCCC' } },
        bottom: { style: 'thin', color: { argb: 'FFCCCCCC' } },
        left: { style: 'thin', color: { argb: 'FFCCCCCC' } },
        right: { style: 'thin', color: { argb: 'FFCCCCCC' } }
      };
    }
  }

  dashboard.getColumn('B').width = 24;
  dashboard.getColumn('C').width = 32;
  dashboard.getColumn('E').width = 28;
  dashboard.getColumn('F').width = 12;
  dashboard.getColumn('G').width = 14;

  // ==========================================
  // SHEET 2: DETAILED TEST LOG
  // ==========================================
  const logSheet = workbook.addWorksheet('Detailed Test Log');
  logSheet.views = [{ showGridLines: true }];

  logSheet.columns = [
    { header: 'Test Category', key: 'testCase', width: 25 },
    { header: 'Test Case / Step Description', key: 'stepName', width: 60 },
    { header: 'Status', key: 'status', width: 12 },
    { header: 'Duration', key: 'duration', width: 12 },
    { header: 'Error Details', key: 'error', width: 50 }
  ];

  const logHeaderRow = logSheet.getRow(1);
  logHeaderRow.height = 28;
  logHeaderRow.eachCell((cell) => {
    cell.font = { name: 'Segoe UI', bold: true, color: { argb: 'FFFFFFFF' } };
    cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF1A1A2E' } };
    cell.alignment = { vertical: 'middle', horizontal: 'center' };
  });

  results.forEach((r) => {
    const row = logSheet.addRow({
      testCase: r.testCase,
      stepName: r.stepName,
      status: r.status,
      duration: `${(r.duration / 1000).toFixed(2)}s`,
      error: r.error || '-'
    });

    row.height = 22;

    row.getCell('status').alignment = { horizontal: 'center', vertical: 'middle' };
    row.getCell('duration').alignment = { horizontal: 'center', vertical: 'middle' };
    row.getCell('testCase').alignment = { vertical: 'middle' };
    row.getCell('stepName').alignment = { vertical: 'middle' };
    row.getCell('error').alignment = { vertical: 'middle' };

    const statusCell = row.getCell('status');
    if (r.status === 'PASS') {
      statusCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFD4EDDA' } }; // Light Green fill
      statusCell.font = { name: 'Segoe UI', color: { argb: 'FF155724' }, bold: true };
    } else {
      statusCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF8D7DA' } }; // Light Red fill
      statusCell.font = { name: 'Segoe UI', color: { argb: 'FF721C24' }, bold: true };
      row.getCell('error').font = { name: 'Segoe UI', color: { argb: 'FF721C24' } };
    }

    row.eachCell((cell) => {
      cell.border = {
        top: { style: 'thin', color: { argb: 'FFE8E8F0' } },
        bottom: { style: 'thin', color: { argb: 'FFE8E8F0' } },
        left: { style: 'thin', color: { argb: 'FFE8E8F0' } },
        right: { style: 'thin', color: { argb: 'FFE8E8F0' } }
      };
    });
  });

  const outputPath = path.join(__dirname, '..', '..', 'selenium_web_report.xlsx');
  await workbook.xlsx.writeFile(outputPath);
  console.log(`\n📊 Excel Report Generated Successfully: ${outputPath}`);
}

module.exports = { generateExcelReport };
