/**
 * generate_excel_report.js
 * Standalone script: reads the last test run results from log and
 * generates a beautiful, detailed Excel report with all 105 test cases.
 * 
 * Usage: node generate_excel_report.js
 */

const ExcelJS = require('exceljs');
const path = require('path');
const fs = require('fs');

// ─── All 105 Test Cases Definition ──────────────────────────────────────────
const ALL_TEST_CASES = [
  // ── UI/UX Verification (30) ──────────────────────────────────────────────
  { id: 'UI001', category: 'UI/UX Verification', description: 'Splash Screen branding indicator', type: 'UI/UX' },
  { id: 'UI002', category: 'UI/UX Verification', description: 'Splash Screen app name display', type: 'UI/UX' },
  { id: 'UI003', category: 'UI/UX Verification', description: 'Splash Screen tagline text', type: 'UI/UX' },
  { id: 'UI004', category: 'UI/UX Verification', description: 'Onboarding page 1 title display', type: 'UI/UX' },
  { id: 'UI005', category: 'UI/UX Verification', description: 'Onboarding page 1 description text layout', type: 'UI/UX' },
  { id: 'UI006', category: 'UI/UX Verification', description: 'Onboarding page 1 button text', type: 'UI/UX' },
  { id: 'UI007', category: 'UI/UX Verification', description: 'Onboarding active page indicator state', type: 'UI/UX' },
  { id: 'UI008', category: 'UI/UX Verification', description: 'Onboarding skip button option visibility', type: 'UI/UX' },
  { id: 'UI009', category: 'UI/UX Verification', description: 'Onboarding page 2 title display', type: 'UI/UX' },
  { id: 'UI010', category: 'UI/UX Verification', description: 'Onboarding page 2 description text layout', type: 'UI/UX' },
  { id: 'UI011', category: 'UI/UX Verification', description: 'Onboarding page 2 active page indicator state', type: 'UI/UX' },
  { id: 'UI012', category: 'UI/UX Verification', description: 'Onboarding page 3 title display', type: 'UI/UX' },
  { id: 'UI013', category: 'UI/UX Verification', description: 'Onboarding page 3 description text layout', type: 'UI/UX' },
  { id: 'UI014', category: 'UI/UX Verification', description: 'Onboarding page 3 Get Started button layout', type: 'UI/UX' },
  { id: 'UI015', category: 'UI/UX Verification', description: 'Login Screen background card shape', type: 'UI/UX' },
  { id: 'UI016', category: 'UI/UX Verification', description: 'Login screen email input container styling', type: 'UI/UX' },
  { id: 'UI017', category: 'UI/UX Verification', description: 'Login screen password input container styling', type: 'UI/UX' },
  { id: 'UI018', category: 'UI/UX Verification', description: 'Login button background design', type: 'UI/UX' },
  { id: 'UI019', category: 'UI/UX Verification', description: 'Login header branding typography', type: 'UI/UX' },
  { id: 'UI020', category: 'UI/UX Verification', description: 'Register screen fields typography and spacing', type: 'UI/UX' },
  { id: 'UI021', category: 'UI/UX Verification', description: 'Register button border radius', type: 'UI/UX' },
  { id: 'UI022', category: 'UI/UX Verification', description: 'Register footer link styling', type: 'UI/UX' },
  { id: 'UI023', category: 'UI/UX Verification', description: 'Bottom navigation bar alignment & icon sets', type: 'UI/UX' },
  { id: 'UI024', category: 'UI/UX Verification', description: 'Dashboard header title formatting', type: 'UI/UX' },
  { id: 'UI025', category: 'UI/UX Verification', description: 'Theme toggler button visual contrast', type: 'UI/UX' },
  { id: 'UI026', category: 'UI/UX Verification', description: 'Light mode dashboard theme colors', type: 'UI/UX' },
  { id: 'UI027', category: 'UI/UX Verification', description: 'Dark mode theme transition styles', type: 'UI/UX' },
  { id: 'UI028', category: 'UI/UX Verification', description: 'Profile screen user avatar size layout', type: 'UI/UX' },
  { id: 'UI029', category: 'UI/UX Verification', description: 'Test session card border margins', type: 'UI/UX' },
  { id: 'UI030', category: 'UI/UX Verification', description: 'AI Feedback dialog spacing layout', type: 'UI/UX' },

  // ── Functional Workflows (30) ─────────────────────────────────────────────
  { id: 'FN001', category: 'Functional Workflows', description: 'Load app page successfully', type: 'Functional' },
  { id: 'FN002', category: 'Functional Workflows', description: 'Click Next to access page 2', type: 'Functional' },
  { id: 'FN003', category: 'Functional Workflows', description: 'Click Next to access page 3', type: 'Functional' },
  { id: 'FN004', category: 'Functional Workflows', description: 'Skip button bypasses onboarding screen', type: 'Functional' },
  { id: 'FN005', category: 'Functional Workflows', description: 'Complete onboarding and transition to authentication page', type: 'Functional' },
  { id: 'FN006', category: 'Functional Workflows', description: 'Select register navigation path', type: 'Functional' },
  { id: 'FN007', category: 'Functional Workflows', description: 'Register a new account with valid unique details', type: 'Functional' },
  { id: 'FN008', category: 'Functional Workflows', description: 'Submit register account credentials to Firestore', type: 'Functional' },
  { id: 'FN009', category: 'Functional Workflows', description: 'Verify user main dashboard is successfully loaded', type: 'Functional' },
  { id: 'FN010', category: 'Functional Workflows', description: 'Navigate to Aptitude & Technical Tests tab', type: 'Functional' },
  { id: 'FN011', category: 'Functional Workflows', description: 'Render Aptitude list categories', type: 'Functional' },
  { id: 'FN012', category: 'Functional Workflows', description: 'Switch tests list to Technical category', type: 'Functional' },
  { id: 'FN013', category: 'Functional Workflows', description: 'Switch tests list to HR category', type: 'Functional' },
  { id: 'FN014', category: 'Functional Workflows', description: 'Select HR Mock Interview session card', type: 'Functional' },
  { id: 'FN015', category: 'Functional Workflows', description: 'Set question counts in configuration card', type: 'Functional' },
  { id: 'FN016', category: 'Functional Workflows', description: 'Launch the HR Interview round', type: 'Functional' },
  { id: 'FN017', category: 'Functional Workflows', description: 'Wait for AI Interviewer to load question details', type: 'Functional' },
  { id: 'FN018', category: 'Functional Workflows', description: 'Retrieve visual text of mock question', type: 'Functional' },
  { id: 'FN019', category: 'Functional Workflows', description: 'Input answer to the generated mock question', type: 'Functional' },
  { id: 'FN020', category: 'Functional Workflows', description: 'Submit answer to AI evaluation engine', type: 'Functional' },
  { id: 'FN021', category: 'Functional Workflows', description: 'Retrieve feedback score from Groq API response', type: 'Functional' },
  { id: 'FN022', category: 'Functional Workflows', description: 'Display evaluation advice layout', type: 'Functional' },
  { id: 'FN023', category: 'Functional Workflows', description: 'Exit active interview page using close option', type: 'Functional' },
  { id: 'FN024', category: 'Functional Workflows', description: 'Exit dialog confirmation redirects back to dashboard', type: 'Functional' },
  { id: 'FN025', category: 'Functional Workflows', description: 'Navigate to Chatbot assistant tab', type: 'Functional' },
  { id: 'FN026', category: 'Functional Workflows', description: 'Enter custom text message in chat query input', type: 'Functional' },
  { id: 'FN027', category: 'Functional Workflows', description: 'Receive chatbot answer correctly', type: 'Functional' },
  { id: 'FN028', category: 'Functional Workflows', description: 'Access user settings & profile tab', type: 'Functional' },
  { id: 'FN029', category: 'Functional Workflows', description: 'Trigger log out process', type: 'Functional' },
  { id: 'FN030', category: 'Functional Workflows', description: 'Confirm sign out dialog returns user to login view', type: 'Functional' },

  // ── Unit Tests (25) ───────────────────────────────────────────────────────
  { id: 'UN001', category: 'Unit Tests', description: 'Validate email regex check for correct domain format', type: 'Unit' },
  { id: 'UN002', category: 'Unit Tests', description: 'Validate email regex check rejects spaces', type: 'Unit' },
  { id: 'UN003', category: 'Unit Tests', description: 'Check password length validator allows 6+ characters', type: 'Unit' },
  { id: 'UN004', category: 'Unit Tests', description: 'Calculate attendance percentage threshold alert flag', type: 'Unit' },
  { id: 'UN005', category: 'Unit Tests', description: 'GPA range checker limits score input', type: 'Unit' },
  { id: 'UN006', category: 'Unit Tests', description: 'Parse Groq LLM API feedback score strings', type: 'Unit' },
  { id: 'UN007', category: 'Unit Tests', description: 'Format epoch milliseconds into readable relative duration', type: 'Unit' },
  { id: 'UN008', category: 'Unit Tests', description: 'Name field input constraint validation check', type: 'Unit' },
  { id: 'UN009', category: 'Unit Tests', description: 'Sanitize user input text to escape script tags', type: 'Unit' },
  { id: 'UN010', category: 'Unit Tests', description: 'SharedPreferences theme status key checks', type: 'Unit' },
  { id: 'UN011', category: 'Unit Tests', description: 'Map Groq rating integers to text badges', type: 'Unit' },
  { id: 'UN012', category: 'Unit Tests', description: 'Calculate test score percentage from raw integers', type: 'Unit' },
  { id: 'UN013', category: 'Unit Tests', description: 'API keys placeholder detection logic', type: 'Unit' },
  { id: 'UN014', category: 'Unit Tests', description: 'Question limits bounds validation logic', type: 'Unit' },
  { id: 'UN015', category: 'Unit Tests', description: 'Parse markdown bullets to list arrays', type: 'Unit' },
  { id: 'UN016', category: 'Unit Tests', description: 'Format durations into mm:ss format', type: 'Unit' },
  { id: 'UN017', category: 'Unit Tests', description: 'Platform checker validation parameters', type: 'Unit' },
  { id: 'UN018', category: 'Unit Tests', description: 'Date parser verification', type: 'Unit' },
  { id: 'UN019', category: 'Unit Tests', description: 'Firestore structure array mapper logic', type: 'Unit' },
  { id: 'UN020', category: 'Unit Tests', description: 'Notifications channel settings validation', type: 'Unit' },
  { id: 'UN021', category: 'Unit Tests', description: 'Phone number sanitization validation', type: 'Unit' },
  { id: 'UN022', category: 'Unit Tests', description: 'Network offline sync status validator', type: 'Unit' },
  { id: 'UN023', category: 'Unit Tests', description: 'GPA eligibility for premium placements check', type: 'Unit' },
  { id: 'UN024', category: 'Unit Tests', description: 'Map test scores to dashboard charts datasets', type: 'Unit' },
  { id: 'UN025', category: 'Unit Tests', description: 'Chat conversation search filter algorithm', type: 'Unit' },

  // ── Input & Schema Validation (20) ────────────────────────────────────────
  { id: 'VL001', category: 'Input & Schema Validation', description: 'Register user empty first name triggers validation', type: 'Validation' },
  { id: 'VL002', category: 'Input & Schema Validation', description: 'Register user empty last name triggers validation', type: 'Validation' },
  { id: 'VL003', category: 'Input & Schema Validation', description: 'Register user blank email validation toast', type: 'Validation' },
  { id: 'VL004', category: 'Input & Schema Validation', description: 'Register user invalid email format display', type: 'Validation' },
  { id: 'VL005', category: 'Input & Schema Validation', description: 'Register user weak password complexity warning display', type: 'Validation' },
  { id: 'VL006', category: 'Input & Schema Validation', description: 'Authenticate with invalid email formatting', type: 'Validation' },
  { id: 'VL007', category: 'Input & Schema Validation', description: 'Authenticate with wrong password key error toast', type: 'Validation' },
  { id: 'VL008', category: 'Input & Schema Validation', description: 'Submit empty text answer to HR Interviewer returns validation message', type: 'Validation' },
  { id: 'VL009', category: 'Input & Schema Validation', description: 'Check question counts upper limit constraint', type: 'Validation' },
  { id: 'VL010', category: 'Input & Schema Validation', description: 'Check question counts lower limit constraint', type: 'Validation' },
  { id: 'VL011', category: 'Input & Schema Validation', description: 'Submit aptitude test with no questions answered displays alert dialog', type: 'Validation' },
  { id: 'VL012', category: 'Input & Schema Validation', description: 'Save offline test session log validation check', type: 'Validation' },
  { id: 'VL013', category: 'Input & Schema Validation', description: 'Submit empty chatbot query displays warning placeholder', type: 'Validation' },
  { id: 'VL014', category: 'Input & Schema Validation', description: 'Edit profile page with blank username returns input validation warning', type: 'Validation' },
  { id: 'VL015', category: 'Input & Schema Validation', description: 'Network timeout request simulation logic', type: 'Validation' },
  { id: 'VL016', category: 'Input & Schema Validation', description: 'Groq API response schema validation matches structure standards', type: 'Validation' },
  { id: 'VL017', category: 'Input & Schema Validation', description: 'Groq API error structure formatting wrapper parsing', type: 'Validation' },
  { id: 'VL018', category: 'Input & Schema Validation', description: 'Concurrent db transactions check locks validation rules', type: 'Validation' },
  { id: 'VL019', category: 'Input & Schema Validation', description: 'Real-time user session status validation updates check', type: 'Validation' },
  { id: 'VL020', category: 'Input & Schema Validation', description: 'Device camera/microphone permissions denied state warning display', type: 'Validation' },
];

// ─── Parse Latest Log File ──────────────────────────────────────────────────
function parseLogFile(logPath) {
  const results = {};
  if (!fs.existsSync(logPath)) return results;

  const content = fs.readFileSync(logPath, 'utf-8');
  const lines = content.split('\n');

  let currentStep = null;
  for (const line of lines) {
    const passMatch = line.match(/\[PASS\]\s+(.+?)\s+>\s+(.+?)\s+\((.+?)s\)/);
    const failMatch = line.match(/\[FAIL\]\s+(.+?)\s+>\s+(.+?)\s+\((.+?)s\)/);
    const errMatch  = line.match(/^\s+Error:\s+(.+)/);

    if (passMatch) {
      const key = passMatch[2].trim().split(':')[0].trim();
      results[key] = { status: 'PASS', duration: passMatch[3], error: '' };
    } else if (failMatch) {
      currentStep = failMatch[2].trim().split(':')[0].trim();
      results[currentStep] = { status: 'FAIL', duration: failMatch[3], error: '' };
    } else if (errMatch && currentStep && results[currentStep]) {
      results[currentStep].error = errMatch[1].trim();
      currentStep = null;
    }
  }

  return results;
}

// ─── Find latest log ────────────────────────────────────────────────────────
function findLatestLog() {
  const taskDir = path.join(
    'C:\\Users\\Raman\\.gemini\\antigravity-ide\\brain\\9369ff22-c1a6-4bf8-a961-a6d9dcc2e346\\.system_generated\\tasks'
  );
  
  if (!fs.existsSync(taskDir)) return null;
  
  const logs = fs.readdirSync(taskDir)
    .filter(f => f.endsWith('.log'))
    .map(f => ({ name: f, mtime: fs.statSync(path.join(taskDir, f)).mtime }))
    .sort((a, b) => b.mtime - a.mtime);

  // Find logs that have our test runner output
  for (const log of logs) {
    const content = fs.readFileSync(path.join(taskDir, log.name), 'utf-8');
    if (content.includes('StriveCampus Selenium E2E Web Tests') && content.includes('[PASS]')) {
      return path.join(taskDir, log.name);
    }
  }
  return null;
}

// ─── Color Palette ──────────────────────────────────────────────────────────
const COLORS = {
  headerBg:     'FF1A1A2E',
  headerFg:     'FFFFFFFF',
  brandGreen:   'FF45B08C',
  brandDark:    'FF0F3460',
  passGreen:    'FF1E7E34',
  passBg:       'FFD4EDDA',
  failRed:      'FF721C24',
  failBg:       'FFF8D7DA',
  pendingBg:    'FFFFF3CD',
  pendingFg:    'FF856404',
  altRow:       'FFF5F7FF',
  white:        'FFFFFFFF',
  uiColor:      'FF6C63FF',
  fnColor:      'FF0077B6',
  unColor:      'FF2EC4B6',
  vlColor:      'FFFF9F1C',
  borderGray:   'FFDDDDDD',
};

const TYPE_COLORS = {
  'UI/UX':       { bg: 'FFF0EEFF', fg: 'FF6C63FF' },
  'Functional':  { bg: 'FFE8F4F8', fg: 'FF0077B6' },
  'Unit':        { bg: 'FFE8F8F7', fg: 'FF2EC4B6' },
  'Validation':  { bg: 'FFFFF8EE', fg: 'FFFF9F1C' },
};

function applyBorder(cell) {
  cell.border = {
    top:    { style: 'thin', color: { argb: COLORS.borderGray } },
    bottom: { style: 'thin', color: { argb: COLORS.borderGray } },
    left:   { style: 'thin', color: { argb: COLORS.borderGray } },
    right:  { style: 'thin', color: { argb: COLORS.borderGray } },
  };
}

// ─── Main Generator ──────────────────────────────────────────────────────────
async function generateReport() {
  console.log('🔍 Searching for latest test run log...');
  const logPath = findLatestLog();
  const runResults = logPath ? parseLogFile(logPath) : {};
  const logFound = !!logPath;
  console.log(logFound ? `✅ Log found: ${logPath}` : '⚠️  No log found. Generating report with PENDING status.');

  // Merge with test case definitions
  const testData = ALL_TEST_CASES.map(tc => {
    const logEntry = runResults[tc.id] || null;
    return {
      ...tc,
      status:   logEntry ? logEntry.status : 'PENDING',
      duration: logEntry ? `${logEntry.duration}s` : '-',
      error:    logEntry ? (logEntry.error || '-') : '-',
    };
  });

  // Stats
  const total    = testData.length;
  const passed   = testData.filter(t => t.status === 'PASS').length;
  const failed   = testData.filter(t => t.status === 'FAIL').length;
  const pending  = testData.filter(t => t.status === 'PENDING').length;
  const passRate = total > 0 ? ((passed / total) * 100).toFixed(1) : '0.0';
  const deployable = parseFloat(passRate) >= 98.0;

  const wb = new ExcelJS.Workbook();
  wb.creator = 'StriveCampus QA Automator';
  wb.created = new Date();

  // ════════════════════════════════════════════════════════════════════════════
  // SHEET 1: SUMMARY DASHBOARD
  // ════════════════════════════════════════════════════════════════════════════
  const summary = wb.addWorksheet('📊 Summary Dashboard');
  summary.views = [{ showGridLines: false }];

  // Title banner
  summary.mergeCells('B2:J2');
  const titleCell = summary.getCell('B2');
  titleCell.value = '🎓 STRIVECAMPUS — SELENIUM E2E WEB TEST REPORT';
  titleCell.font  = { name: 'Segoe UI', size: 18, bold: true, color: { argb: COLORS.headerFg } };
  titleCell.alignment = { horizontal: 'center', vertical: 'middle' };
  titleCell.fill  = { type: 'pattern', pattern: 'solid', fgColor: { argb: COLORS.brandDark } };
  summary.getRow(2).height = 50;

  // Subtitle
  summary.mergeCells('B3:J3');
  const subCell = summary.getCell('B3');
  subCell.value = `Generated: ${new Date().toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' })}  |  Tool: Selenium WebDriver + Node.js  |  App: http://127.0.0.1:8080`;
  subCell.font  = { name: 'Segoe UI', size: 10, color: { argb: 'FF888888' } };
  subCell.alignment = { horizontal: 'center', vertical: 'middle' };
  summary.getRow(3).height = 22;

  // ── Metric Cards ──────────────────────────────────────────────────────────
  const metrics = [
    { label: 'Total Test Cases', value: total,       color: COLORS.brandDark  },
    { label: 'Tests Passed ✅',  value: passed,      color: COLORS.passGreen  },
    { label: 'Tests Failed ❌',  value: failed,      color: failed > 0 ? 'FFCC0000' : COLORS.passGreen },
    { label: 'Pending ⏳',       value: pending,     color: COLORS.pendingFg  },
    { label: 'Pass Rate 📈',     value: `${passRate}%`, color: parseFloat(passRate) >= 98 ? COLORS.passGreen : 'FFCC0000' },
    { label: 'Deployable 🚀',   value: deployable ? 'YES ✅' : 'NO ❌', color: deployable ? COLORS.passGreen : 'FFCC0000' },
  ];

  const metricCols = ['B', 'D', 'F', 'H', 'B', 'D'];
  const metricRows = [5, 5, 5, 5, 8, 8];

  metrics.forEach((m, i) => {
    const col = metricCols[i];
    const row = metricRows[i];
    const labelCell = summary.getCell(`${col}${row}`);
    const valueCell = summary.getCell(`${col}${row + 1}`);
    
    summary.mergeCells(`${col}${row}:${String.fromCharCode(col.charCodeAt(0) + 1)}${row}`);
    summary.mergeCells(`${col}${row + 1}:${String.fromCharCode(col.charCodeAt(0) + 1)}${row + 1}`);

    labelCell.value = m.label;
    labelCell.font  = { name: 'Segoe UI', size: 10, bold: true, color: { argb: COLORS.headerFg } };
    labelCell.fill  = { type: 'pattern', pattern: 'solid', fgColor: { argb: COLORS.headerBg } };
    labelCell.alignment = { horizontal: 'center', vertical: 'middle' };
    summary.getRow(row).height = 22;

    valueCell.value = m.value;
    valueCell.font  = { name: 'Segoe UI', size: 18, bold: true, color: { argb: m.color } };
    valueCell.fill  = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF8F9FA' } };
    valueCell.alignment = { horizontal: 'center', vertical: 'middle' };
    summary.getRow(row + 1).height = 34;
  });

  // ── Category Breakdown Table ──────────────────────────────────────────────
  const cats = [
    { name: 'UI/UX Verification',      count: 30, type: 'UI/UX'      },
    { name: 'Functional Workflows',    count: 30, type: 'Functional'  },
    { name: 'Unit Tests',              count: 25, type: 'Unit'        },
    { name: 'Input & Schema Validation', count: 20, type: 'Validation' },
  ];

  ['F', 'G', 'H', 'I', 'J'].forEach((col, ci) => {
    const headers = ['', 'Category', 'Total', 'Passed', 'Failed', 'Pass Rate'];
    const hCell = summary.getCell(`${col}5`);
    hCell.value = headers[ci + 1] || '';
    hCell.font  = { name: 'Segoe UI', bold: true, size: 10, color: { argb: COLORS.headerFg } };
    hCell.fill  = { type: 'pattern', pattern: 'solid', fgColor: { argb: COLORS.brandDark } };
    hCell.alignment = { horizontal: 'center', vertical: 'middle' };
    applyBorder(hCell);
    summary.getRow(5).height = 24;
  });

  cats.forEach((cat, idx) => {
    const row = 6 + idx;
    const catData = testData.filter(t => t.category === cat.name);
    const catPassed = catData.filter(t => t.status === 'PASS').length;
    const catFailed = catData.filter(t => t.status === 'FAIL').length;
    const catRate   = catData.length > 0 ? ((catPassed / catData.length) * 100).toFixed(1) + '%' : '-';
    const tc = TYPE_COLORS[cat.type] || {};

    const rowData = [cat.name, cat.count, catPassed, catFailed, catRate];
    ['F', 'G', 'H', 'I', 'J'].forEach((col, ci) => {
      const cell = summary.getCell(`${col}${row}`);
      cell.value = rowData[ci];
      cell.font  = { name: 'Segoe UI', size: 10, color: { argb: ci === 0 ? tc.fg : COLORS.headerBg } };
      cell.fill  = { type: 'pattern', pattern: 'solid', fgColor: { argb: idx % 2 === 0 ? tc.bg : COLORS.white } };
      cell.alignment = { horizontal: ci === 0 ? 'left' : 'center', vertical: 'middle' };
      applyBorder(cell);
    });
    summary.getRow(row).height = 20;
  });

  // Column widths
  summary.getColumn('B').width = 22;
  summary.getColumn('C').width = 4;
  summary.getColumn('D').width = 22;
  summary.getColumn('E').width = 4;
  summary.getColumn('F').width = 32;
  summary.getColumn('G').width = 10;
  summary.getColumn('H').width = 10;
  summary.getColumn('I').width = 10;
  summary.getColumn('J').width = 12;

  // ════════════════════════════════════════════════════════════════════════════
  // SHEET 2: ALL TEST CASES
  // ════════════════════════════════════════════════════════════════════════════
  const detail = wb.addWorksheet('📋 All Test Cases');
  detail.views = [{ showGridLines: true, state: 'frozen', ySplit: 1 }];

  detail.columns = [
    { key: 'id',       header: 'Test ID',          width: 10 },
    { key: 'type',     header: 'Test Type',         width: 16 },
    { key: 'category', header: 'Category',          width: 30 },
    { key: 'description', header: 'Test Case Description', width: 62 },
    { key: 'status',   header: 'Status',            width: 12 },
    { key: 'duration', header: 'Duration',          width: 12 },
    { key: 'error',    header: 'Error / Remarks',   width: 55 },
  ];

  // Header row
  const hRow = detail.getRow(1);
  hRow.height = 30;
  hRow.eachCell(cell => {
    cell.font  = { name: 'Segoe UI', bold: true, size: 11, color: { argb: COLORS.headerFg } };
    cell.fill  = { type: 'pattern', pattern: 'solid', fgColor: { argb: COLORS.headerBg } };
    cell.alignment = { horizontal: 'center', vertical: 'middle' };
    applyBorder(cell);
  });

  // Data rows
  testData.forEach((tc, i) => {
    const row = detail.addRow({
      id:          tc.id,
      type:        tc.type,
      category:    tc.category,
      description: tc.description,
      status:      tc.status,
      duration:    tc.duration,
      error:       tc.error,
    });
    row.height = 22;

    const tc_colors = TYPE_COLORS[tc.type] || { bg: COLORS.white, fg: COLORS.headerBg };
    const isAlt = i % 2 === 1;

    row.eachCell((cell, colNum) => {
      cell.font = { name: 'Segoe UI', size: 10 };
      cell.alignment = { vertical: 'middle', wrapText: colNum === 4 };
      applyBorder(cell);
    });

    // ID cell
    const idCell = row.getCell('id');
    idCell.font = { name: 'Segoe UI Semibold', size: 10, bold: true, color: { argb: tc_colors.fg } };
    idCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: tc_colors.bg } };
    idCell.alignment = { horizontal: 'center', vertical: 'middle' };

    // Type cell
    const typeCell = row.getCell('type');
    typeCell.font = { name: 'Segoe UI', size: 10, color: { argb: tc_colors.fg } };
    typeCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: tc_colors.bg } };
    typeCell.alignment = { horizontal: 'center', vertical: 'middle' };

    // Category
    const catCell = row.getCell('category');
    catCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: isAlt ? COLORS.altRow : COLORS.white } };

    // Description
    const descCell = row.getCell('description');
    descCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: isAlt ? COLORS.altRow : COLORS.white } };

    // Status cell — color coded
    const statusCell = row.getCell('status');
    statusCell.alignment = { horizontal: 'center', vertical: 'middle' };
    if (tc.status === 'PASS') {
      statusCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: COLORS.passBg } };
      statusCell.font = { name: 'Segoe UI', bold: true, size: 10, color: { argb: COLORS.passGreen } };
    } else if (tc.status === 'FAIL') {
      statusCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: COLORS.failBg } };
      statusCell.font = { name: 'Segoe UI', bold: true, size: 10, color: { argb: COLORS.failRed } };
    } else {
      statusCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: COLORS.pendingBg } };
      statusCell.font = { name: 'Segoe UI', bold: true, size: 10, color: { argb: COLORS.pendingFg } };
    }

    // Duration
    const durCell = row.getCell('duration');
    durCell.alignment = { horizontal: 'center', vertical: 'middle' };
    durCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: isAlt ? COLORS.altRow : COLORS.white } };

    // Error
    const errCell = row.getCell('error');
    errCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: isAlt ? COLORS.altRow : COLORS.white } };
    if (tc.status === 'FAIL') {
      errCell.font = { name: 'Segoe UI', size: 10, color: { argb: COLORS.failRed } };
    }
  });

  // ════════════════════════════════════════════════════════════════════════════
  // SHEET 3: CATEGORY BREAKDOWN
  // ════════════════════════════════════════════════════════════════════════════
  const breakdown = wb.addWorksheet('📈 Category Breakdown');
  breakdown.views = [{ showGridLines: true, state: 'frozen', ySplit: 2 }];

  const catOrder = ['UI/UX Verification', 'Functional Workflows', 'Unit Tests', 'Input & Schema Validation'];

  catOrder.forEach((catName, catIdx) => {
    const catTests = testData.filter(t => t.category === catName);
    const catType  = catTests[0]?.type || '';
    const tc_colors = TYPE_COLORS[catType] || { bg: 'FFF0F0F0', fg: COLORS.headerBg };
    const catPassed = catTests.filter(t => t.status === 'PASS').length;

    // Category header
    const startRow = breakdown.rowCount + (catIdx === 0 ? 1 : 2);

    breakdown.mergeCells(`A${startRow}:G${startRow}`);
    const catHeader = breakdown.getCell(`A${startRow}`);
    catHeader.value = `${catName}  —  ${catPassed}/${catTests.length} Passed  (${catTests.length > 0 ? ((catPassed/catTests.length)*100).toFixed(1) : 0}%)`;
    catHeader.font  = { name: 'Segoe UI', size: 12, bold: true, color: { argb: COLORS.headerFg } };
    catHeader.fill  = { type: 'pattern', pattern: 'solid', fgColor: { argb: COLORS.brandDark } };
    catHeader.alignment = { horizontal: 'left', vertical: 'middle', indent: 1 };
    breakdown.getRow(startRow).height = 28;

    // Column headers
    const colHRow = breakdown.addRow(['Test ID', 'Test Type', 'Description', 'Status', 'Duration', 'Error / Remarks', '']);
    colHRow.height = 22;
    colHRow.eachCell((cell, ci) => {
      if (ci <= 6) {
        cell.font  = { name: 'Segoe UI', bold: true, size: 10, color: { argb: tc_colors.fg } };
        cell.fill  = { type: 'pattern', pattern: 'solid', fgColor: { argb: tc_colors.bg } };
        cell.alignment = { horizontal: 'center', vertical: 'middle' };
        applyBorder(cell);
      }
    });

    // Data rows
    catTests.forEach((tc, i) => {
      const dRow = breakdown.addRow([tc.id, tc.type, tc.description, tc.status, tc.duration, tc.error, '']);
      dRow.height = 20;

      dRow.eachCell((cell, ci) => {
        if (ci > 6) return;
        cell.font = { name: 'Segoe UI', size: 10 };
        cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: i % 2 === 0 ? COLORS.white : COLORS.altRow } };
        cell.alignment = { vertical: 'middle', horizontal: ci === 1 || ci === 2 || ci === 4 ? 'center' : 'left' };
        applyBorder(cell);
      });

      const statusCell = dRow.getCell(4);
      statusCell.alignment = { horizontal: 'center', vertical: 'middle' };
      if (tc.status === 'PASS') {
        statusCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: COLORS.passBg } };
        statusCell.font = { name: 'Segoe UI', bold: true, size: 10, color: { argb: COLORS.passGreen } };
      } else if (tc.status === 'FAIL') {
        statusCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: COLORS.failBg } };
        statusCell.font = { name: 'Segoe UI', bold: true, size: 10, color: { argb: COLORS.failRed } };
      } else {
        statusCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: COLORS.pendingBg } };
        statusCell.font = { name: 'Segoe UI', bold: true, size: 10, color: { argb: COLORS.pendingFg } };
      }
    });
  });

  breakdown.getColumn(1).width = 10;
  breakdown.getColumn(2).width = 16;
  breakdown.getColumn(3).width = 62;
  breakdown.getColumn(4).width = 12;
  breakdown.getColumn(5).width = 12;
  breakdown.getColumn(6).width = 55;

  // ════════════════════════════════════════════════════════════════════════════
  // SAVE
  // ════════════════════════════════════════════════════════════════════════════
  const outPath = path.join(__dirname, '..', '..', 'selenium_web_report.xlsx');
  await wb.xlsx.writeFile(outPath);

  console.log('\n╔══════════════════════════════════════════════════════════════╗');
  console.log('║        📊 STRIVECAMPUS TEST REPORT GENERATED                ║');
  console.log('╠══════════════════════════════════════════════════════════════╣');
  console.log(`║  📁 File   : ${outPath.padEnd(47)}║`);
  console.log(`║  📋 Tests  : ${String(total).padEnd(47)}║`);
  console.log(`║  ✅ Passed : ${String(passed).padEnd(47)}║`);
  console.log(`║  ❌ Failed : ${String(failed).padEnd(47)}║`);
  console.log(`║  📈 Rate   : ${String(passRate + '%').padEnd(47)}║`);
  console.log(`║  🚀 Deploy : ${(deployable ? 'DEPLOYABLE ✅' : 'NOT DEPLOYABLE ❌').padEnd(47)}║`);
  console.log('╚══════════════════════════════════════════════════════════════╝\n');
}

generateReport().catch(err => {
  console.error('❌ Report generation failed:', err.message);
  process.exit(1);
});
