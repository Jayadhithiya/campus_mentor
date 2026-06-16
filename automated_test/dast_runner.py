# -*- coding: utf-8 -*-
"""
dast_runner.py -- Master DAST Pipeline Orchestrator

Usage:
  python dast_runner.py                      # Full run (tests + remediation + report + GitHub)
  python dast_runner.py --discover-only      # Endpoint discovery only
  python dast_runner.py --run-tests          # Tests + report, no GitHub push
  python dast_runner.py --no-github          # Tests + remediation + report, skip GitHub
  python dast_runner.py --no-remediate       # Tests + report, skip auto-fix

Exits with code 1 if Security Gate fails (Critical finding, >3 High, AuthN/AuthZ bypass).
"""

import os
import sys
import json
import argparse
from datetime import datetime, timezone

# Ensure automated_test/ is in path for sibling imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from security_tests import run_all_tests, discover_endpoints
from auto_remediate import apply_all_fixes
from generate_excel_report import generate_report
from github_integration import run_github_integration

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
OUT_DIR = os.path.dirname(os.path.abspath(__file__))

REPORT_JSON  = os.path.join(OUT_DIR, 'report.json')
REPORT_MD    = os.path.join(OUT_DIR, 'report.md')
REPORT_XLSX  = os.path.join(OUT_DIR, 'security_test_report.xlsx')


# ─────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────

def _ts():
    return datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M UTC')


def _separator(label=''):
    width = 68
    if label:
        pad = max(2, (width - len(label) - 2) // 2)
        print('-' * pad + f' {label} ' + '-' * pad)
    else:
        print('-' * width)


# ─────────────────────────────────────────────────────────────
# Report generators
# ─────────────────────────────────────────────────────────────

def write_json_report(endpoints, test_results, remediation_log, github_result):
    report = {
        'generated_at': _ts(),
        'summary': {
            'endpoints_discovered': len(endpoints),
            'total_tests': len(test_results),
            'passed': sum(1 for r in test_results if r['status'] == 'PASS'),
            'failed': sum(1 for r in test_results if r['status'] == 'FAIL'),
            'critical': sum(1 for r in test_results if r['severity'] == 'Critical'),
            'high': sum(1 for r in test_results if r['severity'] == 'High'),
            'medium': sum(1 for r in test_results if r['severity'] == 'Medium'),
            'low': sum(1 for r in test_results if r['severity'] == 'Low'),
        },
        'endpoints': endpoints,
        'findings': [
            {k: v for k, v in r.items() if k != 'raw'}
            for r in test_results
        ],
        'remediation': remediation_log,
        'github': github_result,
    }
    with open(REPORT_JSON, 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2)
    print(f'[Runner] report.json → {REPORT_JSON}')
    return report


def write_md_report(endpoints, test_results, remediation_log, github_result):
    total   = len(test_results)
    passed  = sum(1 for r in test_results if r['status'] == 'PASS')
    failed  = sum(1 for r in test_results if r['status'] == 'FAIL')
    critical = sum(1 for r in test_results if r['severity'] == 'Critical')
    high    = sum(1 for r in test_results if r['severity'] == 'High')
    medium  = sum(1 for r in test_results if r['severity'] == 'Medium')
    low     = sum(1 for r in test_results if r['severity'] == 'Low')

    auto_fixed   = [r for r in remediation_log if r.get('auto_fixed')]
    manual_req   = [r for r in remediation_log if not r.get('auto_fixed')]

    lines = [
        '# 🛡️ DAST Security Test Report',
        '',
        f'**Generated:** {_ts()}  ',
        f'**Project:** campus_mentor (Flutter/Firebase)',
        '',
        '---',
        '',
        '## Executive Summary',
        '',
        '| Metric | Value |',
        '|--------|-------|',
        f'| Endpoints Discovered | {len(endpoints)} |',
        f'| Total Tests | {total} |',
        f'| Passed ✅ | {passed} |',
        f'| Failed ❌ | {failed} |',
        f'| 🔴 Critical | {critical} |',
        f'| 🟠 High | {high} |',
        f'| 🟡 Medium | {medium} |',
        f'| 🔵 Low | {low} |',
        '',
        '---',
        '',
        '## Endpoint Inventory',
        '',
        '| Method | Endpoint | Access Type | Expected Roles |',
        '|--------|----------|-------------|----------------|',
    ]

    for ep in endpoints[:30]:   # cap to 30 in MD for readability
        lines.append(
            f'| `{ep["method"]}` | `{ep["endpoint"][:60]}` '
            f'| {ep["access_type"]} | {ep["expected_roles"]} |'
        )
    if len(endpoints) > 30:
        lines.append(f'| ... | *{len(endpoints)-30} more — see report.json* | | |')

    lines += [
        '',
        '---',
        '',
        '## Findings',
        '',
        '| ID | Severity | Category | Status | Title |',
        '|----|----------|----------|--------|-------|',
    ]
    for r in test_results:
        sev_icon = {
            'Critical': '🔴', 'High': '🟠', 'Medium': '🟡',
            'Low': '🔵', 'PASS': '✅',
        }.get(r['severity'], '⚪')
        status_icon = '✅' if r['status'] == 'PASS' else '❌'
        lines.append(
            f'| {r["id"]} | {sev_icon} {r["severity"]} '
            f'| {r["category"]} | {status_icon} {r["status"]} | {r["title"]} |'
        )

    lines += [
        '',
        '---',
        '',
        '## Remediation Status',
        '',
        '| Finding ID | Auto Fixed | Status | Files Changed | Details |',
        '|------------|------------|--------|---------------|---------|',
    ]
    for r in remediation_log:
        fixed  = '✅ Yes' if r.get('auto_fixed') else '❌ No'
        files  = ', '.join(r.get('files_changed', [])) or '—'
        detail = (r.get('details') or r.get('manual_action') or '')[:80]
        lines.append(
            f'| {r["finding_id"]} | {fixed} | {r["fix_status"]} | `{files}` | {detail} |'
        )

    if github_result and not github_result.get('skipped'):
        lines += [
            '',
            '---',
            '',
            '## GitHub Integration',
            '',
            f'- **Branch:** `{github_result.get("branch","")}`',
            f'- **Commit:** `{github_result.get("commit_sha","")[:10]}`',
            f'- **PR:** #{github_result.get("pr_number","")} — {github_result.get("pr_url","")}',
        ]
        if github_result.get('issues'):
            lines.append(f'- **Issues created:** {len(github_result["issues"])}')
            for issue in github_result['issues']:
                if issue.get('success'):
                    lines.append(f'  - #{issue["issue_number"]} → {issue.get("issue_url","")}')

    lines += ['', '---', '', '*Generated by DAST Security Pipeline*']

    with open(REPORT_MD, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))
    print(f'[Runner] report.md → {REPORT_MD}')


# ─────────────────────────────────────────────────────────────
# Security Gate
# ─────────────────────────────────────────────────────────────

def evaluate_security_gate(test_results):
    """
    Fail gate if:
      - Any Critical finding
      - More than 3 High findings
      - Any authentication bypass (TC-SEC-003 FAIL)
      - Any authorization bypass (TC-SEC-006 Critical FAIL)
    Returns (passed: bool, reasons: list[str])
    """
    reasons = []

    critical_findings = [r for r in test_results if r['severity'] == 'Critical' and r['status'] == 'FAIL']
    if critical_findings:
        reasons.append(f'Critical findings: {[r["id"] for r in critical_findings]}')

    high_findings = [r for r in test_results if r['severity'] == 'High' and r['status'] == 'FAIL']
    if len(high_findings) > 3:
        reasons.append(f'More than 3 High findings: {len(high_findings)} found')

    authn_bypass = next(
        (r for r in test_results if r['id'] == 'TC-SEC-003' and r['status'] == 'FAIL'), None
    )
    if authn_bypass:
        reasons.append('Authentication bypass finding: TC-SEC-003 FAIL')

    authz_bypass = next(
        (r for r in test_results if r['id'] == 'TC-SEC-006' and r['severity'] == 'Critical' and r['status'] == 'FAIL'),
        None,
    )
    if authz_bypass:
        reasons.append('Authorization bypass finding: TC-SEC-006 Critical FAIL')

    return (len(reasons) == 0), reasons


# ─────────────────────────────────────────────────────────────
# Main pipeline
# ─────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description='DAST Security Pipeline for campus_mentor')
    parser.add_argument('--discover-only', action='store_true',
                        help='Only run endpoint discovery, then exit')
    parser.add_argument('--run-tests', action='store_true',
                        help='Run tests and generate report (no GitHub push)')
    parser.add_argument('--no-github', action='store_true',
                        help='Skip GitHub integration (branch/PR/issues)')
    parser.add_argument('--no-remediate', action='store_true',
                        help='Skip auto-remediation')
    args = parser.parse_args()

    os.makedirs(OUT_DIR, exist_ok=True)

    print()
    _separator('DAST Security Pipeline - campus_mentor')
    print(f'  Start: {_ts()}')
    print(f'  Root:  {ROOT}')
    _separator()
    print()

    # ── STEP 1: Endpoint Discovery ────────────────────────────
    _separator('STEP 1 - Endpoint Discovery')
    endpoints = discover_endpoints()
    print(f'  Discovered {len(endpoints)} endpoints')
    for ep in endpoints[:8]:
        print(f'    [{ep["method"]:10s}] {ep["endpoint"][:60]}')
    if len(endpoints) > 8:
        print(f'    ... and {len(endpoints)-8} more')
    print()

    if args.discover_only:
        print('[Runner] --discover-only: done.')
        _separator()
        return 0

    # ── STEP 2: DAST Execution ────────────────────────────────
    _separator('STEP 2 - DAST Test Execution')
    test_results = run_all_tests()
    print()

    # ── STEP 3: Auto-Remediation ──────────────────────────────
    remediation_log = []
    if not args.no_remediate:
        _separator('STEP 3 - Automated Remediation')
        remediation_log = apply_all_fixes(test_results)
        print()
    else:
        # Still populate log with "skipped" entries
        for r in test_results:
            remediation_log.append({
                'finding_id': r['id'],
                'auto_fixed': False,
                'fix_status': 'Skipped (--no-remediate)',
                'files_changed': [],
                'commit_sha': '',
                'pr_number': '',
                'verification_status': 'Not Run',
                'details': '',
            })

    # ── STEP 4: Re-run tests after remediation ─────────────────
    if not args.no_remediate and any(r.get('auto_fixed') for r in remediation_log):
        _separator('STEP 4 - Re-running Tests After Remediation')
        post_results = run_all_tests()
        # Merge: update status of auto-fixed findings
        fixed_ids = {r['finding_id'] for r in remediation_log if r.get('auto_fixed')}
        for orig in test_results:
            if orig['id'] in fixed_ids:
                updated = next((p for p in post_results if p['id'] == orig['id']), None)
                if updated:
                    orig['status']   = updated['status']
                    orig['severity'] = updated['severity']
                    orig['actual']   = updated['actual'] + ' [POST-FIX]'
        print()

    # ── STEP 5: Generate Reports ──────────────────────────────
    _separator('STEP 5 - Generating Reports')
    github_result = {'skipped': True}
    write_json_report(endpoints, test_results, remediation_log, github_result)
    write_md_report(endpoints, test_results, remediation_log, github_result)
    generate_report(test_results, endpoints, remediation_log, REPORT_XLSX)
    print()

    # ── STEP 6: GitHub Integration ────────────────────────────
    skip_github = args.no_github or args.run_tests
    if not skip_github:
        _separator('STEP 6 - GitHub Integration')
        github_result = run_github_integration(
            test_results, remediation_log,
            report_files=[REPORT_JSON, REPORT_MD, REPORT_XLSX],
        )
        # Re-write reports with GitHub data filled in
        write_json_report(endpoints, test_results, remediation_log, github_result)
        write_md_report(endpoints, test_results, remediation_log, github_result)
        print()
    else:
        print('[Runner] GitHub integration skipped.')
        print()

    # ── STEP 7: Security Gate ─────────────────────────────────
    _separator('STEP 7 - Security Gate')
    gate_passed, gate_reasons = evaluate_security_gate(test_results)

    if gate_passed:
        print('  [PASS] SECURITY GATE: PASSED')
    else:
        print('  [FAIL] SECURITY GATE: FAILED')
        for reason in gate_reasons:
            print(f'     - {reason}')

    # ── Final Summary ─────────────────────────────────────────
    print()
    _separator('Summary')
    total   = len(test_results)
    passed  = sum(1 for r in test_results if r['status'] == 'PASS')
    failed  = sum(1 for r in test_results if r['status'] == 'FAIL')
    critical = sum(1 for r in test_results if r['severity'] == 'Critical')
    high    = sum(1 for r in test_results if r['severity'] == 'High')
    medium  = sum(1 for r in test_results if r['severity'] == 'Medium')
    low     = sum(1 for r in test_results if r['severity'] == 'Low')

    print(f'  Tests:    {total} total  |  {passed} passed  |  {failed} failed')
    print(f'  Severity: [C] {critical} Critical  [H] {high} High  [M] {medium} Medium  [L] {low} Low')
    print(f'  Reports:  {os.path.relpath(REPORT_XLSX, ROOT)}')
    print(f'            {os.path.relpath(REPORT_JSON, ROOT)}')
    print(f'            {os.path.relpath(REPORT_MD, ROOT)}')

    if not skip_github and not github_result.get('skipped'):
        pr = github_result.get('pr_url') or f'PR #{github_result.get("pr_number","")}'
        print(f'  PR:       {pr}')
        print(f'  Issues:   {len(github_result.get("issues", []))} created')

    _separator()
    print()

    # Exit code for CI
    if not gate_passed:
        sys.exit(1)
    return 0


if __name__ == '__main__':
    sys.exit(main())
