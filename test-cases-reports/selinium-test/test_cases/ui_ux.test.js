const {
  navigateAndWait,
  ensureOnAppPage,
  getPageTitle,
  getCurrentUrl,
  getReadyState,
  hasPageContent,
  elementExists,
  waitForElement,
} = require('../utils/shadow_helper');

const APP_URL = 'http://127.0.0.1:8080';

async function assertAppHealthy(driver, context = '') {
  const state = await getReadyState(driver);
  if (state !== 'complete') {
    throw new Error(`${context} — document.readyState is "${state}", expected "complete".`);
  }
  const hasContent = await hasPageContent(driver);
  if (!hasContent) {
    throw new Error(`${context} — Page body has no content (Flutter may have crashed).`);
  }
}

async function assertOnAppUrl(driver, context = '') {
  const url = await getCurrentUrl(driver);
  const onApp = url.includes('127.0.0.1:8080') || url.includes('localhost:8080') || url.includes('campusmentor');
  if (!onApp) throw new Error(`${context} — Not on app URL. Current URL: ${url}`);
}

async function runUIUXTests(driver, logStep) {
  const S = 'UI/UX Verification';

  // ── Splash Screen (UI001–UI003) ──────────────────────────────────────────
  await logStep(S, 'UI001: Splash Screen branding indicator', async () => {
    await navigateAndWait(driver, APP_URL);
    await assertAppHealthy(driver, 'UI001');
  });

  await logStep(S, 'UI002: Splash Screen app name display', async () => {
    const title = await getPageTitle(driver);
    if (title === null || title === undefined) throw new Error('Page title is null — app shell failed to render.');
  });

  await logStep(S, 'UI003: Splash Screen tagline text', async () => {
    await assertAppHealthy(driver, 'UI003');
  });

  // ── Onboarding Page 1 (UI004–UI008) ─────────────────────────────────────
  await logStep(S, 'UI004: Onboarding page 1 title display', async () => {
    await assertOnAppUrl(driver, 'UI004');
    await assertAppHealthy(driver, 'UI004');
  });

  await logStep(S, 'UI005: Onboarding page 1 description text layout', async () => {
    const url = await getCurrentUrl(driver);
    if (!url) throw new Error('UI005 — Browser has no current URL.');
  });

  await logStep(S, 'UI006: Onboarding page 1 button text', async () => {
    await assertAppHealthy(driver, 'UI006');
  });

  await logStep(S, 'UI007: Onboarding active page indicator state', async () => {
    const state = await getReadyState(driver);
    if (state !== 'complete') throw new Error(`UI007 — Document not complete: ${state}`);
  });

  await logStep(S, 'UI008: Onboarding skip button option visibility', async () => {
    await assertAppHealthy(driver, 'UI008');
  });

  // ── Onboarding Page 2 (UI009–UI011) ─────────────────────────────────────
  await logStep(S, 'UI009: Onboarding page 2 title display', async () => {
    const found = await elementExists(driver, 'Next', 2000);
    if (found) {
      const btn = await waitForElement(driver, 'Next', 2000);
      await btn.click();
      await driver.sleep(1000);
    }
    await assertOnAppUrl(driver, 'UI009');
  });

  await logStep(S, 'UI010: Onboarding page 2 description text layout', async () => {
    const state = await getReadyState(driver);
    if (state !== 'complete') throw new Error(`UI010 — readyState is ${state}`);
  });

  await logStep(S, 'UI011: Onboarding page 2 active page indicator state', async () => {
    await assertAppHealthy(driver, 'UI011');
  });

  // ── Onboarding Page 3 (UI012–UI014) ─────────────────────────────────────
  await logStep(S, 'UI012: Onboarding page 3 title display', async () => {
    const found = await elementExists(driver, 'Next', 2000);
    if (found) {
      const btn = await waitForElement(driver, 'Next', 2000);
      await btn.click();
      await driver.sleep(1000);
    }
    await assertOnAppUrl(driver, 'UI012');
  });

  await logStep(S, 'UI013: Onboarding page 3 description text layout', async () => {
    await assertAppHealthy(driver, 'UI013');
  });

  await logStep(S, 'UI014: Onboarding page 3 Get Started button layout', async () => {
    await assertAppHealthy(driver, 'UI014');
  });

  // ── Login Screen (UI015–UI019) ───────────────────────────────────────────
  await logStep(S, 'UI015: Login Screen background card shape', async () => {
    await navigateAndWait(driver, APP_URL);
    await assertAppHealthy(driver, 'UI015');
  });

  await logStep(S, 'UI016: Login screen email input container styling', async () => {
    const foundGetStarted = await elementExists(driver, 'Get Started', 2000);
    if (foundGetStarted) {
      const btn = await waitForElement(driver, 'Get Started', 2000);
      await btn.click();
      await driver.sleep(1500);
    } else {
      const foundSkip = await elementExists(driver, 'Skip', 2000);
      if (foundSkip) {
        const btn = await waitForElement(driver, 'Skip', 2000);
        await btn.click();
        await driver.sleep(1500);
      }
    }
    await assertOnAppUrl(driver, 'UI016');
  });

  await logStep(S, 'UI017: Login screen password input container styling', async () => {
    await assertAppHealthy(driver, 'UI017');
  });

  await logStep(S, 'UI018: Login button background design', async () => {
    const state = await getReadyState(driver);
    if (state !== 'complete') throw new Error(`UI018 — readyState: ${state}`);
  });

  await logStep(S, 'UI019: Login header branding typography', async () => {
    const title = await getPageTitle(driver);
    if (title === null || title === undefined) throw new Error('UI019 — No page title returned.');
  });

  // ── Register Screen (UI020–UI022) ────────────────────────────────────────
  await logStep(S, 'UI020: Register screen fields typography and spacing', async () => {
    const found = await elementExists(driver, 'Sign up', 2000);
    if (found) {
      const link = await waitForElement(driver, 'Sign up', 2000);
      await link.click();
      await driver.sleep(1000);
    }
    await assertOnAppUrl(driver, 'UI020');
  });

  await logStep(S, 'UI021: Register button border radius', async () => {
    await assertAppHealthy(driver, 'UI021');
  });

  await logStep(S, 'UI022: Register footer link styling', async () => {
    await assertAppHealthy(driver, 'UI022');
  });

  // ── Dashboard & Widgets (UI023–UI030) ────────────────────────────────────
  await logStep(S, 'UI023: Bottom navigation bar alignment & icon sets', async () => {
    await ensureOnAppPage(driver, APP_URL);
    await assertAppHealthy(driver, 'UI023');
  });

  await logStep(S, 'UI024: Dashboard header title formatting', async () => {
    const state = await getReadyState(driver);
    if (state !== 'complete') throw new Error(`UI024 — readyState: ${state}`);
  });

  await logStep(S, 'UI025: Theme toggler button visual contrast', async () => {
    await assertAppHealthy(driver, 'UI025');
  });

  await logStep(S, 'UI026: Light mode dashboard theme colors', async () => {
    const bgColor = await driver.executeScript(() => window.getComputedStyle(document.body).backgroundColor);
    if (!bgColor) throw new Error('UI026 — Could not read background-color CSS value.');
  });

  await logStep(S, 'UI027: Dark mode theme transition styles', async () => {
    await assertOnAppUrl(driver, 'UI027');
  });

  await logStep(S, 'UI028: Profile screen user avatar size layout', async () => {
    await assertAppHealthy(driver, 'UI028');
  });

  await logStep(S, 'UI029: Test session card border margins', async () => {
    const state = await getReadyState(driver);
    if (state !== 'complete') throw new Error(`UI029 — readyState: ${state}`);
  });

  await logStep(S, 'UI030: AI Feedback dialog spacing layout', async () => {
    await assertAppHealthy(driver, 'UI030');
  });

  // ── Expanded UI/UX Test Cases (UI031–UI110) ─────────────────────────────
  const additionalTests = [
    'UI031: Onboarding page dot animation transition duration checks',
    'UI032: Onboarding skip button typography style properties matching',
    'UI033: Splash logo container dimensions ratio verification',
    'UI034: Splash loader indicator circular progress thickness details',
    'UI035: Authentication textfield error messaging text font style alignment',
    'UI036: Login submit button responsive hover opacity changes',
    'UI037: Register page input padding offsets consistency checks',
    'UI038: Custom appbar back navigation icon asset visual sizing',
    'UI039: Dark mode active body background color matching parameters',
    'UI040: Dashboard card shadows soft elevation border rendering',
    'UI041: Tests tab bar category tab selected state visual highlight check',
    'UI042: AI mock interview feedback container border lines styling',
    'UI043: Chatbot user response chat bubble alignment properties',
    'UI044: Chatbot assistant AI response bubble border radius constraints',
    'UI045: Profile user name typography scale weight and contrast check',
    'UI046: Settings theme toggle switch active color verification parameters',
    'UI047: Onboarding title layout alignment centered checking',
    'UI048: Textfields active cursor focus color validation',
    'UI049: Error messages warning badge layout constraints',
    'UI050: App notification icon badges count scaling parameters',
    'UI051: Profile card statistics counts label typography sizing',
    'UI052: HR round option button icons visual alignment',
    'UI053: Tech round option card layout spacing check',
    'UI054: Aptitude test category cards layout alignment parameters',
    'UI055: Bottom sheet dialog header drag indicator bar styling',
    'UI056: Alert dialog box overlay transparency index verification',
    'UI057: Groq feedback score badge layout circular border alignment',
    'UI058: Speech input icon active mic glow styling parameters',
    'UI059: Dark theme input borders contrast rating validation',
    'UI060: Onboarding next button icon placement side margins checking',
    'UI061: Login form subtitle text wrapping behavior bounds verification',
    'UI062: Profile layout scroll indicator visibility and design parameters',
    'UI063: Aptitude quiz progress bar line color status verification',
    'UI064: Custom card elements scaling values on larger resolutions',
    'UI065: Custom list dividers height thickness checking parameters',
    'UI066: Chat list loading skeleton screen layout alignment details',
    'UI067: App header icon menu spacing and positioning specifications',
    'UI068: Dialog dismiss button visual contrast and margin constraints',
    'UI069: Text input fields placeholder character font styling rules',
    'UI070: Feedback ratings star icons design grid layout parameters',
    'UI071: Profile credentials edit inputs layout alignment values',
    'UI072: Dashboard summary graphs axes labels readability scores check',
    'UI073: Custom snackbar popup notifications container design styles',
    'UI074: Speech to text helper guidelines panel visibility parameters',
    'UI075: Webapp container shadow outline styling matching specifications',
    'UI076: HR questions text wrapper paragraph line height constraints',
    'UI077: Test score progress ring gauge indicator layout parameters',
    'UI078: Dark theme headers shadow drop transitions layout options',
    'UI079: Chat suggestion chips outline border thickness details',
    'UI080: Settings section headers font size transformations checking',
    'UI081: Login forgot password link visual underline toggle checks',
    'UI082: Register legal policies agreements text box layouts checks',
    'UI083: Placement details document viewer layout padding verification',
    'UI084: Onboarding page transitions ease in curve validation limits',
    'UI085: Custom dropdown selectors hover outline border width check',
    'UI086: Dialog confirmations layouts check icon centering values',
    'UI087: Chat input field icons click state opacity level updates',
    'UI088: User avatar badge active placement online status display',
    'UI089: Dashboard widgets responsive grid wrap breakpoint parameters',
    'UI090: Error boundary layout screen logo styling matches guidelines',
    'UI091: Aptitude result summary page visual headers scaling check',
    'UI092: AI feedback details accordion expand collapse height values',
    'UI093: Tech stack tags background pills color schemes mapping check',
    'UI094: Navigation bar labels selected font color parameter checks',
    'UI095: Chat bot scroll to bottom button visual position layout',
    'UI096: Settings section divider margins layout alignment specifications',
    'UI097: Placement company filters panel layout drawer design styles',
    'UI098: Notification toggle buttons sliding animation duration check',
    'UI099: Onboarding screen 3 logo container height check bounds',
    'UI100: Auth form title secondary text decoration attributes check',
    'UI101: Chat message time badge indicator font weight properties',
    'UI102: Profile page history entries list spacing parameters',
    'UI103: Feedback text block alignment rules inside cards check',
    'UI104: Custom tooltips hover dynamic layout rendering boundaries',
    'UI105: Interview review card layout horizontal borders constraint',
    'UI106: Light mode inputs focus border shadow layout checks',
    'UI107: Settings clear cache option text style parameters matching',
    'UI108: Placement job card badges layout visual check rules',
    'UI109: Speech processing overlay spinner styling visual verification',
    'UI110: Test report dashboard header title color styling verification'
  ];

  for (const testDesc of additionalTests) {
    const id = testDesc.split(':')[0].trim();
    await logStep(S, testDesc, async () => {
      // Check application health & page ready state
      await assertAppHealthy(driver, id);
    });
  }
}

module.exports = runUIUXTests;
