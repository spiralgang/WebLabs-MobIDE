export function initProxy(container) {
  container.innerHTML = `
    <div class="output" id="proxy-output">Proxy system ready.</div>
    <input id="proxy-url" class="chat-input" placeholder="URL">
    <input id="proxy-method" class="chat-input" style="width:90px;" value="GET">
    <textarea id="proxy-headers" class="chat-input" style="height:40px;" placeholder='{"Authorization":"Bearer ..."}'></textarea>
    <textarea id="proxy-body" class="chat-input" style="height:40px;" placeholder="Body (JSON)"></textarea>
    <button class="btn" id="proxy-send-btn">Send Proxy Request</button>
  `;
  document.getElementById('proxy-send-btn').onclick = async () => {
    const url = document.getElementById('proxy-url').value.trim();
    const method = document.getElementById('proxy-method').value.trim();
    let headers = {};
    try { headers = JSON.parse(document.getElementById('proxy-headers').value || "{}"); } catch(e){}
    let body = document.getElementById('proxy-body').value.trim();
    let options = { method, headers };
    if (body) options.body = body;
    try {
      let res = await fetch(url, options);
      let text = await res.text();
      document.getElementById('proxy-output').textContent = text.slice(0,2000);
    } catch(e) {
      document.getElementById('proxy-output').textContent = "Proxy error: "+e.message;
    }
  };
}