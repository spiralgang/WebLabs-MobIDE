## 2025-01-24 - [DOM Element Caching in Mobile Editor]
**Learning:** Caching frequently accessed DOM elements like `editor` and `cursor-pos` in the `ARM64MobileEditor` class avoids redundant `document.getElementById` calls in high-frequency event listeners (input, keyup, click). Even in a simple mock environment, this yielded ~85% improvement in lookup overhead.
**Action:** Always cache DOM elements in component classes, especially those used in high-frequency events or inside loops.
