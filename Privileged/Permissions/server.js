// Minimal Express server to serve Web UI, queue endpoints, artifacts, and AI calls.
// Designed to run under nodejs-mobile or normal node (port 3000).
const express = require('express');
const bodyParser = require('body-parser');
const path = require('path');
const fs = require('fs');
const multer = require('multer');
const cors = require('cors');
const { sendPrompt } = require('./providers');

const app = express();
const PORT = process.env.PORT || 3000;
const BASE = process.env.ICEDMAN_BASE || path.join(process.env.HOME || '.', 'icedman');
const QUEUE_DIR = path.join(BASE, 'bot', 'queue');
const RESPOND_DIR = path.join(QUEUE_DIR, 'respond');
const ARTIFACTS_DIR = path.join(BASE, 'weave_artifacts');

fs.mkdirSync(QUEUE_DIR, { recursive: true });
fs.mkdirSync(RESPOND_DIR, { recursive: true });
fs.mkdirSync(ARTIFACTS_DIR, { recursive: true });

app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, '..', 'www')));

// API: send a prompt to configured provider
app.post('/api/ai', async (req, res) => {
  const prompt = req.body.prompt || req.query.prompt || '';
  const provider = req.body.provider || req.query.provider;
  if (!prompt) return res.status(400).json({ error: 'prompt required' });
  const out = await sendPrompt(prompt, { provider, max_tokens: 800 });
  res.json({ result: out });
});

// API: write a .cmd file to queue (simulate dispatcher)
app.post('/api/queue', (req, res) => {
  const name = req.body.name || `cmd_${Date.now()}`;
  const cmd = req.body.cmd || req.body.prompt || '';
  if (!cmd) return res.status(400).json({ error: 'cmd required' });
  const file = path.join(QUEUE_DIR, `${name}.cmd`);
  fs.writeFileSync(file, cmd, { encoding: 'utf8' });
  res.json({ queued: file });
});

// API: list artifacts
app.get('/api/artifacts', (req, res) => {
  const items = fs.readdirSync(ARTIFACTS_DIR).filter(Boolean).map(f => {
    const s = fs.statSync(path.join(ARTIFACTS_DIR, f));
    return { file: f, path: `/artifacts/${encodeURIComponent(f)}`, mtime: s.mtimeMs, size: s.size };
  }).sort((a,b)=>b.mtime-a.mtime);
  res.json(items);
});

// Serve artifact files
app.get('/artifacts/:name', (req, res) => {
  const name = req.params.name;
  const file = path.join(ARTIFACTS_DIR, name);
  if (!fs.existsSync(file)) return res.status(404).send('not found');
  res.sendFile(file);
});

// list queue
app.get('/api/queue', (req,res) => {
  const files = fs.readdirSync(QUEUE_DIR).filter(f=>f.endsWith('.cmd')).map(f => ({file:f, path: `/queue/${f}`}));
  res.json(files);
});

// read response files
app.get('/api/respond/:name', (req,res) => {
  const file = path.join(RESPOND_DIR, req.params.name);
  if (!fs.existsSync(file)) return res.status(404).json({error:'not found'});
  res.sendFile(file);
});

// small health endpoint
app.get('/api/status', (req,res) => {
  res.json({ status: 'ok', now: Date.now(), base: BASE });
});

// Provide a simple UI route root (index.html in www)
app.get('/', (req,res)=> {
  res.sendFile(path.join(__dirname, '..', 'www', 'index.html'));
});

app.listen(PORT, () => {
  console.log(`UBULITE ICEDMAN server listening on ${PORT}`);
});