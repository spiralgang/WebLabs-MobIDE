## 2025-05-14 - [Intl.DateTimeFormat and localStorage optimization]
**Learning:** Pre-instantiating and reusing 'Intl' formatters in JavaScript significantly improves performance (up to 45x) by avoiding expensive object creation and locale resolution on every call. Also, using Object.keys(localStorage).forEach() is more performant and safer than for...in when removing items during iteration, as for...in may skip items or iterate over unexpected prototype properties.
**Action:** Always cache Intl formatters at the module level and prefer Object.keys() for iterating over localStorage.
