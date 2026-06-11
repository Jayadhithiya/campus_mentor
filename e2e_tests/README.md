# StriveCampus End-to-End (E2E) Test Suite 🧪

This directory contains the automated End-to-End testing suites for the StriveCampus application, divided into:
1. **Web E2E Tests**: Selenium WebdriverJS tests that generate a styled Excel analytics report and capture failure screenshots.
2. **Mobile E2E Tests**: Appium & WebdriverIO tests that target Android mobile devices/emulators.

---

## 📂 Project Structure

```
e2e_tests/
  ├── package.json
  ├── README.md                          <-- You are here
  ├── selenium_web/
  │    ├── test_cases/
  │    │     ├── onboarding.test.js      # Onboarding transitions
  │    │     ├── auth.test.js            # Email Login & Logout
  │    │     └── hr_interview.test.js    # AI Interview simulation & exit
  │    ├── utils/
  │    │     ├── excel_reporter.js       # Excel report builder
  │    │     └── shadow_helper.js        # Traverses Flutter Web shadow DOM
  │    ├── screenshots/                  # Failure screenshots (auto-created)
  │    └── run_web_tests.js              # Selenium runner script
  └── appium_mobile/
       ├── test_cases/
       │     ├── onboarding.test.js      # Mobile onboarding swipes
       │     ├── auth.test.js            # Mobile Login & Logout
       │     └── hr_interview.test.js    # Mobile Interview simulation
       ├── config/
       │     └── wdio.conf.js            # WebdriverIO Appium config
       └── run_mobile_tests.js           # Appium runner script
```

---

## 🛠️ Setup Instructions

### 1. Install Node.js Dependencies
Navigate to the `e2e_tests/` directory and install the packages:
```bash
cd e2e_tests
npm install
```

---

## 🌐 Running Web Tests (Selenium)

The web tests automate the hosted application at `https://campusmentor-2485c.web.app/` using local Chrome.

### Pre-requisites:
- Google Chrome browser installed.
- ChromeDriver (Selenium automatically handles ChromeDriver matching on modern Webdriver versions, so no manual driver installation is needed).

### Execution:
To start the tests, run:
```bash
npm run test:web
```

### Output:
1. **Excel Report**: Upon completion, a beautifully formatted report is generated at `e2e_tests/selenium_web_report.xlsx`. It includes:
   - **Summary Dashboard**: Statistics showing Total steps, Passes, Failures, and Success Rate.
   - **Detailed Test Log**: Itemized logging for each test step, durations, and error descriptions.
2. **Failure Screenshots**: If any step fails, a screenshot of the browser state is automatically saved under `e2e_tests/selenium_web/screenshots/`.

---

## 📱 Running Mobile Tests (Appium)

The mobile tests are configured to launch WebdriverIO and Appium to automate the Android build.

### Pre-requisites:
1. **Appium Server**: Install globally:
   ```bash
   npm install -g appium
   ```
2. **Android UIAutomator2 Driver**: Install the Appium driver:
   ```bash
   appium driver install uiautomator2
   ```
3. **Android SDK & Emulator**: Set up your Android emulator or connect a physical device, and ensure `adb devices` lists the device.
4. **App Build**: Compile the release APK of StriveCampus and place it at the root of `e2e_tests` as `app-release.apk` (or update the path in `appium_mobile/config/wdio.conf.js`).
   ```bash
   # From root project folder:
   flutter build apk --release
   # Copy build/app/outputs/flutter-apk/app-release.apk to e2e_tests/app-release.apk
   ```

### Execution:
1. Start your Appium server on default port `4723`:
   ```bash
   appium
   ```
2. In a separate terminal tab inside `e2e_tests`, run:
   ```bash
   npm run test:mobile
   ```
