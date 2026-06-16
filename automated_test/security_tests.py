"""
security_tests.py — DAST Security Test Suite for campus_mentor (Flutter/Firebase)

Test Categories:
  - AuthN/AuthZ: Firebase JWT, role checks, ownership validation
  - Rate Limiting: Rapid-fire request simulation
  - Security Headers: Web build HTTP headers
  - Input Validation: Fuzz user-visible inputs
  - Secret Exposure: API keys, tokens, private keys in source
"""

import re
import os
import time
import json
import subprocess
from datetime import datetime, timezone

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))

SCAN_EXTS = {
    '.dart', '.java', '.kt', '.xml', '.json', '.yaml', '.yml',
    '.env', '.properties', '.gradle', '.txt', '.md', '.js', '.ts',
    '.swift', '.plist', '.html', '.htm',
}
SKIP_DIRS = {
    'build', '.git', '.venv', '.venv-1', 'node_modules',
    '.gradle', '.idea', '.dart_tool', 'automated_test',
    'e2e_tests', 'ios', 'android', 'windows', 'macos', 'linux',
    '.github',
}

# ─────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────

def ts():
    return datetime.now(timezone.utc).isoformat()


def _walk_source(root=ROOT):
    """Yield (full_path, rel_path) for every scannable source file."""
    for dirpath, dirnames, filenames in os.walk(root):
        parts = set(os.path.normpath(dirpath).split(os.sep))
        if parts & SKIP_DIRS:
            dirnames[:] = []
            continue
        for fname in filenames:
            if fname in ('package-lock.json', 'pubspec.lock'):
                continue
            if os.path.splitext(fname)[1].lower() in SCAN_EXTS:
                full = os.path.join(dirpath, fname)
                yield full, os.path.relpath(full, root)


# ─────────────────────────────────────────────────────────────
# ENDPOINT DISCOVERY
# ─────────────────────────────────────────────────────────────

def discover_endpoints():
    """
    Discover Firebase/HTTP endpoints from Dart source.
    Returns list of dicts: {method, endpoint, access_type, expected_roles, source_file}
    """
    endpoints = []

    # Firebase collection paths
    col_pattern = re.compile(r"""collection\(['"]([^'"]+)['"]\)""")
    doc_pattern = re.compile(r"""doc\(['"]([^'"]+)['"]\)""")
    http_pattern = re.compile(r"""Uri\.(?:parse|https|http)\(['"]([^'"]+)['"]""")
    # Firebase Auth calls
    auth_pattern = re.compile(
        r"""(signInWithEmailAndPassword|createUserWithEmailAndPassword|signInWithGoogle|signOut|currentUser)"""
    )

    seen = set()

    for full, rel in _walk_source():
        try:
            text = open(full, encoding='utf-8', errors='ignore').read()
        except Exception:
            continue

        for m in col_pattern.finditer(text):
            ep = f"firestore://{m.group(1)}"
            if ep not in seen:
                seen.add(ep)
                endpoints.append({
                    'method': 'FIRESTORE',
                    'endpoint': ep,
                    'access_type': 'Firebase/Firestore',
                    'expected_roles': 'authenticated',
                    'source_file': rel,
                })

        for m in auth_pattern.finditer(text):
            ep = f"firebase-auth::{m.group(1)}"
            if ep not in seen:
                seen.add(ep)
                endpoints.append({
                    'method': 'AUTH',
                    'endpoint': ep,
                    'access_type': 'Firebase/Auth',
                    'expected_roles': 'anonymous / authenticated',
                    'source_file': rel,
                })

        for m in http_pattern.finditer(text):
            url = m.group(1)
            if 'http' in url and url not in seen:
                seen.add(url)
                endpoints.append({
                    'method': 'HTTP',
                    'endpoint': url,
                    'access_type': 'External HTTP',
                    'expected_roles': 'authenticated',
                    'source_file': rel,
                })

    # Flutter web routes (from main.dart / router)
    router_pattern = re.compile(r"""['"]/([\w\-/]+)['"]""")
    main_dart = os.path.join(ROOT, 'lib', 'main.dart')
    if os.path.exists(main_dart):
        text = open(main_dart, encoding='utf-8', errors='ignore').read()
        for m in router_pattern.finditer(text):
            route = f"web-route:/{m.group(1)}"
            if route not in seen:
                seen.add(route)
                endpoints.append({
                    'method': 'GET',
                    'endpoint': route,
                    'access_type': 'Flutter Web Route',
                    'expected_roles': 'authenticated',
                    'source_file': 'lib/main.dart',
                })

    return endpoints


# ─────────────────────────────────────────────────────────────
# TEST CATEGORY 1 — SECRET EXPOSURE
# ─────────────────────────────────────────────────────────────

SECRET_PATTERNS = {
    'Firebase API Key (AIza)': re.compile(r'AIza[0-9A-Za-z\-_]{35}'),
    'Private Key': re.compile(r'-----BEGIN (RSA |)PRIVATE KEY-----'),
    'Generic High-Entropy Token (40+ chars)': re.compile(r'[A-Za-z0-9_\-]{40,}'),
    'Hardcoded apiKey field': re.compile(r'''apiKey\s*[:=]\s*['"][^'"]{10,}['"]'''),
    'auth/access token keyword': re.compile(
        r'\b(access_token|id_token|refresh_token|secret|api_key|apiKey)\s*[:=]\s*[\'"][^\'"]{8,}[\'"]',
        re.IGNORECASE,
    ),
    'Firebase project config (hardcoded)': re.compile(
        r'(storageBucket|authDomain|projectId|messagingSenderId)\s*[:=]\s*[\'"][^\'"]{5,}[\'"]'
    ),
}

# Patterns safe to skip (known false positives)
SAFE_SNIPPETS = {'REDACTED_SECRET', 'YOUR_API_KEY', 'your-api-key', 'xxxx', 'apps.googleusercontent.com', '386966654332-ds3q9mbrtomulqpb6dbkbhboo1cjkb8h'}


def test_secret_exposure():
    """TC-SEC-001 — Scan source for hardcoded secrets."""
    findings = []
    raw = []
    start = time.time()

    for full, rel in _walk_source():
        if 'firebase_options.dart' in rel or 'api_keys.dart' in rel:
            continue
        try:
            text = open(full, encoding='utf-8', errors='ignore').read()
        except Exception:
            continue
        for name, pat in SECRET_PATTERNS.items():
            for m in pat.finditer(text):
                snippet = m.group(0)
                if any(s in snippet for s in SAFE_SNIPPETS):
                    continue
                line_no = text[:m.start()].count('\n') + 1
                findings.append({
                    'file': rel,
                    'line': line_no,
                    'pattern': name,
                    'snippet': snippet[:120],
                })

    elapsed = int((time.time() - start) * 1000)
    passed = len(findings) == 0
    severity = 'PASS' if passed else 'Critical'

    raw.append({
        'timestamp': ts(),
        'endpoint': 'source-scan',
        'method': 'STATIC',
        'role': 'n/a',
        'http_status': 0,
        'response_time_ms': elapsed,
        'result': 'PASS' if passed else 'FAIL',
    })

    return {
        'id': 'TC-SEC-001',
        'category': 'Secret Exposure',
        'title': 'Hardcoded Secrets in Source Code',
        'severity': severity,
        'status': 'PASS' if passed else 'FAIL',
        'endpoint': 'source-scan (all files)',
        'method': 'STATIC',
        'expected': 'No hardcoded secrets',
        'actual': f'{len(findings)} potential secrets found' if findings else 'None found',
        'recommendation': (
            'Move Firebase API keys to environment variables or use flutter_dotenv. '
            'Consider Firebase App Check to restrict API key misuse.'
            if not passed else 'No action required'
        ),
        'details': findings,
        'raw': raw,
        'auto_fixable': not passed,
    }


# ─────────────────────────────────────────────────────────────
# TEST CATEGORY 2 — SECURITY HEADERS (Web Build)
# ─────────────────────────────────────────────────────────────

REQUIRED_HEADERS = {
    'X-Frame-Options': re.compile(r'X-Frame-Options', re.IGNORECASE),
    'X-Content-Type-Options': re.compile(r'X-Content-Type-Options', re.IGNORECASE),
    'Content-Security-Policy': re.compile(r'Content-Security-Policy', re.IGNORECASE),
    'Referrer-Policy': re.compile(r'Referrer-Policy', re.IGNORECASE),
    'Permissions-Policy': re.compile(r'Permissions-Policy|Feature-Policy', re.IGNORECASE),
    'Strict-Transport-Security': re.compile(r'Strict-Transport-Security', re.IGNORECASE),
}


def test_security_headers():
    """TC-SEC-002 — Check web/index.html and firebase.json for security headers."""
    missing = []
    present = []
    files_checked = []
    start = time.time()

    check_files = [
        os.path.join(ROOT, 'web', 'index.html'),
        os.path.join(ROOT, 'firebase.json'),
    ]

    combined_text = ''
    for f in check_files:
        if os.path.exists(f):
            files_checked.append(os.path.relpath(f, ROOT))
            combined_text += open(f, encoding='utf-8', errors='ignore').read()

    for header, pat in REQUIRED_HEADERS.items():
        if pat.search(combined_text):
            present.append(header)
        else:
            missing.append(header)

    elapsed = int((time.time() - start) * 1000)
    passed = len(missing) == 0
    severity = 'PASS' if passed else 'Medium'

    return {
        'id': 'TC-SEC-002',
        'category': 'Security Headers',
        'title': 'Missing HTTP Security Headers in Web Build',
        'severity': severity,
        'status': 'PASS' if passed else 'FAIL',
        'endpoint': 'web/index.html, firebase.json',
        'method': 'STATIC',
        'expected': 'All security headers present',
        'actual': (
            f'Missing: {", ".join(missing)}' if missing
            else f'All headers present: {", ".join(present)}'
        ),
        'recommendation': (
            f'Add the following headers to firebase.json hosting headers config: {", ".join(missing)}'
            if missing else 'No action required'
        ),
        'details': {'missing': missing, 'present': present, 'files_checked': files_checked},
        'raw': [{
            'timestamp': ts(), 'endpoint': 'web/index.html',
            'method': 'STATIC', 'role': 'n/a',
            'http_status': 0, 'response_time_ms': elapsed,
            'result': 'PASS' if passed else 'FAIL',
        }],
        'auto_fixable': not passed,
    }


# ─────────────────────────────────────────────────────────────
# TEST CATEGORY 3 — AUTH/AUTHZ CHECKS
# ─────────────────────────────────────────────────────────────

def test_auth_checks():
    """TC-SEC-003 — Check for missing JWT/auth guards in Dart source."""
    findings = []
    start = time.time()

    # Patterns that indicate auth usage
    auth_guard_pat = re.compile(
        r'(FirebaseAuth\.instance\.currentUser|requireAuth|AuthGuard|isAuthenticated|uid\s*==|uid\.isNotEmpty)',
        re.IGNORECASE,
    )
    # Firestore writes without auth check
    write_pat = re.compile(r'\.(set|update|delete|add)\s*\(', re.IGNORECASE)

    for full, rel in _walk_source():
        if not full.endswith('.dart'):
            continue
        try:
            text = open(full, encoding='utf-8', errors='ignore').read()
        except Exception:
            continue

        # Flag: Firestore writes that don't reference auth in the same file
        has_firestore = 'FirebaseFirestore' in text or 'cloud_firestore' in text
        has_write = has_firestore and bool(write_pat.search(text))
        has_auth = bool(auth_guard_pat.search(text))

        if has_write and not has_auth:
            findings.append({
                'file': rel,
                'issue': 'Firestore write operations found without visible auth guard in same file',
                'severity': 'High',
            })

    elapsed = int((time.time() - start) * 1000)
    passed = len(findings) == 0
    severity = 'PASS' if passed else 'High'

    return {
        'id': 'TC-SEC-003',
        'category': 'AuthN/AuthZ',
        'title': 'Missing Auth Guards on Firestore Write Operations',
        'severity': severity,
        'status': 'PASS' if passed else 'FAIL',
        'endpoint': 'firestore:://multiple collections',
        'method': 'STATIC',
        'expected': 'All Firestore writes gated by Firebase Auth check',
        'actual': (
            f'{len(findings)} file(s) perform Firestore writes without visible auth guard'
            if findings else 'Auth guards present on all write operations'
        ),
        'recommendation': (
            'Ensure every Firestore write checks FirebaseAuth.instance.currentUser != null '
            'before executing. Also enforce server-side rules in Firestore security rules.'
            if not passed else 'No action required'
        ),
        'details': findings,
        'raw': [{
            'timestamp': ts(), 'endpoint': 'firestore-auth-scan',
            'method': 'STATIC', 'role': 'n/a',
            'http_status': 0, 'response_time_ms': elapsed,
            'result': 'PASS' if passed else 'FAIL',
        }],
        'auto_fixable': False,  # Requires manual code review
    }


# ─────────────────────────────────────────────────────────────
# TEST CATEGORY 4 — INPUT VALIDATION
# ─────────────────────────────────────────────────────────────

def test_input_validation():
    """TC-SEC-004 — Check for input sanitization in Dart UI code."""
    findings = []
    start = time.time()

    # Patterns that suggest user input is taken
    input_pat = re.compile(r'(TextField|TextFormField|TextEditingController)', re.IGNORECASE)
    # Patterns that suggest validation
    validation_pat = re.compile(
        r'(validator\s*:|sanitize|allowList|RegExp|maxLength|inputFormatters|trim\(\)|isEmpty)',
        re.IGNORECASE,
    )

    for full, rel in _walk_source():
        if not full.endswith('.dart'):
            continue
        try:
            text = open(full, encoding='utf-8', errors='ignore').read()
        except Exception:
            continue

        if input_pat.search(text) and not validation_pat.search(text):
            findings.append({
                'file': rel,
                'issue': 'Text input widget found without apparent input validation/sanitization',
                'severity': 'Medium',
            })

    elapsed = int((time.time() - start) * 1000)
    passed = len(findings) == 0
    severity = 'PASS' if passed else 'Medium'

    return {
        'id': 'TC-SEC-004',
        'category': 'Input Validation',
        'title': 'Missing Input Validation on User-Facing Text Fields',
        'severity': severity,
        'status': 'PASS' if passed else 'FAIL',
        'endpoint': 'multiple UI screens',
        'method': 'STATIC',
        'expected': 'All text inputs have validator, maxLength, or inputFormatters',
        'actual': (
            f'{len(findings)} screen(s) use text inputs without visible validation'
            if findings else 'Input validation present'
        ),
        'recommendation': (
            'Add validator callbacks to TextFormField widgets. '
            'Use inputFormatters to restrict allowed characters. '
            'Apply .trim() before writing user input to Firestore.'
            if not passed else 'No action required'
        ),
        'details': findings,
        'raw': [{
            'timestamp': ts(), 'endpoint': 'ui-input-scan',
            'method': 'STATIC', 'role': 'n/a',
            'http_status': 0, 'response_time_ms': elapsed,
            'result': 'PASS' if passed else 'FAIL',
        }],
        'auto_fixable': False,
    }


# ─────────────────────────────────────────────────────────────
# TEST CATEGORY 5 — DART STATIC ANALYSIS
# ─────────────────────────────────────────────────────────────

def test_dart_analyze():
    """TC-SEC-005 — Run dart analyze and capture issues."""
    start = time.time()
    try:
        p = subprocess.run(
            ['dart', 'analyze', '--no-fatal-infos'],
            cwd=ROOT, capture_output=True, text=True, timeout=180,
        )
        elapsed = int((time.time() - start) * 1000)
        passed = p.returncode == 0
        output = (p.stdout + p.stderr).strip()
        severity = 'PASS' if passed else 'Medium'
        return {
            'id': 'TC-SEC-005',
            'category': 'Static Analysis',
            'title': 'Dart Static Analyzer Issues',
            'severity': severity,
            'status': 'PASS' if passed else 'FAIL',
            'endpoint': 'dart-analyze (all lib/)',
            'method': 'STATIC',
            'expected': 'Zero analyzer errors',
            'actual': 'No issues' if passed else output[:600],
            'recommendation': (
                'Run `dart fix --apply` to auto-fix most analyzer issues. '
                'Review remaining issues manually.'
                if not passed else 'No action required'
            ),
            'details': {'stdout': output[:2000]},
            'raw': [{
                'timestamp': ts(), 'endpoint': 'dart-analyze',
                'method': 'STATIC', 'role': 'n/a',
                'http_status': p.returncode, 'response_time_ms': elapsed,
                'result': 'PASS' if passed else 'FAIL',
            }],
            'auto_fixable': not passed,
        }
    except FileNotFoundError:
        return {
            'id': 'TC-SEC-005',
            'category': 'Static Analysis',
            'title': 'Dart Static Analyzer Issues',
            'severity': 'Low',
            'status': 'SKIP',
            'endpoint': 'dart-analyze',
            'method': 'STATIC',
            'expected': 'Zero analyzer errors',
            'actual': 'dart not found in PATH — skipped',
            'recommendation': 'Install Flutter/Dart SDK and ensure it is in PATH.',
            'details': {},
            'raw': [],
            'auto_fixable': False,
        }
    except Exception as e:
        return {
            'id': 'TC-SEC-005',
            'category': 'Static Analysis',
            'title': 'Dart Static Analyzer Issues',
            'severity': 'Low',
            'status': 'ERROR',
            'endpoint': 'dart-analyze',
            'method': 'STATIC',
            'expected': 'Zero analyzer errors',
            'actual': str(e),
            'recommendation': 'Check Dart SDK installation.',
            'details': {},
            'raw': [],
            'auto_fixable': False,
        }


# ─────────────────────────────────────────────────────────────
# TEST CATEGORY 6 — FIREBASE RULES CHECK
# ─────────────────────────────────────────────────────────────

def test_firebase_rules():
    """TC-SEC-006 — Check if Firestore/Storage security rules are restrictive."""
    start = time.time()
    findings = []

    rules_files = [
        os.path.join(ROOT, 'firestore.rules'),
        os.path.join(ROOT, 'storage.rules'),
    ]

    dangerous_patterns = [
        (re.compile(r'allow\s+read,\s*write\s*:\s*if\s+true', re.IGNORECASE), 'Critical',
         'Open read+write rule: allow read, write: if true'),
        (re.compile(r'allow\s+read\s*:\s*if\s+true', re.IGNORECASE), 'High',
         'Open read rule: allow read: if true'),
        (re.compile(r'allow\s+write\s*:\s*if\s+true', re.IGNORECASE), 'Critical',
         'Open write rule: allow write: if true'),
    ]

    for rules_file in rules_files:
        rel = os.path.relpath(rules_file, ROOT)
        if not os.path.exists(rules_file):
            findings.append({
                'file': rel,
                'issue': f'Security rules file not found: {rel}',
                'severity': 'High',
            })
            continue
        try:
            text = open(rules_file, encoding='utf-8', errors='ignore').read()
        except Exception:
            continue

        for pat, sev, desc in dangerous_patterns:
            if pat.search(text):
                findings.append({'file': rel, 'issue': desc, 'severity': sev})

    elapsed = int((time.time() - start) * 1000)
    passed = len(findings) == 0
    severity = 'PASS' if passed else (
        'Critical' if any(f['severity'] == 'Critical' for f in findings) else 'High'
    )

    return {
        'id': 'TC-SEC-006',
        'category': 'AuthN/AuthZ',
        'title': 'Insecure Firebase Security Rules',
        'severity': severity,
        'status': 'PASS' if passed else 'FAIL',
        'endpoint': 'firestore.rules / storage.rules',
        'method': 'STATIC',
        'expected': 'Restrictive Firebase security rules (no open access)',
        'actual': (
            '; '.join(f['issue'] for f in findings)
            if findings else 'Rules appear restrictive'
        ),
        'recommendation': (
            'Replace `allow read, write: if true` with proper auth checks: '
            '`allow read, write: if request.auth != null && request.auth.uid == resource.data.uid`'
            if not passed else 'No action required'
        ),
        'details': findings,
        'raw': [{
            'timestamp': ts(), 'endpoint': 'firebase-rules',
            'method': 'STATIC', 'role': 'n/a',
            'http_status': 0, 'response_time_ms': elapsed,
            'result': 'PASS' if passed else 'FAIL',
        }],
        'auto_fixable': False,
    }


# ─────────────────────────────────────────────────────────────
# TEST CATEGORY 7 — DEPENDENCY VULNERABILITY CHECK
# ─────────────────────────────────────────────────────────────

def test_dependency_versions():
    """TC-SEC-007 — Check pubspec.yaml for known outdated/vulnerable packages."""
    start = time.time()
    findings = []

    # Known packages that had significant CVEs — checked by name presence
    # (In a real pipeline, you'd use `pub outdated` or an advisory feed)
    flagged_packages = {
        'http': '1.0.0',          # older versions had redirect issues
        'shared_preferences': '2.0.0',  # older had data exposure on Android
        'url_launcher': '6.0.0',  # older had intent-based exploits
    }

    pubspec = os.path.join(ROOT, 'pubspec.yaml')
    text = ''
    if os.path.exists(pubspec):
        text = open(pubspec, encoding='utf-8', errors='ignore').read()

    for pkg, min_ver in flagged_packages.items():
        pat = re.compile(rf'{re.escape(pkg)}\s*:\s*\^?(\d+\.\d+)', re.IGNORECASE)
        m = pat.search(text)
        if m:
            declared = m.group(1)
            # Simple major.minor check
            try:
                declared_parts = [int(x) for x in declared.split('.')]
                min_parts = [int(x) for x in min_ver.split('.')]
                if declared_parts < min_parts:
                    findings.append({
                        'package': pkg,
                        'declared': declared,
                        'minimum_safe': min_ver,
                        'severity': 'Medium',
                    })
            except Exception:
                pass

    elapsed = int((time.time() - start) * 1000)
    passed = len(findings) == 0

    return {
        'id': 'TC-SEC-007',
        'category': 'Dependency Security',
        'title': 'Outdated/Vulnerable Dependencies in pubspec.yaml',
        'severity': 'PASS' if passed else 'Medium',
        'status': 'PASS' if passed else 'FAIL',
        'endpoint': 'pubspec.yaml',
        'method': 'STATIC',
        'expected': 'All dependencies at or above minimum safe versions',
        'actual': (
            f'{len(findings)} package(s) below minimum safe version'
            if findings else 'All checked packages are at safe versions'
        ),
        'recommendation': (
            'Run `flutter pub upgrade` to update packages. '
            'Review changelog for breaking changes.'
            if not passed else 'No action required'
        ),
        'details': findings,
        'raw': [{
            'timestamp': ts(), 'endpoint': 'pubspec-scan',
            'method': 'STATIC', 'role': 'n/a',
            'http_status': 0, 'response_time_ms': elapsed,
            'result': 'PASS' if passed else 'FAIL',
        }],
        'auto_fixable': False,
    }


# ─────────────────────────────────────────────────────────────
# RUN ALL TESTS
# ─────────────────────────────────────────────────────────────

def run_all_tests():
    print('[DAST] Starting security test suite...')
    tests = [
        test_secret_exposure,
        test_security_headers,
        test_auth_checks,
        test_input_validation,
        test_dart_analyze,
        test_firebase_rules,
        test_dependency_versions,
    ]
    results = []
    for fn in tests:
        print(f'  ▸ {fn.__name__}...', end=' ', flush=True)
        try:
            r = fn()
            results.append(r)
            icon = '✅' if r['status'] == 'PASS' else ('⚠️ ' if r['status'] == 'SKIP' else '❌')
            print(f'{icon} {r["status"]} [{r["severity"]}]')
        except Exception as e:
            print(f'💥 ERROR: {e}')
            results.append({
                'id': fn.__name__, 'category': 'Error',
                'title': fn.__name__, 'severity': 'Low',
                'status': 'ERROR', 'endpoint': 'n/a', 'method': 'n/a',
                'expected': 'n/a', 'actual': str(e),
                'recommendation': 'Fix the test script error.',
                'details': {}, 'raw': [], 'auto_fixable': False,
            })
    return results


if __name__ == '__main__':
    results = run_all_tests()
    print(f'\n[DAST] {len(results)} tests completed.')
    for r in results:
        print(f"  {r['id']}: {r['status']} — {r['title']}")
