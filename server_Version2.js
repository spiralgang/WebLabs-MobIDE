// Node.js backend for aarch64 Linux WebIDE with SU privileged shell

const express = require('express');
const bodyParser = require('body-parser');
const child_process = require('child_process');
const fs = require('fs');
const jwt = require('jsonwebtoken'); // For signed key auth, use your public/private keys

const app = express();
app.use(bodyParser.json());

// Auth middleware: expect user to provide JWT signed with private key
app.use((req, res, next) => {
    const auth = req.headers['authorization'];
    if (!auth) return res.status(401).send('No auth token');
    try {
        const token = auth.replace('Bearer ','');
        jwt.verify(token, fs.readFileSync('public.pem'));
        next();
    } catch(e) {
        return res.status(403).send('Invalid signature');
    }
});

// Run any command as root via su binary
app.post('/api/su', (req,res) => {
    const cmd = req.body.command;
    if (!cmd) return res.status(400).send('No command');
    child_process.exec(`su -c "${cmd.replace(/"/g,'\\"')}"`, (err, stdout, stderr) => {
        if (err) return res.status(500).send(stderr || err.message);
        res.send(stdout || 'No output');
    });
});

// Run a shell script as root
app.post('/api/su-script', (req,res) => {
    const script = req.body.script;
    if (!script) return res.status(400).send('No script');
    fs.writeFileSync('/tmp/webide-script.sh', script);
    child_process.exec(`su -c "bash /tmp/webide-script.sh"`, (err, stdout, stderr) => {
        if (err) return res.status(500).send(stderr || err.message);
        res.send(stdout || 'No output');
    });
});

app.listen(8080, () => {
    console.log("WebIDE backend running on port 8080 (privileged SU shell)");
});