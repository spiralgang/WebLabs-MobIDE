# Bolt Performance Journal ⚡

## 2025-01-24 - DOM Caching in High-Frequency Events
**Learning:** Frequent DOM lookups via `document.getElementById` or `querySelector` in high-frequency events (like `input`, `keyup`, or `click` for cursor tracking) introduce significant overhead that accumulates on low-powered ARM64 mobile devices. Caching these elements during component initialization reduces lookup overhead by over 90%.
**Action:** Always cache DOM element references in class properties or variables when they are accessed repeatedly in event listeners or render loops.

## 2025-01-24 - Intl.DateTimeFormat Reuse
**Learning:** Instantiating  is an expensive operation in JavaScript. Reusing a single instance for multiple formatting calls can improve performance by up to 99% in high-frequency scenarios.
**Action:** Pre-instantiate and reuse  formatters at the module level or in constructor logic rather than creating them inside function bodies.

## 2025-01-24 - Repository Hygiene & Focus
**Learning:** Including build artifacts (like `.gradle/`) or temporary benchmark scripts in a PR drastically reduces code quality and review acceptance. Also, sticking to exactly ONE optimization as requested ensures better focus and easier review.
**Action:** Always clean up temporary files and verify `git status` (or equivalent) to ensure only intended source changes are staged.

## 2025-01-24 - Intl.DateTimeFormat Reuse
**Learning:** Instantiating `Intl.DateTimeFormat` is an expensive operation in JavaScript. Reusing a single instance for multiple formatting calls can improve performance by up to 99% in high-frequency scenarios.
**Action:** Pre-instantiate and reuse `Intl` formatters at the module level or in constructor logic rather than creating them inside function bodies.

## 2025-01-24 - Repository Hygiene & Focus
**Learning:** Including build artifacts (like `.gradle/`) or temporary benchmark scripts in a PR drastically reduces code quality and review acceptance. Also, sticking to exactly ONE optimization as requested ensures better focus and easier review.
**Action:** Always clean up temporary files and verify `git status` (or equivalent) to ensure only intended source changes are staged.
