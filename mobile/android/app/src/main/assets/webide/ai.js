// import { files } from './files.js'; // Removed: file does not exist
// Minimal implementation for files object; replace with actual file loading as needed
const files = {
  "README.md": "Welcome to QuantumWebIDE!\nThis is a sample file.",
  "main.js": "// Main JS file\nconsole.log('Hello, world!');"
};

let aiKey = "";

export function initAIChat(container) {
  container.innerHTML = `
    <div class="chatbox" id="chatbox"></div>
    <div class="flex">
      <input id="chat-input" class="chat-input" placeholder="Ask anything...">
      <button class="btn" id="chat-send-btn">Send</button>
    </div>
  `;
  document.getElementById('chat-send-btn').onclick = () => {
    let val = document.getElementById('chat-input').value.trim();
    if (!val) return;
    runAIChat(val);
    document.getElementById('chat-input').value = '';
  };
}

export async function runAIChat(prompt, source="chat", cb) {
  addChatMsg(source==="cli"?"CLI":"You",prompt);
  let repoContext = Object.keys(files).map(f=>`${f}:\n${files[f].slice(0,300)}`).join('\n\n');
  let userMsg = `QuantumWebIDE, Mobile-First, Android 10+/Aarch64. Files:\n${repoContext}\n\n${prompt}`;
  let answer = await queryAI([{role:"user",content:userMsg}]);
  addChatMsg("AI",answer);
  if(cb) cb(answer);
}

function addChatMsg(user, text) {
  let chatbox = document.getElementById('chatbox');
  let div = document.createElement('div');
  div.className = 'chat-msg';
  div.innerHTML = `<span class="${user==='AI'?'chat-ai':'chat-user'}">${user}:</span> <span class="chat-text">${text}</span>`;
  chatbox.appendChild(div);
  chatbox.scrollTop = chatbox.scrollHeight;
}

async function queryAI(messages, model="deepseek-ai/DeepSeek-R1:fireworks-ai") {
  if(!aiKey) return "AI key not set. Paste in settings.";
  try {
    const response = await fetch("https://router.huggingface.co/v1/chat/completions",{
      headers: { Authorization: "Bearer "+aiKey, "Content-Type":"application/json"},
      method: "POST",
      body: JSON.stringify({messages,top_p:1,model}),
    });
    const result = await response.json();
    if(result.choices && result.choices.length>0) return result.choices[0].message.content;
    return result.error||"AI error: Unexpected response";
  } catch(e){ return "AI error: "+e.message;}
}