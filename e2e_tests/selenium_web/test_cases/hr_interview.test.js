const { waitForElement, waitForInputField } = require('../utils/shadow_helper');

/**
 * Automates the Mock HR Interview flow.
 */
async function runHRInterviewTests(driver, logStep) {
  const testCase = 'AI Mock Interview Flow';

  await logStep(testCase, 'Navigate to Tests Tab', async () => {
    const testsTab = await waitForElement(driver, 'Tests', 10000);
    await testsTab.click();
  });

  await logStep(testCase, 'Switch to HR Sub-tab', async () => {
    const hrTab = await waitForElement(driver, 'HR', 5000);
    await hrTab.click();
  });

  await logStep(testCase, 'Select HR Round Interview Card', async () => {
    const hrRoundCard = await waitForElement(driver, 'HR Round', 5000);
    await hrRoundCard.click();
  });

  await logStep(testCase, 'Configure Question Count (Decrease to 5)', async () => {
    const minusButton = await waitForElement(driver, 'remove', 5000);
    if (minusButton) {
      await minusButton.click();
    }
  });

  await logStep(testCase, 'Click Start Interview', async () => {
    const startButton = await waitForElement(driver, 'Start Interview', 5000);
    await startButton.click();
  });

  await logStep(testCase, 'Verify Questions Loaded and Input Active', async () => {
    // Wait for the AI interviewer to generate questions (up to 20 seconds)
    const answerInput = await waitForInputField(driver, 'Type your answer', 20000);
    if (!answerInput) throw new Error('Answer input text field not found on Interview screen.');
  });

  await logStep(testCase, 'Submit Answer to First Question', async () => {
    const answerInput = await waitForInputField(driver, 'Type your answer', 5000);
    await answerInput.sendKeys('I am a passionate software engineer with experience in Flutter development. I love building scalable applications and solving complex problems.');
    
    const submitBtn = await waitForElement(driver, 'Submit Answer', 5000);
    await submitBtn.click();
  });

  await logStep(testCase, 'Verify AI Evaluation Score & Feedback', async () => {
    // Wait for the AI to complete evaluation and render the feedback card (up to 15 seconds)
    const aiFeedbackHeader = await waitForElement(driver, 'AI Feedback', 15000);
    if (!aiFeedbackHeader) throw new Error('AI Feedback section not rendered. Evaluation failed.');
  });

  await logStep(testCase, 'End Interview Early (Quit Interview)', async () => {
    const closeIcon = await waitForElement(driver, 'close', 5000);
    await closeIcon.click();

    const confirmQuit = await waitForElement(driver, 'Quit', 5000);
    await confirmQuit.click();
    await driver.sleep(2000); // Navigation delay back to Dashboard
  });
}

module.exports = runHRInterviewTests;
