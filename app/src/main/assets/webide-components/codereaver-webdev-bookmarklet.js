javascript:(function(){
    // Inject styles
    const style = document.createElement('style');
    style.textContent = `
        .cr-menu-item {
            cursor: pointer !important;
            transition: background-color 0.1s ease;
        }
        .cr-menu-item:hover, .cr-menu-item:active {
            background-color: rgba(0, 0, 0, 0.1);
        }
        .cr-code-block {
            transition: background-color 0.2s ease;
        }
        .cr-code-block:hover {
            background-color: rgba(200, 200, 200, 0.1);
        }
        @media (max-width: 600px) {
            .cr-menu-item {
                padding: 8px;
            }
            .cr-code-block {
                padding: 5px;
            }
        }
    `;
    document.head.appendChild(style);

    // Debounce function
    function debounce(fn, delay) {
        let timeout;
        return function (...args) {
            clearTimeout(timeout);
            timeout = setTimeout(() => fn(...args), delay);
        };
    }

    // Enhance interactions
    function enhanceInteractions() {
        const selectors = [
            '[id*="nav"], [id*="menu"], [class*="nav"], [class*="menu"]',
            '[aria-label*="navigation"], [aria-label*="menu"]',
            '[role="navigation"], button:not([type="submit"]), [role="button"]',
            'pre, code'
        ].join(', ');
        document.querySelectorAll(selectors).forEach(item => {
            if (item.hasAttribute('data-cr-enhanced')) return;
            item.setAttribute('data-cr-enhanced', 'true');

            if (item.matches('pre, code')) {
                item.classList.add('cr-code-block');
            } else {
                item.classList.add('cr-menu-item');
                const originalClick = item.onclick || (() => {});
                item.onclick = debounce((event) => {
                    console.log('Enhanced click on:', item);
                    originalClick.call(item, event);
                }, 150);
            }
        });
    }

    // Android touch support
    if (/Android/.test(navigator.userAgent)) {
        document.addEventListener('touchstart', (e) => {
            const target = e.target.closest('[id*="nav"], [id*="menu"], [class*="nav"], [class*="menu"], [aria-label*="navigation"], [aria-label*="menu"], [role="navigation"], button:not([type="submit"]), [role="button"]');
            if (target) target.click();
        }, { passive: true });
    }

    enhanceInteractions();
})();
