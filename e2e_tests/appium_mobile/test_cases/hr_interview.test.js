describe('StriveCampus AI Mock Interview Flow', () => {
  it('should navigate to Tests tab and start an HR mock interview session', async () => {
    // Navigate to Tests tab
    const testsTab = await $('~Tests');
    await testsTab.click();

    // Switch to HR sub-tab
    const hrTab = await $('~HR');
    await hrTab.waitForDisplayed({ timeout: 5000 });
    await hrTab.click();

    // Choose the HR Round card
    const hrRoundCard = await $('~HR Round');
    await hrRoundCard.waitForDisplayed({ timeout: 5000 });
    await hrRoundCard.click();

    // Click on Start Interview button
    const startButton = await $('~Start Interview');
    await startButton.waitForDisplayed({ timeout: 5000 });
    await startButton.click();

    // Wait for the AI interviewer to generate questions (EditText field is displayed)
    const answerInput = await $('android=new UiSelector().className("android.widget.EditText")');
    await answerInput.waitForDisplayed({ timeout: 25000 });

    // Enter mock response
    await answerInput.setValue('I have developed strong problem-solving skills through college projects in Flutter. I am a team player who is eager to learn new technologies.');

    // Click Submit Answer to trigger AI evaluation
    const submitButton = await $('~Submit Answer ➔ Get Feedback');
    await submitButton.click();

    // Wait for AI feedback results card to render on screen
    const aiFeedbackHeader = await $('~AI Feedback');
    await aiFeedbackHeader.waitForDisplayed({ timeout: 15000 });

    // Click close/exit icon to abort the interview
    const closeButton = await $('~close');
    await closeButton.click();

    // Confirm quitting the session
    const quitButton = await $('~Quit');
    await quitButton.click();

    // Verify returning back to Tests dashboard
    await hrTab.waitForDisplayed({ timeout: 5000 });
  });
});
