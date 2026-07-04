import { githubWrite, shellRun, auditLog } from './integrations.js';

export function initAIChat(container) {
  container.innerHTML = `
    <div class="chatbox" id="chatbox"></div>
    <input id="chat-input" class="chat-input" placeholder="Ask anything (build, refactor, deploy)">
    <button class="btn" id="chat-send-btn">Send</button>
  `;
  document.getElementById('chat-send-btn').onclick = async () => {
    let val = document.getElementById('chat-input').value.trim();
    if (!val) return;
    addChatMsg('You', val);
    // Call DeepSeek/HF API
    let result = await aiExecute(val);
    addChatMsg('AI', result.message);
    // If result includes action (code, command), execute directly
    if (result.action === 'write_file') {
      await githubWrite(result.file, result.content);
      auditLog('write_file', result.file);
    }
    if (result.action === 'run_shell') {
      let shellResult = await shellRun(result.command);
      auditLog('run_shell', result.command, shellResult);
      addChatMsg('Shell', shellResult.output);
    }
  };
}