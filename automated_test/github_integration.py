"""
github_integration.py — GitHub REST API integration for DAST pipeline.

Responsibilities:
  1. Create branch: security/dast-auto-fix-<timestamp>
  2. Commit & push remediation changes
  3. Open a Pull Request with findings summary
  4. Post a PR comment with scan results table
  5. Create GitHub Issues for unfixed vulnerabilities
"""

import os
import json
import subprocess
from datetime import datetime, timezone

import requests

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))

# ─────────────────────────────────────────────────────────────
# Config — read from environment
# ─────────────────────────────────────────────────────────────

def _github_config():
    """Read GitHub config from environment variables."""
    token = (
        os.environ.get('GH_TOKEN')
        or os.environ.get('GITHUB_TOKEN')
        or ''
    )
    repo = os.environ.get('GITHUB_REPOSITORY', '')  # e.g. "Jayadhithiya/campus_mentor"

    if not repo:
        # Try to infer from git remote
        try:
            result = subprocess.run(
                ['git', 'remote', 'get-url', 'origin'],
                cwd=ROOT, capture_output=True, text=True,
            )
            url = result.stdout.strip()
            # parse github.com/owner/repo or git@github.com:owner/repo
            if 'github.com' in url:
                repo = (
                    url.split('github.com/')[-1]
                    .split('github.com:')[-1]
                    .removesuffix('.git')
                )
        except Exception:
            pass

    return token, repo


def _api_headers(token):
    return {
        'Authorization': f'Bearer {token}',
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
    }


def _api(method, path, token, **kwargs):
    """Make a GitHub API call. Returns (status_code, json_body)."""
    url = f'https://api.github.com{path}'
    try:
        resp = getattr(requests, method)(
            url, headers=_api_headers(token), timeout=30, **kwargs
        )
        try:
            body = resp.json()
        except Exception:
            body = {}
        return resp.status_code, body
    except requests.RequestException as e:
        return 0, {'error': str(e)}


# ─────────────────────────────────────────────────────────────
# 1. Create & push branch
# ─────────────────────────────────────────────────────────────

def create_and_push_branch(branch_name, files_to_stage):
    """
    Create a new git branch, stage provided files, commit, and push.

    Args:
        branch_name:    e.g. 'security/dast-auto-fix-20260616T185000Z'
        files_to_stage: list of relative paths (from ROOT)

    Returns: dict {success, branch, commit_sha, error}
    """
    try:
        # Ensure we're on main (or default) and up-to-date
        subprocess.run(['git', 'fetch', 'origin'], cwd=ROOT, check=False)

        # Create branch from HEAD
        subprocess.run(
            ['git', 'checkout', '-b', branch_name],
            cwd=ROOT, capture_output=True, text=True,
        )

        # Stage changed files (if any)
        if files_to_stage:
            abs_files = [
                os.path.join(ROOT, f) if not os.path.isabs(f) else f
                for f in files_to_stage
            ]
            # Only add files that actually exist
            existing = [f for f in abs_files if os.path.exists(f)]
            if existing:
                subprocess.run(['git', 'add'] + existing, cwd=ROOT)

        # Also stage any untracked new files in automated_test/
        subprocess.run(
            ['git', 'add', '--', 'automated_test/', 'firebase.json', '.gitignore', '.env.example'],
            cwd=ROOT, capture_output=True,
        )

        # Check if there's anything to commit
        status = subprocess.run(
            ['git', 'status', '--porcelain'],
            cwd=ROOT, capture_output=True, text=True,
        )
        if not status.stdout.strip():
            return {
                'success': True,
                'branch': branch_name,
                'commit_sha': 'no-changes',
                'error': None,
                'note': 'No changes to commit',
            }

        # Commit
        commit_result = subprocess.run(
            ['git', 'commit', '-m', 'fix(security): resolve DAST findings\n\n'
             'Automated remediation applied by DAST security pipeline.\n'
             'See automated_test/security_test_report.xlsx for full evidence.'],
            cwd=ROOT, capture_output=True, text=True,
        )

        # Get commit SHA
        sha_result = subprocess.run(
            ['git', 'rev-parse', 'HEAD'],
            cwd=ROOT, capture_output=True, text=True,
        )
        commit_sha = sha_result.stdout.strip()

        # Push
        push_result = subprocess.run(
            ['git', 'push', '--set-upstream', 'origin', branch_name],
            cwd=ROOT, capture_output=True, text=True,
        )

        if push_result.returncode == 0:
            return {
                'success': True,
                'branch': branch_name,
                'commit_sha': commit_sha,
                'error': None,
            }
        else:
            return {
                'success': False,
                'branch': branch_name,
                'commit_sha': commit_sha,
                'error': push_result.stderr.strip()[:500],
            }

    except Exception as e:
        return {'success': False, 'branch': branch_name, 'commit_sha': '', 'error': str(e)}


# ─────────────────────────────────────────────────────────────
# 2. Create Pull Request
# ─────────────────────────────────────────────────────────────

def _build_pr_body(test_results, remediation_log, commit_sha):
    """Build the PR body markdown."""
    total = len(test_results)
    passed = sum(1 for r in test_results if r['status'] == 'PASS')
    failed = sum(1 for r in test_results if r['status'] == 'FAIL')
    critical = sum(1 for r in test_results if r['severity'] == 'Critical')
    high = sum(1 for r in test_results if r['severity'] == 'High')
    medium = sum(1 for r in test_results if r['severity'] == 'Medium')
    low = sum(1 for r in test_results if r['severity'] == 'Low')

    auto_fixed = [r for r in remediation_log if r.get('auto_fixed')]
    manual_required = [r for r in remediation_log if not r.get('auto_fixed')]

    lines = [
        '## 🛡️ Security Auto Remediation — DAST Findings',
        '',
        '> This PR was automatically created by the DAST security pipeline.',
        '',
        '### 📊 Findings Summary',
        '',
        f'| Metric | Value |',
        f'|--------|-------|',
        f'| Tests Executed | {total} |',
        f'| Passed ✅ | {passed} |',
        f'| Failed ❌ | {failed} |',
        f'| 🔴 Critical | {critical} |',
        f'| 🟠 High | {high} |',
        f'| 🟡 Medium | {medium} |',
        f'| 🔵 Low | {low} |',
        '',
    ]

    if auto_fixed:
        lines += [
            '### ✅ Vulnerabilities Auto-Fixed in This PR',
            '',
        ]
        for fix in auto_fixed:
            fid = fix.get('finding_id', '')
            files = ', '.join(fix.get('files_changed', [])) or 'no files changed'
            lines.append(f'- **{fid}** — {fix.get("details", "")} (`{files}`)')
        lines.append('')

    if manual_required:
        lines += [
            '### ⚠️ Manual Review Required',
            '',
        ]
        for item in manual_required:
            fid = item.get('finding_id', '')
            rec = item.get('details', '') or item.get('manual_action', '')
            lines.append(f'- **{fid}** — {rec[:200]}')
        lines.append('')

    lines += [
        '### 📋 Detailed Findings',
        '',
        '| ID | Severity | Category | Status |',
        '|----|----------|----------|--------|',
    ]
    for r in test_results:
        lines.append(
            f'| {r["id"]} | {r["severity"]} | {r["category"]} | {r["status"]} |'
        )

    lines += [
        '',
        '### 📎 Attached Artifacts',
        '- `security_test_report.xlsx` — Full evidence report (5 tabs)',
        '- `report.json` — Machine-readable results',
        '- `report.md` — Human-readable summary',
        '',
        f'**Commit:** `{commit_sha[:10] if commit_sha else "n/a"}`',
        '',
        '---',
        '*Generated by DAST Security Pipeline · campus_mentor*',
    ]

    return '\n'.join(lines)


def create_pull_request(branch_name, test_results, remediation_log, commit_sha, token, repo):
    """
    Create a GitHub Pull Request.
    Returns: dict {success, pr_number, pr_url, error}
    """
    if not token or not repo:
        return {
            'success': False,
            'pr_number': '',
            'pr_url': '',
            'error': 'GH_TOKEN or GITHUB_REPOSITORY not set',
        }

    body = _build_pr_body(test_results, remediation_log, commit_sha)

    status, data = _api('post', f'/repos/{repo}/pulls', token, json={
        'title': 'Security Auto Remediation - DAST Findings',
        'head': branch_name,
        'base': 'main',
        'body': body,
        'draft': False,
    })

    if status in (200, 201):
        return {
            'success': True,
            'pr_number': str(data.get('number', '')),
            'pr_url': data.get('html_url', ''),
            'error': None,
        }
    else:
        return {
            'success': False,
            'pr_number': '',
            'pr_url': '',
            'error': f'HTTP {status}: {data.get("message", str(data))[:300]}',
        }


# ─────────────────────────────────────────────────────────────
# 3. Post PR Comment
# ─────────────────────────────────────────────────────────────

def post_pr_comment(pr_number, test_results, remediation_log, token, repo):
    """Post a summary comment on the PR."""
    if not token or not repo or not pr_number:
        return {'success': False, 'error': 'Missing token/repo/pr_number'}

    total = len(test_results)
    passed = sum(1 for r in test_results if r['status'] == 'PASS')
    critical = sum(1 for r in test_results if r['severity'] == 'Critical')
    high = sum(1 for r in test_results if r['severity'] == 'High')
    medium = sum(1 for r in test_results if r['severity'] == 'Medium')
    low = sum(1 for r in test_results if r['severity'] == 'Low')

    auto_fixed = [r for r in remediation_log if r.get('auto_fixed')]
    manual_required = [r for r in remediation_log if not r.get('auto_fixed')]

    auto_fixed_lines = '\n'.join(
        f'  - {r["finding_id"]}: {r.get("details","")[:100]}' for r in auto_fixed
    ) or '  - None'

    manual_lines = '\n'.join(
        f'  - {r["finding_id"]}: {r.get("details","")[:100]}' for r in manual_required
    ) or '  - None'

    comment = f"""### 🔐 Security Scan Results

| | |
|---|---|
| **Endpoints Tested** | {len(set(r['endpoint'] for r in test_results))} |
| **Tests Executed** | {total} |
| **Passed** | {passed} |

| Severity | Count |
|----------|-------|
| 🔴 Critical | {critical} |
| 🟠 High | {high} |
| 🟡 Medium | {medium} |
| 🔵 Low | {low} |

**Auto-Fixed:**
{auto_fixed_lines}

**Manual Review Required:**
{manual_lines}

📎 **Report Artifact:** `security_test_report.xlsx` (see workflow artifacts)

---
*Posted by DAST Security Pipeline*
"""

    status, data = _api(
        'post', f'/repos/{repo}/issues/{pr_number}/comments', token,
        json={'body': comment},
    )
    return {
        'success': status in (200, 201),
        'error': None if status in (200, 201) else f'HTTP {status}',
    }


# ─────────────────────────────────────────────────────────────
# 4. Create GitHub Issues for unfixed findings
# ─────────────────────────────────────────────────────────────

def create_github_issues(test_results, remediation_log, token, repo):
    """
    Create one GitHub Issue per unfixed vulnerability.
    Returns: list of {finding_id, issue_number, issue_url, success}
    """
    if not token or not repo:
        return []

    # Map finding_id → remediation record
    rem_map = {r['finding_id']: r for r in remediation_log}
    created = []

    for finding in test_results:
        if finding['status'] != 'FAIL':
            continue

        rem = rem_map.get(finding['id'], {})
        if rem.get('auto_fixed'):
            continue  # Already fixed — no issue needed

        sev = finding.get('severity', 'Low')
        label_map = {
            'Critical': 'critical',
            'High': 'high-severity',
            'Medium': 'medium-severity',
            'Low': 'low-severity',
        }
        labels = ['security', 'vulnerability', 'dast', label_map.get(sev, 'low-severity')]

        # Build issue body
        details_json = json.dumps(finding.get('details', {}), indent=2)[:1500]
        body = f"""## 🔐 Security Vulnerability: {finding['title']}

**Severity:** {sev}
**Category:** {finding.get('category', '')}
**Test ID:** {finding['id']}

---

### Endpoint / Affected Area
`{finding.get('endpoint', 'n/a')}` — Method: `{finding.get('method', 'n/a')}`

### Description
**Expected:** {finding.get('expected', '')}
**Actual:** {finding.get('actual', '')}

### Reproduction Steps
1. Run `python automated_test/dast_runner.py --run-tests`
2. Check finding `{finding['id']}` in `automated_test/security_test_report.xlsx`
3. Review the Findings tab for full details

### Recommendation
{finding.get('recommendation', '')}

### Details
```json
{details_json}
```

### Affected Files
{chr(10).join(f'- `{d.get("file", "")}`' for d in (finding.get('details') if isinstance(finding.get('details'), list) else [])) or '- See details above'}

---
*Auto-created by DAST Security Pipeline*
"""

        status, data = _api('post', f'/repos/{repo}/issues', token, json={
            'title': f'[{sev}] Security: {finding["title"]}',
            'body': body,
            'labels': labels,
        })

        if status in (200, 201):
            print(f'  📌 Created issue #{data.get("number")} for {finding["id"]}')
            created.append({
                'finding_id': finding['id'],
                'issue_number': str(data.get('number', '')),
                'issue_url': data.get('html_url', ''),
                'success': True,
            })
        else:
            err = data.get('message', str(status))
            print(f'  ⚠️  Failed to create issue for {finding["id"]}: {err[:100]}')
            created.append({
                'finding_id': finding['id'],
                'issue_number': '',
                'issue_url': '',
                'success': False,
                'error': err[:200],
            })

    return created


# ─────────────────────────────────────────────────────────────
# Orchestrator
# ─────────────────────────────────────────────────────────────

def run_github_integration(test_results, remediation_log, report_files=None):
    """
    Full GitHub integration flow:
      1. Create branch + commit + push
      2. Create PR
      3. Post PR comment
      4. Create issues for unfixed findings

    Returns: dict with all integration results
    """
    token, repo = _github_config()
    timestamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')
    branch_name = f'security/dast-auto-fix-{timestamp}'

    print(f'\n[GitHub] Repository: {repo or "NOT DETECTED"}')
    print(f'[GitHub] Branch: {branch_name}')

    if not token:
        print('[GitHub] ⚠️  GH_TOKEN not set — skipping GitHub integration')
        return {
            'branch': branch_name,
            'commit_sha': '',
            'pr_number': '',
            'pr_url': '',
            'issues': [],
            'skipped': True,
            'reason': 'GH_TOKEN not set',
        }

    # 1. Collect all changed files from remediation log
    all_changed = []
    for r in remediation_log:
        all_changed.extend(r.get('files_changed', []))

    # 2. Branch + commit + push
    print('[GitHub] Creating branch and committing...')
    branch_result = create_and_push_branch(branch_name, all_changed)
    commit_sha = branch_result.get('commit_sha', '')
    print(f'[GitHub] Branch push: {"✅" if branch_result["success"] else "❌"} — {branch_result.get("error", "ok")}')

    # Update commit SHA in remediation log
    for r in remediation_log:
        if r.get('auto_fixed') and not r.get('commit_sha'):
            r['commit_sha'] = commit_sha[:10] if commit_sha else ''

    # 3. Create PR
    print('[GitHub] Creating pull request...')
    pr_result = create_pull_request(branch_name, test_results, remediation_log, commit_sha, token, repo)
    pr_number = pr_result.get('pr_number', '')
    print(f'[GitHub] PR: {"✅" if pr_result["success"] else "❌"} #{pr_number} — {pr_result.get("pr_url", pr_result.get("error", ""))}')

    # Update PR number in remediation log
    for r in remediation_log:
        if not r.get('pr_number'):
            r['pr_number'] = pr_number

    # 4. Post PR comment
    if pr_number:
        print('[GitHub] Posting PR comment...')
        comment_result = post_pr_comment(pr_number, test_results, remediation_log, token, repo)
        print(f'[GitHub] PR comment: {"✅" if comment_result["success"] else "❌"}')

    # 5. Create issues for unfixed findings
    print('[GitHub] Creating issues for unfixed findings...')
    issues = create_github_issues(test_results, remediation_log, token, repo)
    print(f'[GitHub] Issues created: {sum(1 for i in issues if i["success"])}/{len(issues)}')

    return {
        'branch': branch_name,
        'commit_sha': commit_sha,
        'pr_number': pr_number,
        'pr_url': pr_result.get('pr_url', ''),
        'issues': issues,
        'skipped': False,
    }


if __name__ == '__main__':
    print('[GitHub Integration] Standalone mode — set GH_TOKEN and GITHUB_REPOSITORY env vars')
    token, repo = _github_config()
    print(f'  Token set: {"yes" if token else "NO"}')
    print(f'  Repo: {repo or "NOT DETECTED"}')
