import { aiKey } from './ai.js';

export function loadSettings(container) {
  container.innerHTML = `
    <h3>System Settings</h3>
    <label>AI API Key: <input id="settings-ai-key" class="chat-input" placeholder="Paste DeepSeek/HuggingFace token"></label>
    <label>Theme: <select id="settings-theme" class="chat-input">
      <option value="dark">Dark</option>
      <option value="light">Light</option>
    </select></label>
  `;
  document.getElementById('settings-ai-key').onchange = e => {
    aiKey = e.target.value.trim();
  };
  document.getElementById('settings-theme').onchange = e => {
    document.body.style.background = e.target.value === "light" ? "#f9fafb" : "#111827";
    document.body.style.color = e.target.value === "light" ? "#181f2a" : "#e5e7eb";
  };
}