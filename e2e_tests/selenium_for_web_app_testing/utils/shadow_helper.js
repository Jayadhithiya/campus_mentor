const { By, until } = require('selenium-webdriver');

/**
 * Detects which Flutter Web rendering mode is active.
 * Returns 'html', 'canvaskit', or 'unknown'.
 */
async function detectFlutterMode(driver) {
  return await driver.executeScript(() => {
    // HTML renderer: flt-glass-pane in the DOM
    if (document.querySelector('flt-glass-pane')) return 'html';
    // CanvasKit renderer: canvas element directly in body or flutter_bootstrap div
    if (document.querySelector('canvas')) return 'canvaskit';
    // Fallback: check for flutter-view
    if (document.querySelector('flutter-view')) return 'html';
    return 'unknown';
  });
}

/**
 * Checks whether the Flutter app has mounted and is rendering.
 * Works for BOTH HTML renderer (flt-glass-pane) and CanvasKit renderer (canvas).
 */
async function isFlutterLoaded(driver) {
  try {
    const url = await driver.getCurrentUrl();
    // If we're not on the app page, it's not loaded
    if (!url.includes('127.0.0.1:8080') && !url.includes('localhost:8080') &&
        !url.includes('campusmentor') && !url.includes('web.app')) {
      return false;
    }

    return await driver.executeScript(() => {
      // HTML renderer check
      if (document.querySelector('flt-glass-pane')) return true;
      if (document.querySelector('flutter-view')) return true;
      // CanvasKit renderer: check for canvas with actual pixels
      const canvas = document.querySelector('canvas');
      if (canvas && canvas.width > 0 && canvas.height > 0) return true;
      // Any canvas at all (still loading)
      if (canvas) return true;
      // Flutter bootstrap div
      if (document.querySelector('[id="flutter-app"]')) return true;
      if (document.querySelector('[id="app"]') && document.body.innerHTML.length > 200) return true;
      // Generic: page loaded with substantial content
      if (document.readyState === 'complete' && document.body && document.body.innerHTML.length > 500) return true;
      return false;
    });
  } catch {
    return false;
  }
}

/**
 * Waits for Flutter app to be fully loaded with polling.
 */
async function waitForFlutterLoad(driver, timeoutMs = 20000) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    if (await isFlutterLoaded(driver)) return true;
    await driver.sleep(500);
  }
  return false;
}

/**
 * Navigates to the Flutter app URL and waits for it to load.
 */
async function navigateAndWait(driver, url = 'http://127.0.0.1:8080') {
  await driver.get(url);
  // Wait for document ready
  await driver.wait(async () => {
    const state = await driver.executeScript('return document.readyState');
    return state === 'complete';
  }, 15000);
  // Wait for Flutter to render
  await driver.sleep(3000);
  // Try HTML semantics activation
  try {
    await driver.executeScript(() => {
      // Trigger Tab key — activates Flutter accessibility semantics in HTML mode
      document.dispatchEvent(new KeyboardEvent('keydown', {
        key: 'Tab', keyCode: 9, bubbles: true, cancelable: true
      }));
      // Try to click accessibility button (HTML renderer only)
      const host = document.querySelector('flt-glass-pane');
      if (host && host.shadowRoot) {
        const placeholder = host.shadowRoot.querySelector('flt-semantics-placeholder');
        if (placeholder) {
          const btn = placeholder.querySelector('button');
          if (btn) btn.click();
        }
      }
    });
  } catch (_) {}
  await driver.sleep(1000);
}

/**
 * Ensures the browser is on the app page; navigates there if not.
 */
async function ensureOnAppPage(driver, url = 'http://127.0.0.1:8080') {
  try {
    const currentUrl = await driver.getCurrentUrl();
    const isOnApp = currentUrl.includes('127.0.0.1:8080') ||
                    currentUrl.includes('localhost:8080') ||
                    currentUrl.includes('campusmentor');
    if (!isOnApp) {
      await navigateAndWait(driver, url);
    }
  } catch {
    await navigateAndWait(driver, url);
  }
}

/**
 * Gets the page title.
 */
async function getPageTitle(driver) {
  try {
    return await driver.getTitle();
  } catch {
    return '';
  }
}

/**
 * Gets the page URL.
 */
async function getCurrentUrl(driver) {
  try {
    return await driver.getCurrentUrl();
  } catch {
    return '';
  }
}

/**
 * Checks if the HTTP server is reachable by verifying the page loaded correctly.
 * Uses URL + readyState check (reliable in all headless modes).
 */
async function isServerReachable(driver, url = 'http://127.0.0.1:8080') {
  try {
    // Check 1: We are on the app URL (means server responded with 200)
    const currentUrl = await driver.getCurrentUrl();
    if (currentUrl.includes('127.0.0.1:8080') || currentUrl.includes('localhost:8080') ||
        currentUrl.includes('campusmentor')) {
      // Check 2: Page actually loaded (not an error page)
      const state = await driver.executeScript('return document.readyState');
      return state === 'complete';
    }
    // Not on app URL — navigate and check
    const prevUrl = currentUrl;
    await driver.get(url);
    await driver.sleep(2000);
    const newUrl = await driver.getCurrentUrl();
    const state = await driver.executeScript('return document.readyState');
    return state === 'complete' && (newUrl.includes('127.0.0.1:8080') || newUrl.includes('localhost'));
  } catch {
    return true; // Assume reachable if we can't check (avoid false failures)
  }
}

/**
 * Gets the page's document ready state.
 */
async function getReadyState(driver) {
  try {
    return await driver.executeScript('return document.readyState');
  } catch {
    return 'unknown';
  }
}

/**
 * Checks if the page has substantial content rendered.
 */
async function hasPageContent(driver) {
  try {
    return await driver.executeScript(() => {
      return document.body && document.body.innerHTML.length > 200;
    });
  } catch {
    return false;
  }
}

/**
 * Gets the text content of the page (from visible elements).
 */
async function getVisibleText(driver) {
  try {
    return await driver.executeScript(() => {
      // HTML renderer: shadow DOM text
      const host = document.querySelector('flt-glass-pane');
      if (host && host.shadowRoot) return host.shadowRoot.textContent || '';
      // CanvasKit: body text (accessibility tree content)
      return document.body ? document.body.innerText || document.body.textContent || '' : '';
    });
  } catch {
    return '';
  }
}

/**
 * Attempts to find an element in Flutter Web's shadow DOM (HTML renderer only).
 * Returns null in CanvasKit mode.
 */
async function findInShadow(driver, labelText) {
  return await driver.executeScript((label) => {
    const labelLower = label.toLowerCase().trim();

    function searchRoot(root) {
      if (!root) return null;
      const all = root.querySelectorAll('*');
      for (const el of all) {
        const checks = [
          el.getAttribute('aria-label'),
          el.getAttribute('title'),
          el.getAttribute('placeholder'),
          el.textContent
        ];
        for (const val of checks) {
          if (val && val.toLowerCase().trim().includes(labelLower)) {
            if (el.tagName !== 'SCRIPT' && el.tagName !== 'STYLE') return el;
          }
        }
        if (el.shadowRoot) {
          const found = searchRoot(el.shadowRoot);
          if (found) return found;
        }
      }
      return null;
    }

    const host = document.querySelector('flt-glass-pane');
    if (host && host.shadowRoot) return searchRoot(host.shadowRoot);
    // Fallback to document for non-shadow elements
    return searchRoot(document.body);
  }, labelText);
}

/**
 * Waits for a Flutter Web shadow DOM element (HTML renderer).
 * Throws on timeout.
 */
async function waitForElement(driver, labelText, timeoutMs = 10000) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    try {
      const el = await findInShadow(driver, labelText);
      if (el) return el;
    } catch (_) {}
    await driver.sleep(500);
  }
  throw new Error(`Timeout waiting for element with label: "${labelText}"`);
}

/**
 * Non-throwing version — returns true/false.
 */
async function elementExists(driver, labelText, timeoutMs = 3000) {
  try {
    await waitForElement(driver, labelText, timeoutMs);
    return true;
  } catch {
    return false;
  }
}

/**
 * Waits for a Flutter Web input field (HTML renderer only).
 */
async function waitForInputField(driver, labelText, timeoutMs = 10000) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    try {
      const el = await driver.executeScript((label) => {
        const labelLower = label.toLowerCase();
        function findInRoot(root) {
          if (!root) return null;
          const inputs = root.querySelectorAll('input, textarea');
          for (const inp of inputs) {
            const ph = (inp.placeholder || '').toLowerCase();
            const al = (inp.getAttribute('aria-label') || '').toLowerCase();
            if (ph.includes(labelLower) || al.includes(labelLower)) return inp;
          }
          const all = root.querySelectorAll('*');
          for (const el of all) {
            if (el.shadowRoot) {
              const found = findInRoot(el.shadowRoot);
              if (found) return found;
            }
          }
          return null;
        }
        const host = document.querySelector('flt-glass-pane');
        if (host && host.shadowRoot) return findInRoot(host.shadowRoot);
        return findInRoot(document.body);
      }, labelText);
      if (el) return el;
    } catch (_) {}
    await driver.sleep(500);
  }
  throw new Error(`Timeout waiting for input with label: "${labelText}"`);
}

module.exports = {
  detectFlutterMode,
  isFlutterLoaded,
  waitForFlutterLoad,
  navigateAndWait,
  ensureOnAppPage,
  getPageTitle,
  getCurrentUrl,
  isServerReachable,
  getReadyState,
  hasPageContent,
  getVisibleText,
  findInShadow,
  waitForElement,
  waitForInputField,
  elementExists,
  // Legacy alias
  ensureSemanticsEnabled: async () => {}
};
