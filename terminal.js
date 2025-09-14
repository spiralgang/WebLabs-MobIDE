import { files, openFile } from './files.js';
import { runAIChat } from './ai.js';

export function initTerminal(container) {
  container.innerHTML = `<div id="terminal"></div>`;
  const term = new Terminal({ theme: { background: '#181f2a', foreground: '#5eead4' }, fontFamily: 'Fira Code, monospace', fontSize: 15 });
  term.open(document.getElementById('terminal'));
  term.write('QuantumWebIDE Terminal Ready!\r\n> ');
  let cmd = '';
  term.onData(data => {
    if (data === '\r') {
      term.write('\r\n');
      handleCmd(cmd.trim(), term);
      cmd = '';
      term.write('> ');
    } else if (data === '\u007F') {
      if (cmd.length > 0) {
        term.write('\b \b'); cmd = cmd.slice(0, -1);
      }
    } else { term.write(data); cmd += data;}
  });
}

function handleCmd(cmd, term) {
  if (!cmd) return;
  if (cmd === 'help') {
    term.write('Commands: help, ls, cat <file>, edit <file>, proxy <url>, ai <msg>\r\n'); return;
  }
  if (cmd === 'ls') { term.write(Object.keys(files).join('  ') + '\r\n'); return; }
  if (cmd.startsWith('cat ')) { term.write((files[cmd.slice(4).trim()] || 'File not found.') + '\r\n'); return; }
  if (cmd.startsWith('edit ')) { openFile(cmd.slice(5).trim()); term.write('Editing ' + cmd.slice(5).trim() + '\r\n'); return; }
  if (cmd.startsWith('ai ')) { runAIChat(cmd.slice(3).trim(),"cli",out=>term.write(out+'\r\n')); return; }
  term.write('Unknown command. Type help.\r\n');
}