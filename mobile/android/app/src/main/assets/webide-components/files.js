export let files = {
  "README.md": "# QuantumWebIDE\nMobile-first, privileged shell.",
  "main.sh": "#!/bin/bash\necho 'Ready.'"
};
let activeFile = "README.md";

export function openFile(fname) {
  if (fname && files[fname]) activeFile = fname;
  return activeFile;
}
export function saveFile(content) { files[activeFile] = content; }
export function deleteFile() { delete files[activeFile]; activeFile = Object.keys(files)[0];}
export function downloadFile() {
  const a = document.createElement('a');
  a.href = URL.createObjectURL(new Blob([files[activeFile]], {type: "text/plain"}));
  a.download = activeFile;
  a.click();
}