import { writeFileSync } from "node:fs";
import { performance } from "node:perf_hooks";

const baseUrl = (process.env.BASE_URL || "https://redacta.site").replace(/\/$/, "");
const apiPath = process.env.API_PATH || "/api/v1/anonymization";
const rate = Number(process.env.RATE || 300);
const durationSeconds = Number(process.env.DURATION_SECONDS || 60);
const tickMs = Number(process.env.TICK_MS || 100);
const timeoutMs = Number(process.env.TIMEOUT_MS || 10000);
const maxFailureRate = Number(process.env.MAX_FAILURE_RATE || 0.01);
const maxP95Ms = Number(process.env.MAX_P95_MS || 300);
const summaryPath = process.env.SUMMARY_PATH;

const url = `${baseUrl}${apiPath}`;
const requestsPerTick = Math.max(1, Math.round((rate * tickMs) / 1000));
const totalTicks = Math.ceil((durationSeconds * 1000) / tickMs);
const latencies = [];
const statusCounts = new Map();
const checks = {
  total: 0,
  failed: 0,
  networkErrors: 0,
};

async function sendRequest() {
  const started = performance.now();
  checks.total += 1;

  try {
    const response = await fetch(url, {
      method: "GET",
      signal: AbortSignal.timeout(timeoutMs),
    });
    const latency = performance.now() - started;
    latencies.push(latency);

    const key = String(response.status);
    statusCounts.set(key, (statusCounts.get(key) || 0) + 1);

    if (response.status >= 500) {
      checks.failed += 1;
    }

    await response.arrayBuffer();
  } catch {
    checks.failed += 1;
    checks.networkErrors += 1;
    latencies.push(performance.now() - started);
  }
}

function percentile(values, percentileValue) {
  if (values.length === 0) {
    return 0;
  }

  const sorted = [...values].sort((a, b) => a - b);
  const index = Math.min(sorted.length - 1, Math.ceil((percentileValue / 100) * sorted.length) - 1);
  return sorted[index];
}

const startedAt = new Date().toISOString();
const started = performance.now();
const pending = [];

for (let tick = 0; tick < totalTicks; tick += 1) {
  const targetTime = started + tick * tickMs;
  const delay = targetTime - performance.now();

  if (delay > 0) {
    await new Promise((resolve) => setTimeout(resolve, delay));
  }

  for (let i = 0; i < requestsPerTick; i += 1) {
    pending.push(sendRequest());
  }
}

await Promise.allSettled(pending);

const finished = performance.now();
const actualDurationSeconds = (finished - started) / 1000;
const actualRate = checks.total / actualDurationSeconds;
const failureRate = checks.total === 0 ? 1 : checks.failed / checks.total;
const p95 = percentile(latencies, 95);
const p99 = percentile(latencies, 99);
const avg = latencies.length === 0
  ? 0
  : latencies.reduce((sum, value) => sum + value, 0) / latencies.length;

const summary = {
  startedAt,
  target: {
    url,
    rate,
    durationSeconds,
    maxFailureRate,
    maxP95Ms,
  },
  result: {
    totalRequests: checks.total,
    actualDurationSeconds: Number(actualDurationSeconds.toFixed(2)),
    actualRate: Number(actualRate.toFixed(2)),
    failedRequests: checks.failed,
    failureRate: Number(failureRate.toFixed(4)),
    networkErrors: checks.networkErrors,
    averageMs: Number(avg.toFixed(2)),
    p95Ms: Number(p95.toFixed(2)),
    p99Ms: Number(p99.toFixed(2)),
    statusCounts: Object.fromEntries([...statusCounts.entries()].sort()),
  },
  pass: failureRate < maxFailureRate && p95 < maxP95Ms,
};

const output = JSON.stringify(summary, null, 2);
console.log(output);

if (summaryPath) {
  writeFileSync(summaryPath, `${output}\n`);
}

if (!summary.pass) {
  process.exitCode = 1;
}
