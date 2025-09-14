import { files, openFile, saveFile, deleteFile, downloadFile } from './files.js';

export function initEditor(container) {
  container.innerHTML = `
    <textarea id="editor" style="width:100%;height:180px;"></textarea>
    <div>
      <button id="save-file-btn" class="btn">Save</button>
      <button id="new-file-btn" class="btn">New File</button>
      <button id="delete-file-btn" class="btn">Delete File</button>
      <button id="download-file-btn" class="btn">Download File</button>
    </div>
  `;
  document.getElementById('editor').value = files[openFile()] || '';
  document.getElementById('save-file-btn').onclick = () => saveFile(document.getElementById('editor').value);
  document.getElementById('new-file-btn').onclick = () => openFile(prompt("New file name:"));
  document.getElementById('delete-file-btn').onclick = () => deleteFile();
  document.getElementById('download-file-btn').onclick = () => downloadFile();
}