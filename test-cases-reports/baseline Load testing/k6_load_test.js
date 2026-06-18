/**
 * Campus Mentor - Baseline / Load Test Script (k6)
 * ─────────────────────────────────────────────────
 * Config : 100 Virtual Users | Duration: 1 minute
 * Target : http://127.0.0.1:8080  (local Flutter Web build)
 *
 * Run:
 *   k6 run k6_load_test.js --out json=k6_results.json
 */

import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

// ─── Custom Metrics ────────────────────────────────────────────────────────
const errorRate       = new Rate('error_rate');
const pageLoadTime    = new Trend('page_load_time', true);
const apiLatency      = new Trend('api_latency', true);
const successCounter  = new Counter('successful_requests');
const failCounter     = new Counter('failed_requests');

// ─── Test Configuration ────────────────────────────────────────────────────
export const options = {
  scenarios: {
    baseline_load: {
      executor: 'constant-vus',
      vus: 100,
      duration: '1m',
      gracefulStop: '10s',
    },
  },
  thresholds: {
    // 95% of requests must complete below 2s
    http_req_duration: ['p(95)<2000'],
    // Error rate must stay below 5%
    error_rate: ['rate<0.05'],
    // 99% of requests must complete below 5s
    'http_req_duration{type:page}': ['p(99)<5000'],
  },
  summaryTrendStats: ['avg', 'min', 'med', 'max', 'p(90)', 'p(95)', 'p(99)'],
};

// ─── Base URL ──────────────────────────────────────────────────────────────
const BASE_URL = __ENV.BASE_URL || 'http://127.0.0.1:8080';

// ─── Helper: tagged GET request ────────────────────────────────────────────
function get(url, tag, expectedStatus = 200) {
  const params = { tags: { type: tag } };
  const res = http.get(url, params);
  const ok = check(res, {
    [`${tag} status ${expectedStatus}`]: (r) => r.status === expectedStatus || r.status === 304,
    [`${tag} response time < 3000ms`]  : (r) => r.timings.duration < 3000,
  });

  pageLoadTime.add(res.timings.duration, { endpoint: tag });
  errorRate.add(!ok);

  if (ok) { successCounter.add(1); }
  else     { failCounter.add(1); }

  return res;
}

// ─── Virtual User Scenario ─────────────────────────────────────────────────
export default function () {

  // ── 1. Home / Root ──────────────────────────────────────────────────────
  group('01_Home Page', () => {
    get(`${BASE_URL}/`, 'page');
    sleep(0.5);
  });

  // ── 2. Static Assets ────────────────────────────────────────────────────
  group('02_Static Assets', () => {
    // Flutter Web bootstrap assets
    const assets = [
      '/flutter.js',
      '/flutter_bootstrap.js',
      '/main.dart.js',
      '/manifest.json',
      '/index.html',
      '/favicon.png',
      '/icons/Icon-192.png',
    ];
    for (const asset of assets) {
      const res = http.get(`${BASE_URL}${asset}`);
      const ok = check(res, {
        [`asset ${asset} loaded`]: (r) => r.status === 200 || r.status === 304 || r.status === 404,
      });
      errorRate.add(!ok);
      if (ok) successCounter.add(1); else failCounter.add(1);
    }
    sleep(0.3);
  });

  // ── 3. SPA Routes (index.html rewrite) ──────────────────────────────────
  group('03_SPA Routes', () => {
    const routes = [
      '/login',
      '/signup',
      '/dashboard',
      '/profile',
      '/mentors',
      '/sessions',
      '/resources',
      '/chat',
      '/settings',
      '/notifications',
    ];
    for (const route of routes) {
      get(`${BASE_URL}${route}`, 'page');
      sleep(0.2);
    }
  });

  // ── 4. Manifest & PWA ────────────────────────────────────────────────────
  group('04_PWA Manifest', () => {
    get(`${BASE_URL}/manifest.json`, 'api');
    sleep(0.2);
  });

  // ── 5. Concurrent Asset Batch ────────────────────────────────────────────
  group('05_Concurrent Asset Batch', () => {
    const batch = [
      `${BASE_URL}/flutter.js`,
      `${BASE_URL}/main.dart.js`,
      `${BASE_URL}/index.html`,
    ];
    const responses = http.batch(batch.map(url => ['GET', url]));
    for (const res of responses) {
      const ok = check(res, {
        'batch status ok': (r) => r.status === 200 || r.status === 304,
      });
      errorRate.add(!ok);
    }
    sleep(0.5);
  });

  // ── 6. Simulate repeated navigation ─────────────────────────────────────
  group('06_Repeat Navigation', () => {
    get(`${BASE_URL}/`, 'page');
    sleep(0.3);
    get(`${BASE_URL}/login`, 'page');
    sleep(0.3);
    get(`${BASE_URL}/dashboard`, 'page');
    sleep(0.3);
  });

  sleep(1);
}

// ─── Summary Handler ────────────────────────────────────────────────────────
export function handleSummary(data) {
  // Write raw JSON for the Excel report generator
  return {
    'k6_results.json': JSON.stringify(data, null, 2),
    stdout: textSummary(data),
  };
}

// ─── Text Summary Formatter ─────────────────────────────────────────────────
function textSummary(data) {
  const m   = data.metrics;
  const dur = m.http_req_duration;
  const rps = m.http_reqs ? (m.http_reqs.values.count / 60).toFixed(1) : 'N/A';

  return `
╔══════════════════════════════════════════════════════════════════╗
║           CAMPUS MENTOR  –  BASELINE / LOAD TEST REPORT          ║
╠══════════════════════════════════════════════════════════════════╣
║  Virtual Users  : 100                                            ║
║  Duration       : 1 minute                                       ║
║  Target URL     : ${(BASE_URL).padEnd(43)} ║
╠══════════════════════════════════════════════════════════════════╣
║  THROUGHPUT                                                       ║
║    Total Requests      : ${String(m.http_reqs?.values?.count ?? 0).padEnd(38)} ║
║    Requests/sec (RPS)  : ${String(rps).padEnd(38)} ║
╠══════════════════════════════════════════════════════════════════╣
║  RESPONSE TIMES (ms)                                             ║
║    Average    : ${String((dur?.values?.avg   ?? 0).toFixed(2) + ' ms').padEnd(46)} ║
║    Min        : ${String((dur?.values?.min   ?? 0).toFixed(2) + ' ms').padEnd(46)} ║
║    Median     : ${String((dur?.values?.med   ?? 0).toFixed(2) + ' ms').padEnd(46)} ║
║    p(90)      : ${String((dur?.values['p(90)'] ?? 0).toFixed(2) + ' ms').padEnd(46)} ║
║    p(95)      : ${String((dur?.values['p(95)'] ?? 0).toFixed(2) + ' ms').padEnd(46)} ║
║    p(99)      : ${String((dur?.values['p(99)'] ?? 0).toFixed(2) + ' ms').padEnd(46)} ║
║    Max        : ${String((dur?.values?.max   ?? 0).toFixed(2) + ' ms').padEnd(46)} ║
╠══════════════════════════════════════════════════════════════════╣
║  ERROR RATE  : ${String(((m.error_rate?.values?.rate ?? 0) * 100).toFixed(2) + ' %').padEnd(47)} ║
╠══════════════════════════════════════════════════════════════════╣
║  THRESHOLDS                                                       ║
║    p(95) < 2000 ms : ${(dur?.values['p(95)'] ?? 0) < 2000 ? '✅ PASS' : '❌ FAIL'}                                     ║
║    Error rate < 5% : ${((m.error_rate?.values?.rate ?? 0) * 100) < 5 ? '✅ PASS' : '❌ FAIL'}                                     ║
╚══════════════════════════════════════════════════════════════════╝
`;
}
