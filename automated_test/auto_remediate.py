"""
auto_remediate.py — Automated remediation for safe, low-risk security fixes.

Safe auto-fixes applied:
  1. Security headers → added to firebase.json hosting config
  2. Dart analyzer issues → dart fix --apply
  3. Secrets in source → flag for manual rotation; create .env.example template

Manual-fix-required findings (not auto-patched):
  - Missing auth guards (logic change)
  - Input validation gaps (logic change)
  - Insecure Firebase rules (requires Firebase Console)
  - Dependency upgrades (may introduce breaking changes)
"""

import os
import re
import json
import shutil
import subprocess
from datetime import datetime, timezone

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))


def _ts():
    return datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')


def _backup(path):
    """Create a .bak copy of file before modifying."""
    bak = path + '.dast.bak'
    if not os.path.exists(bak):
        shutil.copy2(path, bak)
    return bak


# ─────────────────────────────────────────────────────────────
# FIX 1 — Security Headers in firebase.json
# ─────────────────────────────────────────────────────────────

SECURITY_HEADERS = [
    {"key": "X-Frame-Options", "value": "SAMEORIGIN"},
    {"key": "X-Content-Type-Options", "value": "nosniff"},
    {"key": "X-XSS-Protection", "value": "1; mode=block"},
    {"key": "Referrer-Policy", "value": "strict-origin-when-cross-origin"},
    {"key": "Permissions-Policy", "value": "camera=(), microphone=(), geolocation=()"},
    {
        "key": "Content-Security-Policy",
        "value": (
            "default-src 'self'; "
            "script-src 'self' 'unsafe-inline' https://apis.google.com https://www.gstatic.com; "
            "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; "
            "font-src 'self' https://fonts.gstatic.com; "
            "img-src 'self' data: https:; "
            "connect-src 'self' https://*.googleapis.com https://*.firebaseio.com wss://*.firebaseio.com; "
            "frame-ancestors 'none';"
        ),
    },
    {"key": "Strict-Transport-Security", "value": "max-age=31536000; includeSubDomains; preload"},
]


def fix_security_headers():
    """
    Add security headers to firebase.json hosting configuration.
    Returns: dict with status, files_changed, details
    """
    firebase_json_path = os.path.join(ROOT, 'firebase.json')

    if not os.path.exists(firebase_json_path):
        return {
            'fix': 'security_headers',
            'status': 'SKIP',
            'reason': 'firebase.json not found',
            'files_changed': [],
        }

    try:
        _backup(firebase_json_path)
        with open(firebase_json_path, 'r', encoding='utf-8') as f:
            config = json.load(f)

        # Ensure hosting key exists
        if 'hosting' not in config:
            config['hosting'] = {}

        hosting = config['hosting']

        # Ensure headers list exists
        if 'headers' not in hosting:
            hosting['headers'] = []

        # Find or create the catch-all glob rule
        catch_all = None
        for rule in hosting['headers']:
            if rule.get('source') in ('**', '**/*'):
                catch_all = rule
                break

        if catch_all is None:
            catch_all = {'source': '**', 'headers': []}
            hosting['headers'].append(catch_all)

        if 'headers' not in catch_all:
            catch_all['headers'] = []

        existing_keys = {h['key'] for h in catch_all['headers']}
        added = []
        for hdr in SECURITY_HEADERS:
            if hdr['key'] not in existing_keys:
                catch_all['headers'].append(hdr)
                added.append(hdr['key'])

        with open(firebase_json_path, 'w', encoding='utf-8') as f:
            json.dump(config, f, indent=2)

        if added:
            return {
                'fix': 'security_headers',
                'status': 'APPLIED',
                'files_changed': ['firebase.json'],
                'added_headers': added,
                'details': f'Added {len(added)} security header(s): {", ".join(added)}',
            }
        else:
            return {
                'fix': 'security_headers',
                'status': 'ALREADY_PRESENT',
                'files_changed': [],
                'details': 'All security headers already configured',
            }

    except Exception as e:
        return {
            'fix': 'security_headers',
            'status': 'ERROR',
            'files_changed': [],
            'reason': str(e),
        }


# ─────────────────────────────────────────────────────────────
# FIX 2 — Dart Analyzer Auto-fix
# ─────────────────────────────────────────────────────────────

def fix_dart_analyze():
    """
    Run dart fix --apply and verify with dart analyze.
    Returns: dict with status, files_changed, details
    """
    try:
        # Step 1: run dart fix --apply
        fix_result = subprocess.run(
            ['dart', 'fix', '--apply'],
            cwd=ROOT, capture_output=True, text=True, timeout=180,
        )

        # Step 2: re-run analyzer
        verify = subprocess.run(
            ['dart', 'analyze', '--no-fatal-infos'],
            cwd=ROOT, capture_output=True, text=True, timeout=180,
        )

        if verify.returncode == 0:
            return {
                'fix': 'dart_analyze',
                'status': 'APPLIED',
                'files_changed': [],  # dart fix doesn't give us a clean list easily
                'details': 'dart fix --apply succeeded; dart analyze is now clean.',
            }
        else:
            return {
                'fix': 'dart_analyze',
                'status': 'PARTIAL',
                'files_changed': [],
                'details': (
                    f'dart fix applied but analyzer still reports issues:\n'
                    f'{(verify.stdout + verify.stderr).strip()[:800]}'
                ),
            }
    except FileNotFoundError:
        return {
            'fix': 'dart_analyze',
            'status': 'SKIP',
            'files_changed': [],
            'reason': 'dart not found in PATH',
        }
    except Exception as e:
        return {
            'fix': 'dart_analyze',
            'status': 'ERROR',
            'files_changed': [],
            'reason': str(e),
        }


# ─────────────────────────────────────────────────────────────
# FIX 3 — Secret Exposure: create .env.example + gitignore guard
# ─────────────────────────────────────────────────────────────

ENV_EXAMPLE_CONTENT = """# .env.example — copy to .env and fill in your values
# NEVER commit the real .env file to version control.

# Firebase Web Config
FIREBASE_WEB_API_KEY=your-web-api-key-here
FIREBASE_WEB_APP_ID=your-web-app-id-here
FIREBASE_WEB_MESSAGING_SENDER_ID=your-sender-id-here
FIREBASE_PROJECT_ID=your-project-id-here
FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
FIREBASE_STORAGE_BUCKET=your-project.firebasestorage.app

# Firebase Android Config
FIREBASE_ANDROID_API_KEY=your-android-api-key-here
FIREBASE_ANDROID_APP_ID=your-android-app-id-here
"""

GITIGNORE_ENTRIES = ['.env', '*.env', '.env.local', '.env.production']


def fix_secret_exposure():
    """
    Creates .env.example as a template and ensures .env is in .gitignore.
    Does NOT move keys automatically (that requires app code changes).
    Returns: dict with status, files_changed, details
    """
    files_changed = []
    actions = []

    # 1. Create .env.example if missing
    env_example_path = os.path.join(ROOT, '.env.example')
    if not os.path.exists(env_example_path):
        with open(env_example_path, 'w', encoding='utf-8') as f:
            f.write(ENV_EXAMPLE_CONTENT)
        files_changed.append('.env.example')
        actions.append('Created .env.example template')

    # 2. Ensure .env variants are in .gitignore
    gitignore_path = os.path.join(ROOT, '.gitignore')
    if os.path.exists(gitignore_path):
        _backup(gitignore_path)
        content = open(gitignore_path, encoding='utf-8').read()
        added_entries = []
        for entry in GITIGNORE_ENTRIES:
            if entry not in content:
                content += f'\n{entry}'
                added_entries.append(entry)
        if added_entries:
            with open(gitignore_path, 'w', encoding='utf-8') as f:
                f.write(content)
            files_changed.append('.gitignore')
            actions.append(f'Added to .gitignore: {", ".join(added_entries)}')

    # 3. Add a NOTE file about manual key rotation
    note_path = os.path.join(ROOT, 'automated_test', 'SECRET_ROTATION_REQUIRED.md')
    note_content = f"""# ⚠️ Secret Rotation Required

**Generated by DAST auto-remediation on {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M UTC')}**

The DAST scanner found hardcoded Firebase API keys in `lib/firebase_options.dart`.

## Action Required

1. **Rotate the Firebase API keys** in the Firebase Console:
   - Go to Project Settings → General → Web API Key
   - Regenerate the key and update your Firebase project

2. **Restrict the API keys** in Google Cloud Console:
   - Add HTTP referrer restrictions for the web key
   - Add Android app restrictions for the Android key

3. **Long-term fix** — migrate to environment variables:
   - Add `flutter_dotenv: ^5.1.0` to pubspec.yaml
   - Move keys from `firebase_options.dart` to `.env`
   - Load with `await dotenv.load()` in `main()`

## Files Containing Hardcoded Keys
- `lib/firebase_options.dart` — `apiKey` fields for web and Android

> Note: Firebase client API keys have limited security impact when restricted properly,
> but rotating them after public exposure is still recommended best practice.
"""
    os.makedirs(os.path.dirname(note_path), exist_ok=True)
    with open(note_path, 'w', encoding='utf-8') as f:
        f.write(note_content)
    files_changed.append('automated_test/SECRET_ROTATION_REQUIRED.md')
    actions.append('Created SECRET_ROTATION_REQUIRED.md with rotation instructions')

    return {
        'fix': 'secret_exposure',
        'status': 'PARTIAL',  # Keys not auto-moved (manual rotation required)
        'files_changed': files_changed,
        'details': '; '.join(actions),
        'manual_action_required': (
            'Firebase API keys found in lib/firebase_options.dart. '
            'Rotate keys in Firebase Console. See automated_test/SECRET_ROTATION_REQUIRED.md'
        ),
    }


# ─────────────────────────────────────────────────────────────
# MAIN: Apply all safe auto-fixes
# ─────────────────────────────────────────────────────────────

def apply_all_fixes(test_results):
    """
    Given the list of test results, apply auto-fixes for eligible findings.
    Returns: list of remediation records
    """
    remediation_log = []

    for finding in test_results:
        if not finding.get('auto_fixable', False):
            remediation_log.append({
                'finding_id': finding['id'],
                'auto_fixed': False,
                'fix_status': 'Manual Fix Required',
                'files_changed': [],
                'commit_sha': '',
                'pr_number': '',
                'verification_status': 'Pending Manual Review',
                'details': finding.get('recommendation', ''),
            })
            continue

        fix_result = {'status': 'SKIP', 'files_changed': [], 'details': ''}

        if finding['id'] == 'TC-SEC-001':
            fix_result = fix_secret_exposure()

        elif finding['id'] == 'TC-SEC-002':
            fix_result = fix_security_headers()

        elif finding['id'] == 'TC-SEC-005':
            fix_result = fix_dart_analyze()

        applied = fix_result['status'] in ('APPLIED', 'PARTIAL', 'ALREADY_PRESENT')
        remediation_log.append({
            'finding_id': finding['id'],
            'auto_fixed': applied,
            'fix_status': fix_result['status'],
            'files_changed': fix_result.get('files_changed', []),
            'commit_sha': '',   # filled in by github_integration.py after commit
            'pr_number': '',    # filled in by github_integration.py after PR creation
            'verification_status': 'Pending Re-test' if applied else 'Not Applicable',
            'details': fix_result.get('details', fix_result.get('reason', '')),
            'manual_action': fix_result.get('manual_action_required', ''),
        })

        icon = '✅' if applied else '⚠️ '
        print(f'  [{icon}] {finding["id"]} fix: {fix_result["status"]} — {fix_result.get("details","")[:80]}')

    return remediation_log


if __name__ == '__main__':
    print('[Remediation] Running standalone fixes...')
    print('\n--- Security Headers ---')
    r = fix_security_headers()
    print(json.dumps(r, indent=2))

    print('\n--- Secret Exposure ---')
    r = fix_secret_exposure()
    print(json.dumps(r, indent=2))

    print('\n--- Dart Analyze Fix ---')
    r = fix_dart_analyze()
    print(json.dumps(r, indent=2))
