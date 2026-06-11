const { By } = require('selenium-webdriver');

/**
 * Traverses Flutter Web's shadow DOM under <flt-glass-pane> to locate a semantic element.
 * Matches by aria-label, textContent, or placeholder.
 */
async function findInShadow(driver, labelText) {
  return await driver.executeScript((label) => {
    const host = document.querySelector('flt-glass-pane');
    const shadow = host ? host.shadowRoot : null;
    if (!shadow) return null;

    const elements = shadow.querySelectorAll('*');
    for (const el of elements) {
      // Match by aria-label
      const ariaLabel = el.getAttribute('aria-label');
      if (ariaLabel && ariaLabel.toLowerCase().includes(label.toLowerCase())) {
        return el;
      }
      // Match by textContent
      if (el.textContent && el.textContent.toLowerCase().includes(label.toLowerCase())) {
        return el;
      }
      // Match by placeholder
      if (el.placeholder && el.placeholder.toLowerCase().includes(label.toLowerCase())) {
        return el;
      }
    }
    return null;
  }, labelText);
}

/**
 * Finds a standard text input or textarea element inside the shadow root by placeholder or label.
 */
async function findInputField(driver, labelText) {
  return await driver.executeScript((label) => {
    const host = document.querySelector('flt-glass-pane');
    const shadow = host ? host.shadowRoot : null;
    if (!shadow) return null;

    // Look for real HTML inputs rendered by Flutter Web
    const inputs = shadow.querySelectorAll('input, textarea');
    for (const input of inputs) {
      if (input.placeholder && input.placeholder.toLowerCase().includes(label.toLowerCase())) {
        return input;
      }
    }

    // Fallback: Find semantic container, click it to activate real input, and return active element
    const elements = shadow.querySelectorAll('*');
    for (const el of elements) {
      const ariaLabel = el.getAttribute('aria-label');
      if (ariaLabel && ariaLabel.toLowerCase().includes(label.toLowerCase())) {
        el.click();
        return document.activeElement;
      }
    }
    return null;
  }, labelText);
}

module.exports = {
  findInShadow,
  findInputField,
  
  /**
   * Polls the shadow root until the element containing labelText is found or timeout is reached.
   */
  waitForElement: async function(driver, labelText, timeoutMs = 15000) {
    const start = Date.now();
    while (Date.now() - start < timeoutMs) {
      try {
        const el = await findInShadow(driver, labelText);
        if (el) return el;
      } catch (e) {
        // Ignore script execution errors during loading
      }
      await driver.sleep(500);
    }
    throw new Error(`Timeout waiting for element with label: "${labelText}"`);
  },

  /**
   * Polls the shadow root until the input field with labelText is found or timeout is reached.
   */
  waitForInputField: async function(driver, labelText, timeoutMs = 15000) {
    const start = Date.now();
    while (Date.now() - start < timeoutMs) {
      try {
        const el = await findInputField(driver, labelText);
        if (el) return el;
      } catch (e) {
        // Ignore script execution errors during loading
      }
      await driver.sleep(500);
    }
    throw new Error(`Timeout waiting for input field with label/placeholder: "${labelText}"`);
  }
};
