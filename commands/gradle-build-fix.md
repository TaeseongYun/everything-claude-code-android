# /gradle-build-fix - Fix Gradle Build Issues

Diagnose and fix Android Gradle build errors.

## Usage

```
/gradle-build-fix [error message or issue description]
/gradle-build-fix --analyze  # Analyze current build issues
```

## Examples

```
/gradle-build-fix ksp version mismatch
/gradle-build-fix duplicate class ListenableFuture
/gradle-build-fix --analyze
```

## Common Issues Handled

### Version Conflicts
- KSP version mismatch with Kotlin
- Compose compiler compatibility
- Dependency version conflicts

### Configuration Issues
- Missing build features
- Module dependency problems
- ProGuard/R8 rules

### Plugin Issues
- Hilt plugin configuration
- KSP setup
- Build logic plugins

### Dependency Issues
- Duplicate classes
- Missing dependencies
- Transitive dependency conflicts

## Diagnostic Steps

1. **Parse error message**
2. **Identify root cause**
3. **Check version catalog** (`libs.versions.toml`)
4. **Verify module configurations**
5. **Provide fix with explanation**

## Output Format

```markdown
## Build Issue Analysis

### Error
[Original error message]

### Root Cause
[Explanation of what's causing the issue]

### Solution

#### Step 1: [Action]
```kotlin
// File: build.gradle.kts
[Code change]
```

#### Step 2: [Action]
```toml
# File: libs.versions.toml
[Version change]
```

### Verification
```bash
./gradlew clean assembleDebug
```

### Prevention
[How to prevent this issue in the future]
```

## Useful Commands

```bash
# Clean build
./gradlew clean

# Build with stacktrace
./gradlew assembleDebug --stacktrace

# Check dependencies
./gradlew :app:dependencies

# Refresh dependencies
./gradlew build --refresh-dependencies
```

## Tips

- Always include the full error message
- Mention recent changes that might have caused the issue
- Try `./gradlew clean` before reporting persistent issues
