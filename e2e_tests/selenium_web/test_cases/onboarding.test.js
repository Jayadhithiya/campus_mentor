const { waitForElement } = require('../utils/shadow_helper');
const { until } = require('selenium-webdriver');

/**
 * Automates the onboarding screen flows.
 */
async function runOnboardingTests(driver, logStep) {
  const testCase = 'Onboarding Flow';

  await logStep(testCase, 'Navigate to Web Application URL', async () => {
    await driver.get('https://campusmentor-2485c.web.app');
    await driver.wait(until.elementLocated({ css: 'flt-glass-pane' }), 20000);
  });

  await logStep(testCase, 'Verify Onboarding Title Text', async () => {
    // Wait for splash screen timer to finish (3 seconds in app + boot time)
    const title = await waitForElement(driver, 'Practice interviews with AI', 15000);
    if (!title) throw new Error('Onboarding screen title not found.');
  });

  await logStep(testCase, 'Navigate to Onboarding Page 2', async () => {
    const nextButton = await waitForElement(driver, 'Next');
    await nextButton.click();
    await driver.sleep(1000); // Allow time for transition
  });

  await logStep(testCase, 'Verify Onboarding Page 2 Title', async () => {
    const title = await waitForElement(driver, 'Track attendance');
    if (!title) throw new Error('Page 2 onboarding title not found.');
  });

  await logStep(testCase, 'Navigate to Onboarding Page 3', async () => {
    const nextButton = await waitForElement(driver, 'Next');
    await nextButton.click();
    await driver.sleep(1000);
  });

  await logStep(testCase, 'Verify Onboarding Page 3 Title', async () => {
    const title = await waitForElement(driver, 'See exactly where to improve');
    if (!title) throw new Error('Page 3 onboarding title not found.');
  });

  await logStep(testCase, 'Click Get Started to load Login Page', async () => {
    const getStarted = await waitForElement(driver, 'Get Started');
    await getStarted.click();
    await driver.sleep(2000); // Navigation delay
  });
}

module.exports = runOnboardingTests;
