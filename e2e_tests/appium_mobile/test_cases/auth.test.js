describe('StriveCampus Authentication Flow', () => {
  it('should sign in using email and password', async () => {
    // Locate the first input field (Email) and second input field (Password)
    const emailField = await $('android=new UiSelector().className("android.widget.EditText").instance(0)');
    const passwordField = await $('android=new UiSelector().className("android.widget.EditText").instance(1)');

    // Enter values
    await emailField.setValue('teststudent@strive.edu');
    await passwordField.setValue('password123');

    // Click on the 'Sign in' button
    const signInButton = await $('~Sign in');
    await signInButton.click();

    // Wait for the Dashboard to load by verifying that the Home tab icon is displayed
    const homeTab = await $('~Home');
    await homeTab.waitForDisplayed({ timeout: 15000 });
  });

  it('should navigate to the Profile tab and sign out', async () => {
    // Click on the Profile navigation item
    const profileTab = await $('~Profile');
    await profileTab.click();

    // Verify profile header has loaded
    const profileHeader = await $('~My Profile');
    await profileHeader.waitForDisplayed({ timeout: 5000 });

    // Click Sign Out
    const signOutButton = await $('~Sign Out');
    await signOutButton.click();

    // Confirm sign out on dialog popup
    const confirmButton = await $('~Sign Out');
    await confirmButton.click();

    // Verify redirected back to Login screen
    const emailField = await $('android=new UiSelector().className("android.widget.EditText").instance(0)');
    await emailField.waitForDisplayed({ timeout: 10000 });
  });
});
