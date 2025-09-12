- name: Salesforce/codet5-small

on: [Mannual], [Trigger]
  push:
    branches:
      - 'master' , 'main', 'WebOps'

jobs:
  import_model: https://huggingface.co/Salesforce/codet5-small
    runs-on: self-hosted
    steps:
      - name: Checkout code
        uses: actions/checkout@v2

      - name: Set up Python
        uses: actions/setup-python@v2
        with:
          python-version: '3.8'

      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          git lfs install
          git hf_cli install 

      - name: 
        run: |
          python import_model.py
          git clone https://huggingface.co/Salesforce/codet5-small.git
          hf download Salesforce/codet5-small
       $echo
fi

done

# <-- 
# Advance To Production Stage 
# Professional Coding Repository Contributor 
# Draft 'Project Roadmap && Process Substance Review.md' 
# -->

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Privilege Manager Dashboard</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    fontFamily: {
                        sans: ['Inter', 'sans-serif'],
                        mono: ['Fira Code', 'monospace']
                    }
                }
            }
        }
    </script>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;700&family=Fira+Code:wght@400;700&display=swap');
        body {
            font-family: 'Inter', sans-serif;
            background-color: #111827;
            color: #d1d5db;
        }
        .terminal-output {
            background-color: #1f2937;
            border-radius: 0.75rem;
            padding: 1rem;
            height: 300px;
            overflow-y: auto;
            white-space: pre-wrap;
            word-wrap: break-word;
            font-family: 'Fira Code', monospace;
            font-size: 0.875rem;
        }
    </style>
</head>
<body class="p-4 sm:p-8 flex flex-col items-center min-h-screen">
    <div class="max-w-4xl w-full">
        <div class="bg-gray-800 p-6 rounded-2xl shadow-xl border border-gray-700">
            <h1 class="text-3xl sm:text-4xl font-bold text-white mb-2">Privilege Dashboard</h1>
            <p class="text-gray-400 mb-6">A safe, simulated environment for interacting with superuser binaries and tools.</p>

            <!-- IMPORTANT DISCLAIMER -->
            <div class="bg-red-900 bg-opacity-30 border border-red-700 p-4 rounded-xl text-red-300 font-bold mb-6">
                <p>⚠️ **Disclaimer:** This is a simulated environment. It does not have actual root privileges and cannot execute commands on your system. It is for educational and demonstrative purposes only.</p>
            </div>

            <!-- Privilege Tools Section -->
            <div class="mb-6">
                <h2 class="text-2xl font-semibold text-gray-200 mb-4">SU Binaries & Tools</h2>
                <div id="tools-list" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                    <!-- Tools will be injected here by JavaScript -->
                </div>
            </div>

            <!-- Terminal Area -->
            <div class="relative">
                <div id="terminal-output" class="terminal-output mb-4">
                    <p class="text-gray-500">Welcome to the simulated privileged shell. Type `help` to see available commands.</p>
                </div>
                <div class="flex items-center space-x-2">
                    <span class="text-green-400 font-bold">sim_user@web-shell:~$</span>
                    <input type="text" id="terminal-input" class="flex-1 bg-gray-700 text-gray-200 rounded-lg p-2 font-mono outline-none focus:ring-2 focus:ring-blue-500 transition-all" autofocus>
                </div>
            </div>
        </div>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', () => {

            // --- Embedded JSON Data ---
            const SECURITY_TOOLS = {
                "su_binaries": {
                    "description": "Superuser binary implementations",
                    "sources": [
                        "https://github.com/topjohnwu/Magisk",
                        "https://su-binary.com/",
                        "https://android.googlesource.com/platform/system/extras/+/master/su/"
                    ],
                    "implementations": [{
                        "name": "Magisk SU",
                        "description": "Modern Android superuser solution",
                        "features": [
                            "systemless",
                            "hide_detection",
                            "module_support"
                        ]
                    }, {
                        "name": "LineageOS SU",
                        "description": "Built-in superuser for LineageOS",
                        "features": [
                            "integrated",
                            "privacy_guard",
                            "per_app_permissions"
                        ]
                    }]
                },
                "keystores": {
                    "description": "Android keystore and certificate management",
                    "types": [{
                        "name": "AI Keystore",
                        "description": "Hardware-backed key storage",
                        "location": "/system/etc/security/cacerts/"
                    }, {
                        "name": "AI Certificates",
                        "description": "User-installed certificates",
                        "location": "/data/misc/user/0/cacerts-added/"
                    }]
                },
                "ca_certificates": {
                    "description": "Certificate Authority certificates",
                    "system_locations": [
                        "/system/etc/security/cacerts/",
                        "/apex/com.android.conscrypt/cacerts/",
                        "/etc/ssl/certs/"
                    ],
                    "management_commands": [
                        "update-ca-certificates",
                        "trust anchor",
                        "keytool -importcert"
                    ]
                },
                "privilege_escalation": {
                    "description": "Privilege escalation methods",
                    "methods": [{
                        "name": "su command",
                        "description": "Switch user to root",
                        "syntax": "su [options]"
                    }]
                }
            };

            const terminalOutput = document.getElementById('terminal-output');
            const terminalInput = document.getElementById('terminal-input');
            const toolsList = document.getElementById('tools-list');

            let commandHistory = [];
            let historyIndex = -1;

            // Function to append text to the terminal output
            function appendToTerminal(text) {
                const line = document.createElement('p');
                line.textContent = text;
                terminalOutput.appendChild(line);
                terminalOutput.scrollTop = terminalOutput.scrollHeight; // Scroll to bottom
            }

            // Function to simulate command execution
            function executeCommand(command) {
                const parts = command.trim().split(/\s+/);
                const cmd = parts[0];

                appendToTerminal(`> sim_user@web-shell:~$ ${command}`);

                switch (cmd) {
                    case 'help':
                        appendToTerminal(`\nAvailable simulated commands:`);
                        appendToTerminal(`- su [--version]`);
                        appendToTerminal(`- keystore list`);
                        appendToTerminal(`- certs list`);
                        appendToTerminal(`- magisk info`);
                        appendToTerminal(`- clear`);
                        break;
                    case 'su':
                        if (parts[1] === '--version') {
                            const su = SECURITY_TOOLS.su_binaries.implementations[0];
                            appendToTerminal(`\n${su.name} (Simulated)`);
                            appendToTerminal(`Version: v25.2`);
                            appendToTerminal(`Features: ${su.features.join(', ')}`);
                        } else {
                            appendToTerminal(`\nsu: Permission granted.`);
                            appendToTerminal(`\nThis is a simulated root shell. No real changes will be made.`);
                        }
                        break;
                    case 'keystore':
                        if (parts[1] === 'list') {
                            appendToTerminal(`\nListing simulated Android keystore types:`);
                            SECURITY_TOOLS.keystores.types.forEach(type => {
                                appendToTerminal(`- Name: ${type.name}`);
                                appendToTerminal(`  Description: ${type.description}`);
                                appendToTerminal(`  Location: ${type.location}`);
                                appendToTerminal(``);
                            });
                        } else {
                            appendToTerminal(`\nInvalid 'keystore' command. Use 'keystore list'.`);
                        }
                        break;
                    case 'certs':
                        if (parts[1] === 'list') {
                            appendToTerminal(`\nListing simulated CA certificate locations:`);
                            SECURITY_TOOLS.ca_certificates.system_locations.forEach(loc => {
                                appendToTerminal(`- ${loc}`);
                            });
                        } else {
                            appendToTerminal(`\nInvalid 'certs' command. Use 'certs list'.`);
                        }
                        break;
                    case 'magisk':
                         if (parts[1] === 'info') {
                             const magisk = SECURITY_TOOLS.su_binaries.implementations.find(i => i.name.includes('Magisk'));
                             if (magisk) {
                                 appendToTerminal(`\nSimulated Magisk Info:`);
                                 appendToTerminal(`Name: ${magisk.name}`);
                                 appendToTerminal(`Description: ${magisk.description}`);
                                 appendToTerminal(`Features: ${magisk.features.join(', ')}`);
                             } else {
                                 appendToTerminal(`\nSimulated Magisk info not found.`);
                             }
                         } else {
                            appendToTerminal(`\nInvalid 'magisk' command. Use 'magisk info'.`);
                         }
                         break;
                    case 'clear':
                        terminalOutput.innerHTML = '';
                        break;
                    default:
                        appendToTerminal(`\nCommand not found: ${cmd}`);
                        break;
                }
                appendToTerminal(``);
            }

            // Function to render tool buttons from JSON
            function renderTools() {
                const binaries = SECURITY_TOOLS.su_binaries.implementations;
                binaries.forEach(binary => {
                    const toolCard = document.createElement('div');
                    toolCard.className = "bg-gray-700 p-4 rounded-xl shadow-md border border-gray-600 cursor-pointer hover:bg-gray-600 transition-colors duration-200";
                    toolCard.innerHTML = `
                        <h3 class="font-bold text-gray-100">${binary.name}</h3>
                        <p class="text-sm text-gray-400 mt-1">${binary.description}</p>
                        <p class="text-xs text-gray-500 mt-2">Features: ${binary.features.join(', ')}</p>
                    `;
                    toolsList.appendChild(toolCard);
                });
            }

            // Event listener for keyboard input
            terminalInput.addEventListener('keydown', (event) => {
                if (event.key === 'Enter') {
                    const command = terminalInput.value;
                    if (command.trim() !== '') {
                        commandHistory.unshift(command);
                        historyIndex = -1;
                    }
                    executeCommand(command);
                    terminalInput.value = '';
                } else if (event.key === 'ArrowUp') {
                    event.preventDefault();
                    if (historyIndex < commandHistory.length - 1) {
                        historyIndex++;
                        terminalInput.value = commandHistory[historyIndex];
                    }
                } else if (event.key === 'ArrowDown') {
                    event.preventDefault();
                    if (historyIndex > -1) {
                        historyIndex--;
                        terminalInput.value = commandHistory[historyIndex] || '';
                    }
                }
            });

            // Initial render
            renderTools();
        });
    </script>
</body>
</html>
              },
              "privilege_escalation": {
                "description": "Privilege escalation is the act of exploiting a bug, design flaw, or configuration oversight in an operating system to gain elevated access. On Linux-based systems like Android, the `su` command is the primary legitimate method for switching to the root user.",
                "methods": [
                  {
                    "name": "su command",
                    "description": "The 'switch user' command allows a user to assume the identity of another user on the system, most commonly the root user, if they have the necessary permissions.",
                    "syntax": "su [options...] [-] [user [args...]]"
                  }
                ]
              }
            };

            const contentContainer = document.getElementById('content-container');
            const navLinks = document.querySelectorAll('#nav-links a');
            const sidebar = document.getElementById('sidebar');
            const menuBtn = document.getElementById('menu-btn');
            const mobileOverlay = document.getElementById('mobile-overlay');

            function renderOverview() {
                return `
                    <div id="overview-content" class="content-section space-y-8">
                        <div class="p-8 bg-white rounded-xl shadow-lg">
                            <h2 class="text-3xl font-bold text-slate-900 mb-4">Welcome to the Security Explorer</h2>
                            <p class="text-lg text-slate-600">This interactive application provides a structured overview of key security components in Android and Linux systems. The information is sourced from a detailed compilation of security tools and concepts. Use the navigation on the left to explore different topics, from Superuser binaries to privilege escalation techniques.</p>
                            <p class="mt-4 text-slate-600">Each section is designed to present the information in a clear and accessible format, turning complex data into an easy-to-understand reference guide.</p>
                        </div>
                    </div>
                `;
            }

            function renderTsuBinaries(data) {
                const implementationsHtml = data.implementations.map(impl => `
                    <div class="bg-white rounded-xl shadow-lg overflow-hidden flex-1 min-w-[300px]">
                        <div class="p-6 bg-teal-500">
                            <h3 class="text-2xl font-bold text-white">${impl.name}</h3>
                        </div>
                        <div class="p-6 space-y-4">
                            <p class="text-slate-600">${impl.description}</p>
                            <div>
                                <h4 class="font-semibold text-slate-800 mb-2">Key Features:</h4>
                                <div class="flex flex-wrap gap-2">
                                    ${impl.features.map(feature => `<span class="bg-teal-100 text-teal-800 text-xs font-semibold px-2.5 py-0.5 rounded-full">${feature}</span>`).join('')}
                                </div>
                            </div>
                        </div>
                    </div>
                `).join('');

                return `
                    <div id="Tsu_binaries-content" class="content-section space-y-8">
                        <div>
                            <h2 class="text-3xl font-bold text-slate-900 mb-2">Superuser (SU) Binaries</h2>
                            <p class="text-lg text-slate-600">${data.description}</p>
                        </div>
                        <div class="flex flex-wrap gap-8">
                            ${implementationsHtml}
                        </div>
                    </div>
                `;
            }
            
            function renderKeystores(data) {
                 const typesHtml = data.types.map(type => `
                    <div class="bg-white rounded-xl shadow-lg p-6">
                        <h3 class="text-2xl font-bold text-slate-800">${type.name}</h3>
                        <p class="text-slate-600 mt-2 mb-4">${type.description}</p>
                        <div class="relative code-block">
                            <code class="block bg-slate-800 text-white p-4 rounded-lg text-sm font-mono">${type.location}</code>
                            <button class="copy-btn" data-copy="${type.location}">Copy</button>
                        </div>
                    </div>
                `).join('');
                return `
                    <div id="keystores-content" class="content-section space-y-8">
                         <div>
                            <h2 class="text-3xl font-bold text-slate-900 mb-2">Android Keystores</h2>
                            <p class="text-lg text-slate-600">${data.description}</p>
                        </div>
                        <div class="space-y-6">
                            ${typesHtml}
                        </div>
                    </div>
                `;
            }

            function renderCaCertificates(data) {
                return `
                    <div id="ca_certificates-content" class="content-section space-y-8">
                        <div>
                            <h2 class="text-3xl font-bold text-slate-900 mb-2">CA Certificates</h2>
                            <p class="text-lg text-slate-600">${data.description}</p>
                        </div>
                        <div class="grid md:grid-cols-2 gap-8">
                            <div class="bg-white rounded-xl shadow-lg p-6">
                                <h3 class="text-xl font-bold mb-4">System Locations</h3>
                                <ul class="space-y-3">
                                    ${data.system_locations.map(loc => `
                                        <li class="relative code-block">
                                            <code class="block bg-slate-100 text-slate-800 p-3 rounded-md text-sm font-mono">${loc}</code>
                                            <button class="copy-btn" data-copy="${loc}">Copy</button>
                                        </li>
                                    `).join('')}
                                </ul>
                            </div>
                            <div class="bg-white rounded-xl shadow-lg p-6">
                                <h3 class="text-xl font-bold mb-4">Management Commands</h3>
                                <ul class="space-y-3">
                                    ${data.management_commands.map(cmd => `
                                        <li class="relative code-block">
                                            <code class="block bg-slate-100 text-slate-800 p-3 rounded-md text-sm font-mono">${cmd}</code>
                                            <button class="copy-btn" data-copy="${cmd}">Copy</button>
                                        </li>
                                    `).join('')}
                                </ul>
                            </div>
                        </div>
                    </div>
                `;
            }

            function renderPrivilegeEscalation(data) {
                const methodsHtml = data.methods.map(method => `
                     <div class="bg-white rounded-xl shadow-lg p-6">
                        <h3 class="text-2xl font-bold text-slate-800">${method.name}</h3>
                        <p class="text-slate-600 mt-2 mb-4">${method.description}</p>
                        <div class="relative code-block">
                            <h4 class="font-semibold text-slate-800 mb-2">Example Syntax:</h4>
                            <code class="block bg-slate-800 text-white p-4 rounded-lg text-sm font-mono">${method.syntax}</code>
                            <button class="copy-btn" data-copy="${method.syntax}">Copy</button>
                        </div>
                    </div>
                `).join('');

                return `
                    <div id="privilege_escalation-content" class="content-section space-y-8">
                        <div>
                            <h2 class="text-3xl font-bold text-slate-900 mb-2">Privilege Escalation</h2>
                            <p class="text-lg text-slate-600">${data.description}</p>
                        </div>
                        <div class="space-y-6">
                            ${methodsHtml}
                        </div>
                    </div>
                `;
            }

            function renderAllContent() {
                contentContainer.innerHTML = `
                    ${renderOverview()}
                    ${renderSuBinaries(securityData.su_binaries)}
                    ${renderKeystores(securityData.keystores)}
                    ${renderCaCertificates(securityData.ca_certificates)}
                    ${renderPrivilegeEscalation(securityData.privilege_escalation)}
                `;
            }

            function navigateToSection(sectionId) {
                document.querySelectorAll('.content-section').forEach(section => {
                    section.classList.remove('active');
                });
                const activeSection = document.getElementById(`${sectionId}-content`);
                if (activeSection) {
                    activeSection.classList.add('active');
                }

                navLinks.forEach(link => {
                    link.classList.toggle('active', link.dataset.section === sectionId);
                });
                
                window.location.hash = sectionId;

                // Close sidebar on mobile after navigation
                if (window.innerWidth < 768) {
                    sidebar.classList.add('-translate-x-full');
                    mobileOverlay.classList.add('hidden');
                }
            }
            
            renderAllContent();
            
            const initialSection = window.location.hash ? window.location.hash.substring(1) : 'overview';
            navigateToSection(initialSection);

            navLinks.forEach(link => {
                link.addEventListener('click', (e) => {
                    e.preventDefault();
                    const sectionId = e.currentTarget.dataset.section;
                    navigateToSection(sectionId);
                });
            });

            contentContainer.addEventListener('click', (e) => {
                if (e.target.matches('.copy-btn')) {
                    const textToCopy = e.target.dataset.copy;
                    navigator.clipboard.writeText(textToCopy).then(() => {
                        e.target.textContent = 'Copied!';
                        setTimeout(() => { e.target.textContent = 'Copy'; }, 2000);
                    }).catch(err => {
                        console.error('Failed to copy text: ', err);
                    });
                }
            });

            menuBtn.addEventListener('click', () => {
                sidebar.classList.toggle('-translate-x-full');
                mobileOverlay.classList.toggle('hidden');
            });

            mobileOverlay.addEventListener('click', () => {
                sidebar.classList.add('-translate-x-full');
                mobileOverlay.classList.add('hidden');
            });
        });
    </script>
</body>
</html>
