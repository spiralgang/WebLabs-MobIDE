#!/usr/bin/env node
// Generates a JWT from GITHUB_APP_PRIVATE_KEY and exchanges it for an installation access token.
// Usage: Set env GITHUB_APP_PRIVATE_KEY, GITHUB_APP_ID, GITHUB_APP_INSTALLATION_ID and run this script.
// This script prints the installation access token to stdout ONLY (no logs of secrets).

const https = require('https');
const { createSign } = require('crypto');

function base64url(input) {
  return Buffer.from(input).toString('base64')
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function nowSeconds() {
  return Math.floor(Date.now() / 1000);
}

const PRIVATE_KEY = process.env.GITHUB_APP_PRIVATE_KEY;
const APP_ID = process.env.GITHUB_APP_ID;
const INSTALLATION_ID = process.env.GITHUB_APP_INSTALLATION_ID;

if (!PRIVATE_KEY || !APP_ID || !INSTALLATION_ID) {
  console.error('Missing GITHUB_APP_PRIVATE_KEY or GITHUB_APP_ID or GITHUB_APP_INSTALLATION_ID');
  process.exit(2);
}

// Build JWT
const header = { alg: "RS256", typ: "JWT" };
const iat = nowSeconds();
const exp = iat + (9 * 60); // 9 minutes TTL (GitHub max 10 minutes)
const payload = { iat, exp, iss: APP_ID };

const signingInput = base64url(JSON.stringify(header)) + '.' + base64url(JSON.stringify(payload));
const sign = createSign('RSA-SHA256');
sign.update(signingInput);
sign.end();
let signature;
try {
  signature = sign.sign(PRIVATE_KEY);
} catch (e) {
  console.error('Failed to sign JWT with private key:', e.message || e);
  process.exit(3);
}
const jwt = signingInput + '.' + base64url(signature);

// Exchange JWT for installation token
const options = {
  hostname: 'api.github.com',
  path: `/app/installations/${INSTALLATION_ID}/access_tokens`,
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${jwt}`,
    'Accept': 'application/vnd.github+json',
    'User-Agent': 'github-action-get-app-token'
  }
};

const req = https.request(options, (res) => {
  let data = '';
  res.on('data', (d) => data += d);
  res.on('end', () => {
    try {
      const parsed = JSON.parse(data);
      if (parsed.token) {
        // Print only the token so the workflow can capture it
        process.stdout.write(parsed.token);
        process.exit(0);
      } else {
        console.error('No token in response', parsed);
        process.exit(4);
      }
    } catch (e) {
      console.error('Failed to parse response from GitHub API:', e.message || e);
      console.error('Raw response:', data);
      process.exit(5);
    }
  });
});
req.on('error', (err) => {
  console.error('Request error:', err.message || err);
  process.exit(6);
});
req.end();