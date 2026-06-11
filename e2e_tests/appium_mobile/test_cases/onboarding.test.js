describe('StriveCampus Onboarding Flow', () => {
  it('should swipe/navigate through onboarding and proceed to Login', async () => {
    // Wait for the first onboarding screen title to load (Accessibility ID matches the semantic label)
    const page1Title = await $('~Practice interviews with AI in your language');
    await page1Title.waitForDisplayed({ timeout: 20000 });

    // Click 'Next' button to navigate to the second page
    const nextButton = await $('~Next');
    await nextButton.click();

    // Verify page 2 title
    const page2Title = await $('~Track attendance, deadlines and marks');
    await page2Title.waitForDisplayed({ timeout: 5000 });

    // Click 'Next' again to navigate to the third page
    await nextButton.click();

    // Verify page 3 title
    const page3Title = await $('~See exactly where to improve');
    await page3Title.waitForDisplayed({ timeout: 5000 });

    // Click 'Get Started' to load the login screen
    const getStartedButton = await $('~Get Started');
    await getStartedButton.click();

    // Verify the login screen is active by searching for the email input field
    // In Flutter Android, inputs map to android.widget.EditText
    const emailInput = await $('android=new UiSelector().className("android.widget.EditText").instance(0)');
    await emailInput.waitForDisplayed({ timeout: 10000 });
  });
});
