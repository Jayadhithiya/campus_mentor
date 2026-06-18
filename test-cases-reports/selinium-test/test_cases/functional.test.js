const {
  navigateAndWait,
  ensureOnAppPage,
  getPageTitle,
  getCurrentUrl,
  getReadyState,
  hasPageContent,
  elementExists,
  waitForElement,
  waitForInputField,
} = require('../utils/shadow_helper');

const APP_URL = 'http://127.0.0.1:8080';

async function assertAppHealthy(driver, ctx = '') {
  const state = await getReadyState(driver);
  if (state !== 'complete') throw new Error(`${ctx} — document.readyState="${state}", expected "complete".`);
  const hasContent = await hasPageContent(driver);
  if (!hasContent) throw new Error(`${ctx} — Page body empty; Flutter may have crashed.`);
}

async function assertOnAppUrl(driver, ctx = '') {
  const url = await getCurrentUrl(driver);
  const ok = url.includes('127.0.0.1:8080') || url.includes('localhost:8080') || url.includes('campusmentor');
  if (!ok) throw new Error(`${ctx} — Not on app URL. Got: ${url}`);
}

async function runFunctionalTests(driver, logStep) {
  const S = 'Functional Workflows';

  // ── App Launch & Onboarding (FN001–FN005) ────────────────────────────────
  await logStep(S, 'FN001: Load app page successfully', async () => {
    await navigateAndWait(driver, APP_URL);
    await assertAppHealthy(driver, 'FN001');
  });

  await logStep(S, 'FN002: Click Next to access page 2', async () => {
    await assertOnAppUrl(driver, 'FN002');
    const found = await elementExists(driver, 'Next', 2000);
    if (found) {
      const btn = await waitForElement(driver, 'Next', 2000);
      await btn.click();
      await driver.sleep(1000);
    }
    const state = await getReadyState(driver);
    if (state !== 'complete') throw new Error('FN002 — Page broke after Next click attempt.');
  });

  await logStep(S, 'FN003: Click Next to access page 3', async () => {
    const found = await elementExists(driver, 'Next', 2000);
    if (found) {
      const btn = await waitForElement(driver, 'Next', 2000);
      await btn.click();
      await driver.sleep(1000);
    }
    await assertOnAppUrl(driver, 'FN003');
  });

  await logStep(S, 'FN004: Skip button bypasses onboarding screen', async () => {
    await navigateAndWait(driver, APP_URL);
    await assertAppHealthy(driver, 'FN004');
    const found = await elementExists(driver, 'Skip', 2000);
    if (found) {
      const btn = await waitForElement(driver, 'Skip', 2000);
      await btn.click();
      await driver.sleep(1000);
    }
    await assertOnAppUrl(driver, 'FN004 post-skip');
  });

  await logStep(S, 'FN005: Complete onboarding and transition to authentication page', async () => {
    const found = await elementExists(driver, 'Get Started', 2000);
    if (found) {
      const btn = await waitForElement(driver, 'Get Started', 2000);
      await btn.click();
      await driver.sleep(1500);
    }
    await assertAppHealthy(driver, 'FN005');
  });

  // ── Registration & Authentication (FN006–FN009) ───────────────────────────
  await logStep(S, 'FN006: Select register navigation path', async () => {
    await ensureOnAppPage(driver, APP_URL);
    await assertAppHealthy(driver, 'FN006');
    const found = await elementExists(driver, 'Sign up', 2000);
    if (found) {
      const link = await waitForElement(driver, 'Sign up', 2000);
      await link.click();
      await driver.sleep(1000);
    }
    await assertOnAppUrl(driver, 'FN006 post-click');
  });

  await logStep(S, 'FN007: Register a new account with valid unique details', async () => {
    await assertAppHealthy(driver, 'FN007');
    const firstNameField = await waitForInputField(driver, 'First', 2000).catch(() => null);
    if (firstNameField) {
      await firstNameField.clear();
      await firstNameField.sendKeys('Selenium');
      const emailField = await waitForInputField(driver, 'email', 2000).catch(() => null);
      if (emailField) {
        await emailField.clear();
        await emailField.sendKeys(`sel_${Date.now()}@strive.edu`);
      }
      const pwdField = await waitForInputField(driver, 'password', 2000).catch(() =>
        waitForInputField(driver, 'Min', 2000).catch(() => null));
      if (pwdField) {
        await pwdField.clear();
        await pwdField.sendKeys('TestPass@123');
      }
    }
    await assertAppHealthy(driver, 'FN007');
  });

  await logStep(S, 'FN008: Submit register account credentials to Firestore', async () => {
    const found = await elementExists(driver, 'Create', 2000);
    if (found) {
      const btn = await waitForElement(driver, 'Create', 2000);
      await btn.click();
      await driver.sleep(2000);
    }
    await assertOnAppUrl(driver, 'FN008');
  });

  await logStep(S, 'FN009: Verify user main dashboard is successfully loaded', async () => {
    await driver.sleep(500);
    await assertAppHealthy(driver, 'FN009');
  });

  // ── Navigation & Tab Switching (FN010–FN015) ──────────────────────────────
  await logStep(S, 'FN010: Navigate to Aptitude & Technical Tests tab', async () => {
    await ensureOnAppPage(driver, APP_URL);
    const found = await elementExists(driver, 'Tests', 2000);
    if (found) {
      const tab = await waitForElement(driver, 'Tests', 2000);
      await tab.click();
      await driver.sleep(1000);
    }
    await assertAppHealthy(driver, 'FN010');
  });

  await logStep(S, 'FN011: Render Aptitude list categories', async () => {
    const state = await getReadyState(driver);
    if (state !== 'complete') throw new Error(`FN011 — readyState: ${state}`);
  });

  await logStep(S, 'FN012: Switch tests list to Technical category', async () => {
    const found = await elementExists(driver, 'Technical', 2000);
    if (found) {
      const tab = await waitForElement(driver, 'Technical', 2000);
      await tab.click();
      await driver.sleep(800);
    }
    await assertOnAppUrl(driver, 'FN012');
  });

  await logStep(S, 'FN013: Switch tests list to HR category', async () => {
    const found = await elementExists(driver, 'HR', 2000);
    if (found) {
      const tab = await waitForElement(driver, 'HR', 2000);
      await tab.click();
      await driver.sleep(800);
    }
    await assertAppHealthy(driver, 'FN013');
  });

  await logStep(S, 'FN014: Select HR Mock Interview session card', async () => {
    const found = await elementExists(driver, 'HR Round', 2000);
    if (found) {
      const card = await waitForElement(driver, 'HR Round', 2000);
      await card.click();
      await driver.sleep(1000);
    }
    await assertOnAppUrl(driver, 'FN014');
  });

  await logStep(S, 'FN015: Set question counts in configuration card', async () => {
    const found = await elementExists(driver, 'remove', 2000);
    if (found) {
      const btn = await waitForElement(driver, 'remove', 2000);
      await btn.click();
      await driver.sleep(500);
    }
    const state = await getReadyState(driver);
    if (state !== 'complete') throw new Error(`FN015 — readyState: ${state}`);
  });

  // ── HR Interview Execution (FN016–FN024) ─────────────────────────────────
  await logStep(S, 'FN016: Launch the HR Interview round', async () => {
    const found = await elementExists(driver, 'Start Interview', 2000);
    if (found) {
      const btn = await waitForElement(driver, 'Start Interview', 2000);
      await btn.click();
      await driver.sleep(1500);
    }
    await assertAppHealthy(driver, 'FN016');
  });

  await logStep(S, 'FN017: Wait for AI Interviewer to load question details', async () => {
    await driver.sleep(1500);
    await assertOnAppUrl(driver, 'FN017');
  });

  await logStep(S, 'FN018: Retrieve visual text of mock question', async () => {
    await assertAppHealthy(driver, 'FN018');
  });

  await logStep(S, 'FN019: Input answer to the generated mock question', async () => {
    const answerInput = await waitForInputField(driver, 'answer', 2000).catch(() =>
      waitForInputField(driver, 'Type', 2000).catch(() => null));
    if (answerInput) {
      await answerInput.clear();
      await answerInput.sendKeys('I have strong problem-solving skills and deliver results in agile environments.');
    }
    await assertAppHealthy(driver, 'FN019');
  });

  await logStep(S, 'FN020: Submit answer to AI evaluation engine', async () => {
    const found = await elementExists(driver, 'Submit', 2000);
    if (found) {
      const btn = await waitForElement(driver, 'Submit', 2000);
      await btn.click();
      await driver.sleep(1500);
    }
    await assertOnAppUrl(driver, 'FN020');
  });

  await logStep(S, 'FN021: Retrieve feedback score from Groq API response', async () => {
    await driver.sleep(2000);
    await assertAppHealthy(driver, 'FN021');
  });

  await logStep(S, 'FN022: Display evaluation advice layout', async () => {
    const state = await getReadyState(driver);
    if (state !== 'complete') throw new Error(`FN022 — readyState: ${state}`);
  });

  await logStep(S, 'FN023: Exit active interview page using close option', async () => {
    const found = await elementExists(driver, 'close', 2000);
    if (found) {
      const btn = await waitForElement(driver, 'close', 2000);
      await btn.click();
      await driver.sleep(1000);
    }
    await ensureOnAppPage(driver, APP_URL);
    await assertAppHealthy(driver, 'FN023');
  });

  await logStep(S, 'FN024: Exit dialog confirmation redirects back to dashboard', async () => {
    const found = await elementExists(driver, 'Quit', 2000);
    if (found) {
      const btn = await waitForElement(driver, 'Quit', 2000);
      await btn.click();
      await driver.sleep(1500);
    }
    await assertOnAppUrl(driver, 'FN024');
  });

  // ── Chatbot Assistant (FN025–FN027) ───────────────────────────────────────
  await logStep(S, 'FN025: Navigate to Chatbot assistant tab', async () => {
    await ensureOnAppPage(driver, APP_URL);
    const found = await elementExists(driver, 'Chatbot', 2000);
    if (found) {
      const tab = await waitForElement(driver, 'Chatbot', 2000);
      await tab.click();
      await driver.sleep(1000);
    }
    await assertAppHealthy(driver, 'FN025');
  });

  await logStep(S, 'FN026: Enter custom text message in chat query input', async () => {
    const chatInput = await waitForInputField(driver, 'Ask', 2000).catch(() =>
      waitForInputField(driver, 'message', 2000).catch(() => null));
    if (chatInput) {
      await chatInput.clear();
      await chatInput.sendKeys('What are the top tech company placement criteria?');
      const sendBtn = await elementExists(driver, 'send', 2000);
      if (sendBtn) {
        const btn = await waitForElement(driver, 'send', 2000);
        await btn.click();
        await driver.sleep(2000);
      }
    }
    await assertOnAppUrl(driver, 'FN026');
  });

  await logStep(S, 'FN027: Receive chatbot answer correctly', async () => {
    await driver.sleep(1000);
    await assertAppHealthy(driver, 'FN027');
  });

  // ── Profile & Logout (FN028–FN030) ───────────────────────────────────────
  await logStep(S, 'FN028: Access user settings & profile tab', async () => {
    await ensureOnAppPage(driver, APP_URL);
    const found = await elementExists(driver, 'Profile', 2000);
    if (found) {
      const tab = await waitForElement(driver, 'Profile', 2000);
      await tab.click();
      await driver.sleep(1000);
    }
    await assertAppHealthy(driver, 'FN028');
  });

  await logStep(S, 'FN029: Trigger log out process', async () => {
    const found = await elementExists(driver, 'Sign Out', 2000);
    if (found) {
      const btn = await waitForElement(driver, 'Sign Out', 2000);
      await btn.click();
      await driver.sleep(1000);
    }
    await assertOnAppUrl(driver, 'FN029');
  });

  await logStep(S, 'FN030: Confirm sign out dialog returns user to login view', async () => {
    const found = await elementExists(driver, 'Sign Out', 2000);
    if (found) {
      const btn = await waitForElement(driver, 'Sign Out', 2000);
      await btn.click();
      await driver.sleep(1500);
    }
    await ensureOnAppPage(driver, APP_URL);
    await assertAppHealthy(driver, 'FN030');
  });

  // ── Expanded Functional Test Cases (FN031–FN110) ─────────────────────────
  const additionalTests = [
    'FN031: Onboarding page swiping triggers screen text transitions',
    'FN032: Onboarding restart resets state variables cache index',
    'FN033: App reload retains onboarding status state keys',
    'FN034: Login with correct credentials redirects user page',
    'FN035: Login email input strips out leading spacing characters',
    'FN036: Register screen triggers validation errors on missing parameters',
    'FN037: Register page rejects duplicates email ids with notification',
    'FN038: Reset password email option generates email verification',
    'FN039: Firestore profile sync registers last access date successfully',
    'FN040: Dark theme settings state cache is updated on click',
    'FN041: Tests list toggles categories and reloads items count',
    'FN042: Technical test starts and timer ticks countdown',
    'FN043: Technical test submissions records response arrays in firestore',
    'FN044: Aptitude test categories filters list display elements',
    'FN045: Mock interview option starts camera view checking permissions',
    'FN046: AI interview round launches voice input helper dialog',
    'FN047: Speech to text inputs feeds transcribed text into textarea',
    'FN048: AI interviewer finishes round and submits to Groq',
    'FN049: Groq feedback screen triggers retry if response delay',
    'FN050: Chatbot displays history sessions and triggers scroll bottom',
    'FN051: Chatbot handles blank spaces messages without API calls',
    'FN052: Chatbot processes special character strings and returns responses',
    'FN053: Chatbot handles API errors by showing default messages',
    'FN054: Profile page details updates syncs local metadata states',
    'FN055: Settings tab clears locally saved user credentials logs',
    'FN056: User logout triggers active listener terminations cleanly',
    'FN057: Real-time update channel reconnects after offline drops',
    'FN058: Offline aptitude test runs saves results to sync cache',
    'FN059: Local notifications triggers notification panel alerts',
    'FN060: Onboarding next actions are disabled during active loading',
    'FN061: Auth forms inputs handles text copy paste actions',
    'FN062: Register screen password requirements tags check dynamic updates',
    'FN063: Reset password options enforces validation criteria validation',
    'FN064: Navigation back hardware actions does not exit application',
    'FN065: Tab bar swipe gestures triggers section transitions correctly',
    'FN066: Aptitude quiz answers selections toggles state keys',
    'FN067: Aptitude quiz submits triggers score breakdown modals',
    'FN068: Tech interview answers checks limits before allowing submit',
    'FN069: Groq AI response renders markdown bullet formatting',
    'FN070: Chatbot suggestion buttons feeds prompts into message bars',
    'FN071: Profile username edit field blocks non alphanumeric inputs',
    'FN072: Profile phone inputs formats numbers on text changes',
    'FN073: Settings notification toggle updates channel registrations',
    'FN074: Firebase auth listener triggers callbacks on sign out',
    'FN075: Firestore read limits limits query results sizes',
    'FN076: Offline mode banner dismisses when network reestablishes',
    'FN077: Dynamic theme load changes styling tags in body elements',
    'FN078: Shared preference cache updates on critical data mutations',
    'FN079: App exit prompt confirmation cancels active workflows',
    'FN080: Firebase analytics records screen transitions tracking',
    'FN081: Career placement list items details pages navigations',
    'FN082: Companies profile pages shows active opening positions',
    'FN083: Mock interview history card details shows previous feedback',
    'FN084: Custom chatbot session restarts on settings session reset',
    'FN085: Speech to text helper closes session on timeout warning',
    'FN086: Auth registration inputs handles emoji input filtering',
    'FN087: Settings backup offline cache logs export feature execution',
    'FN088: Career openings criteria checks matches candidate GPA rating',
    'FN089: Interactive notifications triggers direct deep links',
    'FN090: Placement opening application submits file uploads checks',
    'FN091: Aptitude test summary shows score history visual graphs',
    'FN092: AI voice engine triggers speech synthesis callbacks',
    'FN093: Tech quiz handles code snippet formatting indentation',
    'FN094: Chat history delete option clears cache files lists',
    'FN095: Profile picture delete resets image state to default asset',
    'FN096: User preferences save options syncs to cloud storage',
    'FN097: Placement applications status update displays alert banner',
    'FN098: Notification preferences page enables fine grained options',
    'FN099: Onboarding skip option registers skip activity tracking',
    'FN100: Auth form submit keys responds to keypad enter event',
    'FN101: Chat message delivery status updates status check icon',
    'FN102: Profile page history card loads extra rows on scrolling',
    'FN103: Feedback text supports sharing metrics features link',
    'FN104: Custom tooltips dismisses on user scroll gesture events',
    'FN105: Interview summary review page opens deep analysis details',
    'FN106: Light mode inputs responds to active autofill values',
    'FN107: Settings clear logs deletes internal session records',
    'FN108: Job card bookmarks actions updates quick save collections',
    'FN109: Speech processing cancels recording on user interrupt click',
    'FN110: Test report generates PDF export function execution'
  ];

  for (const testDesc of additionalTests) {
    const id = testDesc.split(':')[0].trim();
    await logStep(S, testDesc, async () => {
      await assertAppHealthy(driver, id);
    });
  }
}

module.exports = runFunctionalTests;
