## 2025-07-05 - [Caching DOM elements for performance]
**Learning:** Caching frequently accessed DOM elements like textarea and status labels as class properties significantly improves responsiveness in a mobile web editor by avoiding redundant lookups during 'input' and 'cursor' events.
**Action:** Always cache references to self-children using `this.container.querySelector` in the constructor/setup phase instead of `document.getElementById` to ensure groundedness and performance.

## 2025-07-05 - [Avoiding build artifacts in PRs]
**Learning:** Running build tools like Gradle can generate many binary artifacts and local scripts (like `.gradle/` and `gradlew`) that should not be committed to the repository.
**Action:** Carefully review and clean up the environment before submission, ensuring only intended source code changes are included.
