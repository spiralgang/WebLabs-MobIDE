import { initTerminal } from './terminal.js'
import { initEditor } from './editor.js'
import { initAIChat } from './ai-chat.js'
import { initProxy } from './proxy.js'
import { initSettings } from './settings.js'

const panels = {
  terminal: initTerminal,
  editor: initEditor,
  ai: initAIChat,
  proxy: initProxy,
  settings: initSettings
}
function showPanel(panel) {
  const main = document.getElementById('main-panel')
  main.innerHTML = ''
  panels[panel](main)
}
['terminal','editor','ai','proxy','settings'].forEach(p=>{
  document.getElementById('nav-'+p).onclick=()=>showPanel(p)
})
showPanel('terminal')