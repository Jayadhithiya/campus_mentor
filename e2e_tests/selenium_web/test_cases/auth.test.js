const { waitForElement, waitForInputField } = require('../utils/shadow_helper');

const testCase = 'Authentication Flow';

/**
 * Automates the Login (Registration) flow.
 */
async function runLoginTests(driver, logStep) {
  // We assume the browser is currently showing the Login Screen after the Onboarding flow completes.
  
  await logStep(testCase, 'Click Sign Up Link', async () => {
    // Navigate to the Registration screen
    const signUpLink = await waitForElement(driver, 'Sign up', 10000);
    await signUpLink.click();
    await driver.sleep(1000); // Wait for transition
  });

  await logStep(testCase, 'Enter Registration Details', async () => {
    // Enter First Name
    const firstName = await waitForInputField(driver, 'Jay', 5000);
    await firstName.sendKeys('Test');

    // Enter Last Name
    const lastName = await waitForInputField(driver, 'Adhithiya', 5000);
    await lastName.sendKeys('Student');

    // Enter unique Email
    const emailField = await waitForInputField(driver, 'jay@college.edu', 5000);
    const uniqueEmail = `teststudent_${Date.now()}@strive.edu`;
    console.log(`[TEST DETAILS] Registering unique test account: ${uniqueEmail}`);
    await emailField.sendKeys(uniqueEmail);

    // Enter Password
    const passwordField = await waitForInputField(driver, 'Min. 6 characters', 5000);
    await passwordField.sendKeys('password123');
  });

  await logStep(testCase, 'Click Create Account Button', async () => {
    const createBtn = await waitForElement(driver, 'Create my account', 5000);
    await createBtn.click();
    await driver.sleep(6000); // Wait for account creation, Firebase Firestore doc setup, and dashboard loading
  });

  await logStep(testCase, 'Verify Successful Navigation to Home Tab', async () => {
    // Wait for the Dashboard title to load after login completes
    const homeTitle = await waitForElement(driver, 'Home', 15000);
    if (!homeTitle) throw new Error('Home dashboard indicator not found. Registration/Login failed.');
  });
}

/**
 * Automates the Logout flow.
 */
async function runLogoutTests(driver, logStep) {
  await logStep(testCase, 'Navigate to Profile Tab', async () => {
    const profileTab = await waitForElement(driver, 'Profile', 10000);
    await profileTab.click();
    await driver.sleep(1000);
  });

  await logStep(testCase, 'Verify Profile Screen Loads', async () => {
    const myProfileHeader = await waitForElement(driver, 'My Profile', 5000);
    if (!myProfileHeader) throw new Error('My Profile screen header not found.');
  });

  await logStep(testCase, 'Click Sign Out Button', async () => {
    const signOutButton = await waitForElement(driver, 'Sign Out', 5000);
    await signOutButton.click();
  });

  await logStep(testCase, 'Confirm Sign Out in Dialog', async () => {
    const confirmSignOut = await waitForElement(driver, 'Sign Out', 5000);
    await confirmSignOut.click();
    await driver.sleep(2000); // Navigation delay back to onboarding/login
  });
}

module.exports = {
  runLoginTests,
  runLogoutTests
};
