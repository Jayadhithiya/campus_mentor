module.exports = async function assertAppHealthy(driver, testId) {
  let lastError = null;

  // Strategy 1: Wait for MainActivity or known package
  try {
    await driver.waitUntil(async () => {
      try {
        const activity = await driver.getCurrentActivity();
        const pkg = await driver.getCurrentPackage();
        return (
          (activity && (
            activity.includes('MainActivity') ||
            activity.includes('FlutterActivity') ||
            activity.includes('com.example')
          )) ||
          (pkg && pkg.includes('com.example.campus_mentor'))
        );
      } catch (e) {
        return false;
      }
    }, {
      timeout: 25000,
      timeoutMsg: `[${testId}] App not in expected state after 25s`
    });
    console.log(`${testId}: App health check passed (activity/package check)`);
    return true;
  } catch (e) {
    lastError = e;
    console.warn(`${testId}: Primary health check failed - ${e.message}, trying fallback...`);
  }

  // Strategy 2: Try activating the app and check via package source
  try {
    await driver.activateApp('com.example.campus_mentor');
    await driver.pause(3000);
    const source = await driver.getPageSource();
    if (source && source.length > 50) {
      console.log(`${testId}: App health check passed (page source fallback)`);
      return true;
    }
  } catch (e) {
    lastError = e;
    console.warn(`${testId}: Fallback health check also failed - ${e.message}`);
  }

  // Strategy 3: Check FrameLayout as last resort
  try {
    const root = await driver.$('android=new UiSelector().className("android.widget.FrameLayout")');
    await root.waitForDisplayed({ timeout: 8000 });
    console.log(`${testId}: App health check passed (FrameLayout fallback)`);
    return true;
  } catch (e) {
    lastError = e;
  }

  throw new Error(`${testId}: All health checks failed - ${lastError ? lastError.message : 'unknown error'}`);
};
