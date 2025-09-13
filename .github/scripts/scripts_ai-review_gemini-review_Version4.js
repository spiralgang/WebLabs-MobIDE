#!/usr/bin/env node
/**
 * Gemini review runner — secure auth support
 *
 * Authentication modes:
 *  - gcloud (recommended): short-lived GEMINI_ACCESS_TOKEN obtained via GitHub OIDC -> GCP Workload Identity.
 *  - secret (fallback): GEMINI_API_KEY stored as a repository secret (used when calling an internal proxy).
 *
 * Behavior:
 *  - Use GEMINI_ACCESS_TOKEN if present, otherwise GEMINI_API_KEY.
 *  - Do NOT print tokens or secrets to logs.
 *  - Fail clearly if neither token nor API key is available and explain required secrets.
 *
 * Output:
 *  - Writes artifacts/gemini-review-<sha>.json with model request/response (no secrets).
 *
 * Vault references and operational guidance in the end-of-file "References".
 */

import { execSync } from "child_process";
import { existsSync, mkdirSync, readFileSync, statSync, writeFileSync } from "fs";
import https from "https";
import http from "http";
import { env, exit } from "process";
import { URL } from "url";

const MAX_FILE_BYTES = 300 * 1024;
const MAX_PROMPT_CHARS_PER_FILE = 32 * 1024;
const MAX_FILES_IN_PROMPT = 75;

const MODEL = env.GEMINI_MODEL || "gemini-pro-2.5";
const API_ENDPOINT = env.GEMINI_API_ENDPOINT;
const API_KEY = env.GEMINI_API_KEY || null;            // secret-based fallback
const ACCESS_TOKEN = env.GEMINI_ACCESS_TOKEN || null;  // preferred for OIDC/GCP
const AUTH_MODE = env.GEMINI_AUTH_MODE || 'secret';

function fatal(code, msg) {
  console.error(msg);
  process.exit(code);
}

// Ensure we have an endpoint
if (!API_ENDPOINT) {
  fatal(2, "Missing GEMINI_API_ENDPOINT. Store the endpoint in repository secrets as GEMINI_API_ENDPOINT.");
}

// Auth selection logic: prefer short-lived access token
if (!ACCESS_TOKEN && !API_KEY) {
  fatal(2, `No usable authentication found. Set one of:
  - (recommended) Configure Workload Identity: set GEMINI_AUTH_MODE=gcloud and secrets GCP_WORKLOAD_IDENTITY_PROVIDER & GCP_SERVICE_ACCOUNT_EMAIL in the workflow, or
  - (fallback) set GEMINI_API_KEY as a repository secret for proxy endpoints.
  See repository docs for setup.`);
}

// Prevent flash variants
if (/flash/i.test(MODEL)) {
  fatal(3, `Model "${MODEL}" appears to be a "flash" variant. This workflow enforces non-flash Gemini Pro models.`);
}

// Helper: safe shell run
function run(cmd) {
  try {
    return execSync(cmd, { encoding: 'utf8', stdio: ['pipe', 'pipe', 'ignore'] }).trim();
  } catch {
    return '';
  }
}

function getChangedFiles() {
  run('git fetch origin main --depth=1 || true');
  const diff = run('git diff --name-only origin/main...HEAD') || run('git show --name-only --pretty="" HEAD') || run('git ls-files');
  return diff.split('\n').filter(Boolean);
}

function readFileSnippet(path) {
  try {
    const size = statSync(path).size;
    if (size > MAX_FILE_BYTES) return `<<skipped ${path} (size ${size} bytes) - exceeds ${MAX_FILE_BYTES} bytes limit>>`;
    const content = readFileSync(path, 'utf8');
    return content.length > MAX_PROMPT_CHARS_PER_FILE ? content.slice(0, MAX_PROMPT_CHARS_PER_FILE) + "\n<<truncated>>" : content;
  } catch (e) {
    return `<<unreadable ${path}: ${String(e)}>>`;
  }
}

function buildPrompt(changedFiles) {
  const header = [
    `You are an advanced automated reviewer: "Gemini Pro 2.5 (high-level)"`,
    `Standards: ${env.STANDARDS || 'vault'}`,
    `Model directive: Use "${MODEL}". NEVER use any "flash" variant.`,
    "",
    "Required output: JSON: { summary, issues[], suggestions[], confidence }. Issues must include file, category, severity.",
    "",
    "Changed files (truncated where necessary):",
    ""
  ].join("\n");

  const fileBodies = changedFiles.map(p => {
    const content = readFileSnippet(p);
    return `-- ${p} --\n${content}\n`;
  });

  const tail = [
    "",
    "Return strict JSON only. If uncertain, mark findings with low confidence.",
  ].join("\n");

  return [header, ...fileBodies, tail].join("\n");
}

async function postJson(endpoint, tokenOrKey, body, useBearer = true) {
  const url = new URL(endpoint);
  const payload = JSON.stringify(body);
  const isHttps = url.protocol === 'https:';
  const options = {
    hostname: url.hostname,
    port: url.port || (isHttps ? 443 : 80),
    path: url.pathname + url.search,
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(payload),
      Authorization: useBearer ? `Bearer ${tokenOrKey}` : `${tokenOrKey}`
    }
  };

  return new Promise((resolve, reject) => {
    const lib = isHttps ? https : http;
    const req = lib.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        try { resolve({ status: res.statusCode, body: JSON.parse(data) }); }
        catch { resolve({ status: res.statusCode, body: data }); }
      });
    });
    req.on('error', reject);
    req.write(payload);
    req.end();
  });
}

(async function main() {
  try {
    const changed = getChangedFiles();
    if (!changed.length) {
      console.log("No changed files detected. Nothing to review.");
      process.exit(0);
    }
    console.log(`Detected ${changed.length} changed files; including up to ${MAX_FILES_IN_PROMPT} files.`);
    const selected = changed.slice(0, MAX_FILES_IN_PROMPT);

    const prompt = buildPrompt(selected);
    const requestPayload = {
      model: MODEL,
      input: prompt,
      meta: {
        commit: env.CI_COMMIT_SHA || run('git rev-parse HEAD'),
        pr: env.CI_PR_NUMBER || ''
      },
      options: { temperature: 0.0, max_output_tokens: 2000 }
    };

    console.log("Preparing request to model endpoint (auth mode: " + AUTH_MODE + ")...");
    // Choose header token without printing it
    const token = ACCESS_TOKEN || API_KEY;
    const useBearer = Boolean(ACCESS_TOKEN || true); // default to Bearer, most endpoints accept Bearer
    const res = await postJson(API_ENDPOINT, token, requestPayload, useBearer);

    // Save artifact without secrets
    const artifactsDir = './artifacts';
    if (!existsSync(artifactsDir)) mkdirSync(artifactsDir, { recursive: true });
    const sha = (env.CI_COMMIT_SHA || run('git rev-parse --short HEAD') || 'unknown').slice(0,12);
    const artifactPath = `${artifactsDir}/gemini-review-${sha}.json`;
    const artifact = {
      meta: requestPayload.meta,
      model_request: { model: requestPayload.model, input_summary: `(omitted)`, options: requestPayload.options },
      model_response: res,
      generated_at: new Date().toISOString()
    };
    writeFileSync(artifactPath, JSON.stringify(artifact, null, 2));
    console.log("Wrote artifact:", artifactPath);
    process.exit(0);
  } catch (err) {
    console.error("Runtime error during Gemini review:", err);
    exit(4);
  }
})();