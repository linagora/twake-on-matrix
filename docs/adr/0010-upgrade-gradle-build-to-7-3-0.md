# 10. upgrade gradle build to 7.3.0

Date: 2023-10-19

## Status

Accepted

## Context

- `com.android.tools.build:gradle:7.2.2` install NDK v21.4.7075529 by default.
- but [super_clipboard](https://pub.dev/packages/super_clipboard) required NDK v23
- upgrade to `com.android.tools.build:gradle:7.3.0`

## Decision

- but `com.android.tools.build:gradle:7.3.0` need `org.jetbrains.kotlin:kotlin-gradle-plugin` upgrade to version > `1.4.32`
- so we use `resolutionStrategy` to override `kotlin-gradle-plugin` for all conflict dependencies
- [resolutionStrategy](https://docs.gradle.org/current/dsl/org.gradle.api.artifacts.ResolutionStrategy.html)
```agsl
for (p in project.subprojects) {
    p.buildscript.configurations.classpath.resolutionStrategy {
        force "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}
```

## Consequences

Build Android success