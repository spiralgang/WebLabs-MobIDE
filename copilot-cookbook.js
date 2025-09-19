/**
 * GitHub Copilot Chat Cookbook
 * A comprehensive collection of prompts and examples for using GitHub Copilot Chat effectively
 * Specifically designed for ARM64/AArch64 Android development and mobile-first applications
 */

export const copilotCookbook = {
  categories: {
    "communicate": {
      name: "Communicate Effectively",
      description: "Examples for extracting information, synthesizing research, and creating visual content",
      icon: "💬",
      examples: [
        {
          id: "extract-info",
          title: "Extracting information from GitHub issues",
          difficulty: "Simple",
          description: "Copilot Chat in GitHub can help you extract key information from issues and discussions.",
          prompt: "Please extract the key information from this GitHub issue:\n\n[Paste issue content here]\n\nSummarize:\n- Main problem\n- Proposed solution\n- Required actions\n- Timeline/priority\n- Android/ARM64 compatibility considerations",
          tags: ["information", "issues", "discussions", "android"],
          useCase: "When you need to quickly understand the core details from lengthy GitHub discussions or issue threads, especially for mobile development projects.",
          androidSpecific: true
        },
        {
          id: "synthesize-research",
          title: "Synthesizing mobile development research",
          difficulty: "Simple", 
          description: "Copilot Chat can help you synthesize research findings and insights from multiple sources into a cohesive summary.",
          prompt: "I have research findings from multiple sources about Android ARM64 development and mobile optimization. Please help me synthesize this information:\n\nSource 1: [ARM64 performance findings]\nSource 2: [Android compatibility research]\nSource 3: [Mobile UI/UX insights]\n\nPlease create:\n- Executive summary for mobile-first development\n- Key insights for ARM64 optimization\n- Android-specific recommendations\n- Performance considerations",
          tags: ["research", "synthesis", "android", "arm64"],
          useCase: "Combining insights from multiple research sources for mobile app development and Android optimization.",
          androidSpecific: true
        },
        {
          id: "create-mobile-diagrams",
          title: "Creating mobile architecture diagrams",
          difficulty: "Simple",
          description: "GitHub Copilot Chat can help you create diagrams specific to mobile app architecture and Android systems.",
          prompt: "Help me create a mobile app architecture diagram for an Android ARM64 application:\n\nContext: [describe your mobile app architecture]\n\nPlease provide:\n- Mermaid diagram code for mobile architecture\n- Android-specific components (Activities, Services, etc.)\n- ARM64 native components integration\n- Data flow between mobile layers\n- Suggested optimizations for mobile performance",
          tags: ["diagrams", "mobile", "android", "architecture"],
          useCase: "Creating visual representations of mobile app architecture, especially for Android ARM64 applications.",
          androidSpecific: true
        },
        {
          id: "mobile-feature-tables",
          title: "Generating mobile feature comparison tables",
          difficulty: "Simple",
          description: "Copilot Chat can help you create tables to organize mobile development information and feature comparisons.",
          prompt: "Create a feature comparison table for Android mobile development:\n\n[Provide feature data or requirements]\n\nFormat as:\n- Markdown table with mobile-specific columns\n- Include ARM64 compatibility status\n- Android API level requirements\n- Performance impact ratings\n- Mobile-first design considerations",
          tags: ["tables", "mobile", "android", "features"],
          useCase: "Organizing mobile feature comparisons, Android compatibility matrices, or performance benchmarks.",
          androidSpecific: true
        }
      ]
    },
    "debugging": {
      name: "Debugging Mobile Code", 
      description: "Examples for identifying and fixing bugs in mobile applications and Android development",
      icon: "🐛",
      examples: [
        {
          id: "debug-android-json",
          title: "Debugging Android JSON parsing issues",
          difficulty: "Intermediate",
          description: "Copilot Chat can identify and resolve JSON parsing issues specific to Android applications.",
          prompt: "I have JSON parsing errors in my Android app that's causing crashes on ARM64 devices:\n\n```json\n[paste your Android JSON response]\n```\n\nAndroid error log:\n```\n[paste logcat errors]\n```\n\nPlease:\n- Identify JSON syntax and structure errors\n- Fix Android-specific parsing issues\n- Provide ARM64-compatible parsing solution\n- Suggest error handling for mobile networks\n- Add validation for mobile data constraints",
          tags: ["json", "android", "parsing", "arm64"],
          useCase: "When dealing with malformed JSON in Android apps, API responses, or mobile data structures.",
          androidSpecific: true
        },
        {
          id: "mobile-api-rate-limits",
          title: "Handling mobile API rate limits and network issues",
          difficulty: "Intermediate", 
          description: "Copilot Chat can help handle API rate limits and network connectivity issues specific to mobile applications.",
          prompt: "I'm hitting API rate limits and network issues in my Android app. Help me implement robust mobile networking:\n\n```kotlin\n[paste your Android networking code]\n```\n\nMobile-specific requirements:\n- Handle poor network conditions\n- Implement background sync\n- ARM64 optimization\n- Battery-efficient networking\n\nPlease provide:\n- Mobile-optimized rate limiting detection\n- Exponential backoff with mobile considerations\n- Network state awareness\n- Background processing for Android",
          tags: ["api", "mobile", "networking", "android"],
          useCase: "Building resilient mobile applications that handle network limitations and mobile-specific constraints.",
          androidSpecific: true
        },
        {
          id: "android-performance-debugging",
          title: "Debugging Android ARM64 performance issues",
          difficulty: "Advanced",
          description: "Copilot Chat can help identify and resolve performance issues specific to Android ARM64 applications.",
          prompt: "My Android app has performance issues on ARM64 devices. Help me debug and optimize:\n\nPerformance symptoms:\n- [describe performance issues]\n- ARM64-specific problems\n- Memory usage patterns\n\nCode sections:\n```kotlin/java\n[paste performance-critical code]\n```\n\nPlease analyze:\n- ARM64-specific bottlenecks\n- Android memory management issues\n- Native code optimization opportunities\n- Mobile-specific performance patterns\n- Battery usage optimization",
          tags: ["performance", "android", "arm64", "optimization"],
          useCase: "Optimizing Android applications for ARM64 devices and resolving mobile-specific performance bottlenecks.",
          androidSpecific: true
        }
      ]
    },
    "refactoring": {
      name: "Mobile Code Refactoring",
      description: "Examples for improving mobile app structure, Android performance, and ARM64 compatibility",
      icon: "🔧",
      examples: [
        {
          id: "android-readability",
          title: "Improving Android code readability and maintainability",
          difficulty: "Simple",
          description: "Copilot Chat can suggest ways to make your Android code easier to understand and maintain.",
          prompt: "Please help me improve the readability and maintainability of this Android code:\n\n```kotlin/java\n[paste your Android code]\n```\n\nFocus on:\n- Android best practices and conventions\n- Clear naming for mobile contexts\n- Reducing complexity in mobile UI logic\n- ARM64-specific optimizations\n- Mobile lifecycle considerations\n- Memory management for mobile apps",
          tags: ["readability", "android", "mobile", "best-practices"],
          useCase: "Making Android code more maintainable for team development and mobile-specific requirements.",
          androidSpecific: true
        },
        {
          id: "android-performance-refactor",
          title: "Refactoring for mobile performance optimization",
          difficulty: "Intermediate",
          description: "Copilot Chat can suggest ways to optimize Android applications for better mobile performance.",
          prompt: "This Android code is causing performance issues on mobile devices. Help me optimize it:\n\n```kotlin/java\n[paste mobile performance bottleneck code]\n```\n\nMobile performance issues:\n- Battery drain patterns\n- Memory leaks in mobile context\n- ARM64-specific performance problems\n- UI thread blocking on mobile\n\nPlease suggest:\n- Mobile-optimized algorithms\n- Android lifecycle-aware optimizations\n- ARM64 native optimizations\n- Background processing strategies\n- Memory-efficient mobile patterns",
          tags: ["performance", "mobile", "android", "optimization"],
          useCase: "Optimizing Android applications for better mobile performance, battery life, and ARM64 compatibility.",
          androidSpecific: true
        },
        {
          id: "android-architecture-patterns",
          title: "Refactoring Android apps with mobile architecture patterns",
          difficulty: "Advanced",
          description: "Copilot Chat can suggest mobile-specific architecture patterns for Android applications.",
          prompt: "I want to refactor this Android app to use modern mobile architecture patterns:\n\n```kotlin/java\n[paste current Android app code]\n```\n\nCurrent mobile-specific issues:\n- Poor separation of concerns in mobile context\n- Lifecycle management problems\n- ARM64 native integration challenges\n\nPlease:\n- Implement MVVM or Clean Architecture for Android\n- Add proper mobile lifecycle handling\n- Integrate ARM64 native components\n- Optimize for mobile performance\n- Follow Android development best practices",
          tags: ["architecture", "android", "mobile", "patterns"],
          useCase: "Applying modern Android architecture patterns while optimizing for mobile performance and ARM64 compatibility.",
          androidSpecific: true
        }
      ]
    },
    "testing": {
      name: "Mobile Testing",
      description: "Examples for creating and maintaining tests for mobile applications",
      icon: "🧪",
      examples: [
        {
          id: "android-unit-tests",
          title: "Generating Android unit tests",
          difficulty: "Intermediate",
          description: "Copilot Chat can help generate comprehensive unit tests for Android applications.",
          prompt: "Please generate comprehensive unit tests for this Android function:\n\n```kotlin/java\n[paste Android function code]\n```\n\nMobile testing requirements:\n- Test Android-specific components\n- Mock mobile system services\n- Handle mobile lifecycle states\n- Test ARM64 compatibility\n- Include mobile edge cases (network, battery, etc.)\n\nProvide tests using:\n- [JUnit/Espresso/Robolectric]\n- Android testing best practices\n- Mobile-specific assertions\n- Lifecycle-aware testing",
          tags: ["unit-testing", "android", "mobile", "testing"],
          useCase: "Creating thorough test suites for Android applications with mobile-specific testing considerations.",
          androidSpecific: true
        },
        {
          id: "android-ui-tests",
          title: "Creating Android UI and integration tests",
          difficulty: "Advanced",
          description: "Copilot Chat can help create comprehensive UI tests for Android applications.",
          prompt: "Create comprehensive UI tests for this Android mobile app:\n\nApp functionality:\n- [describe mobile app features]\n- ARM64-specific components\n- Mobile-specific user interactions\n\nTesting requirements:\n- Test on different screen sizes\n- Handle mobile system interruptions\n- Test ARM64 native integrations\n- Verify mobile performance\n\nPlease provide:\n- Espresso UI test suite\n- Mobile-specific test scenarios\n- Device configuration tests\n- Performance testing for mobile\n- ARM64 compatibility verification",
          tags: ["ui-testing", "android", "mobile", "integration"],
          useCase: "Testing complete mobile user workflows and ensuring Android app functionality across devices.",
          androidSpecific: true
        }
      ]
    },
    "security": {
      name: "Mobile Security & Dependencies",
      description: "Examples for securing mobile applications and managing Android dependencies",
      icon: "🔒",
      examples: [
        {
          id: "android-security-audit",
          title: "Securing Android applications",
          description: "Copilot Chat can help you secure Android applications and identify mobile-specific vulnerabilities.",
          prompt: "Help me secure this Android application and identify mobile security vulnerabilities:\n\nAndroid manifest:\n```xml\n[paste AndroidManifest.xml]\n```\n\nSecurity-critical Android code:\n```kotlin/java\n[paste sensitive mobile code sections]\n```\n\nPlease provide:\n- Android security best practices audit\n- Mobile-specific vulnerability assessment\n- ARM64 security considerations\n- Android permission security review\n- Mobile data protection strategies\n- Secure mobile authentication patterns",
          tags: ["security", "android", "mobile", "audit"],
          useCase: "Conducting security reviews for Android applications with mobile-specific security considerations.",
          androidSpecific: true
        },
        {
          id: "android-dependency-management",
          title: "Managing Android dependencies and ARM64 compatibility", 
          description: "Copilot Chat can help set up dependency management for Android projects with ARM64 support.",
          prompt: "Help me set up automated dependency management for this Android project:\n\nAndroid project structure:\n```gradle\n[paste build.gradle files]\n```\n\nRequirements:\n- ARM64/AArch64 native library support\n- Android security updates\n- Mobile performance optimization\n- Cross-platform compatibility\n\nPlease provide:\n- Gradle dependency management configuration\n- ARM64 native library integration\n- Android security scanning setup\n- Mobile performance monitoring\n- Update strategy for mobile dependencies",
          tags: ["dependencies", "android", "arm64", "gradle"],
          useCase: "Setting up automated dependency management for Android projects with ARM64 native components.",
          androidSpecific: true
        }
      ]
    },
    "mobile-development": {
      name: "Mobile Development Patterns",
      description: "Specialized examples for mobile-first development and Android optimization",
      icon: "📱",
      examples: [
        {
          id: "android-arm64-optimization",
          title: "Optimizing for Android ARM64/AArch64",
          difficulty: "Advanced",
          description: "Copilot Chat can help optimize Android applications specifically for ARM64 architecture.",
          prompt: "Help me optimize this Android application for ARM64/AArch64 devices:\n\nCurrent implementation:\n```kotlin/java\n[paste Android code]\n```\n\nNative components:\n```cpp\n[paste native/JNI code if any]\n```\n\nOptimization goals:\n- Maximum ARM64 performance\n- Efficient memory usage on mobile\n- Battery optimization\n- Native library integration\n\nPlease provide:\n- ARM64-specific optimizations\n- Android NDK best practices\n- Mobile performance patterns\n- Memory management for ARM64\n- Battery-efficient algorithms",
          tags: ["arm64", "android", "optimization", "performance"],
          useCase: "Optimizing Android applications specifically for ARM64 devices and mobile performance requirements.",
          androidSpecific: true
        },
        {
          id: "mobile-first-architecture",
          title: "Implementing mobile-first architecture patterns",
          difficulty: "Advanced",
          description: "Copilot Chat can help design architecture patterns optimized for mobile-first applications.",
          prompt: "Help me design a mobile-first architecture for this application:\n\nApplication requirements:\n- [describe mobile app requirements]\n- Offline-first capabilities\n- ARM64 performance optimization\n- Battery-efficient design\n- Responsive mobile UI\n\nPlease provide:\n- Mobile-first architecture design\n- Offline data synchronization patterns\n- Mobile performance optimization strategies\n- Battery-aware background processing\n- Responsive mobile UI patterns\n- ARM64-optimized components",
          tags: ["architecture", "mobile-first", "offline", "performance"],
          useCase: "Designing applications with mobile-first principles and optimal mobile device performance.",
          androidSpecific: true
        }
      ]
    }
  },
  
  // Search functionality optimized for mobile development
  search: function(query) {
    const results = [];
    const queryLower = query.toLowerCase();
    
    for (const [categoryKey, category] of Object.entries(this.categories)) {
      for (const example of category.examples) {
        // Enhanced search including mobile-specific terms
        const searchText = [
          example.title,
          example.description,
          example.useCase,
          ...example.tags,
          example.androidSpecific ? 'android mobile arm64' : ''
        ].join(' ').toLowerCase();
        
        if (searchText.includes(queryLower)) {
          results.push({
            ...example,
            category: category.name,
            categoryKey: categoryKey,
            categoryIcon: category.icon
          });
        }
      }
    }
    
    // Sort results with Android/mobile content first
    return results.sort((a, b) => {
      if (a.androidSpecific && !b.androidSpecific) return -1;
      if (!a.androidSpecific && b.androidSpecific) return 1;
      return 0;
    });
  },
  
  // Get examples by difficulty with mobile priority
  getByDifficulty: function(difficulty) {
    const results = [];
    
    for (const [categoryKey, category] of Object.entries(this.categories)) {
      for (const example of category.examples) {
        if (example.difficulty === difficulty) {
          results.push({
            ...example,
            category: category.name,
            categoryKey: categoryKey,
            categoryIcon: category.icon
          });
        }
      }
    }
    
    // Prioritize Android-specific examples
    return results.sort((a, b) => {
      if (a.androidSpecific && !b.androidSpecific) return -1;
      if (!a.androidSpecific && b.androidSpecific) return 1;
      return 0;
    });
  },
  
  // Get Android-specific examples
  getAndroidExamples: function() {
    const results = [];
    
    for (const [categoryKey, category] of Object.entries(this.categories)) {
      for (const example of category.examples) {
        if (example.androidSpecific) {
          results.push({
            ...example,
            category: category.name,
            categoryKey: categoryKey,
            categoryIcon: category.icon
          });
        }
      }
    }
    
    return results;
  },
  
  // Get all examples from a category
  getByCategory: function(categoryKey) {
    const category = this.categories[categoryKey];
    if (!category) return [];
    
    return category.examples.map(example => ({
      ...example,
      category: category.name,
      categoryKey: categoryKey,
      categoryIcon: category.icon
    }));
  },
  
  // Get example by ID
  getById: function(id) {
    for (const [categoryKey, category] of Object.entries(this.categories)) {
      const example = category.examples.find(ex => ex.id === id);
      if (example) {
        return {
          ...example,
          category: category.name,
          categoryKey: categoryKey,
          categoryIcon: category.icon
        };
      }
    }
    return null;
  },
  
  // Get random example with mobile preference
  getRandomExample: function(preferMobile = true) {
    const allExamples = [];
    
    for (const [categoryKey, category] of Object.entries(this.categories)) {
      for (const example of category.examples) {
        allExamples.push({
          ...example,
          category: category.name,
          categoryKey: categoryKey,
          categoryIcon: category.icon
        });
      }
    }
    
    if (preferMobile) {
      const mobileExamples = allExamples.filter(ex => ex.androidSpecific);
      if (mobileExamples.length > 0) {
        return mobileExamples[Math.floor(Math.random() * mobileExamples.length)];
      }
    }
    
    return allExamples[Math.floor(Math.random() * allExamples.length)];
  }
};