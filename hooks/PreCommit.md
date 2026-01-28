# Pre-Commit Hook

커밋 전에 자동으로 실행되는 검사들.

## Setup

`.claude/settings.json`에 다음 hook 설정을 추가:

```json
{
  "hooks": {
    "preCommit": [
      "ktlint",
      "logDetection"
    ]
  }
}
```

## Available Hooks

### 1. ktlint - Kotlin Linter

커밋 전에 ktlint를 실행하여 코드 스타일을 검사합니다.

```bash
# 검사만
./gradlew ktlintCheck

# 자동 수정
./gradlew ktlintFormat
```

#### 설정 (.editorconfig)

```ini
[*.{kt,kts}]
indent_size = 4
insert_final_newline = true
max_line_length = 120
ktlint_standard_no-wildcard-imports = disabled
ktlint_standard_package-name = disabled
```

### 2. logDetection - 로그 감지

프로덕션 코드에서 디버그 로그를 감지합니다.

**감지 대상:**
- `Log.d()`, `Log.v()`, `Log.i()`
- `println()`
- `print()`
- `System.out.println()`

**허용:**
- `Timber.d()` (release tree에서 제거됨)
- `Log.w()`, `Log.e()` (경고/에러 로그)

#### 감지 스크립트

```bash
#!/bin/bash
# hooks/detect-logs.sh

FORBIDDEN_PATTERNS=(
    "Log\.d\("
    "Log\.v\("
    "Log\.i\("
    "println\("
    "print\("
    "System\.out\."
)

FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E "\.kt$")

if [ -z "$FILES" ]; then
    exit 0
fi

FOUND=0

for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
    MATCHES=$(echo "$FILES" | xargs grep -l "$pattern" 2>/dev/null)
    if [ -n "$MATCHES" ]; then
        echo "⚠️  Found forbidden log pattern: $pattern"
        echo "$MATCHES" | while read file; do
            echo "   - $file"
            grep -n "$pattern" "$file"
        done
        FOUND=1
    fi
done

if [ $FOUND -eq 1 ]; then
    echo ""
    echo "❌ Commit blocked: Remove debug logs before committing"
    echo "   Use Timber instead: Timber.d(...)"
    exit 1
fi

echo "✅ No forbidden log statements found"
exit 0
```

### 3. detekt - Static Analysis

정적 분석을 실행합니다.

```bash
./gradlew detekt
```

#### 설정 (detekt.yml)

```yaml
complexity:
  LongMethod:
    threshold: 60
  LongParameterList:
    functionThreshold: 6
    constructorThreshold: 8

naming:
  FunctionNaming:
    functionPattern: '[a-z][a-zA-Z0-9]*'
  VariableNaming:
    variablePattern: '[a-z][a-zA-Z0-9]*'

style:
  MagicNumber:
    ignoreNumbers: ['-1', '0', '1', '2']
  MaxLineLength:
    maxLineLength: 120
```

## Git Hook Installation

### Manual Setup

```bash
# .git/hooks/pre-commit
#!/bin/bash

echo "🔍 Running pre-commit checks..."

# ktlint
echo "Running ktlint..."
./gradlew ktlintCheck --daemon
if [ $? -ne 0 ]; then
    echo "❌ ktlint failed. Run './gradlew ktlintFormat' to fix."
    exit 1
fi

# Log detection
echo "Checking for debug logs..."
./hooks/detect-logs.sh
if [ $? -ne 0 ]; then
    exit 1
fi

echo "✅ All pre-commit checks passed!"
exit 0
```

```bash
# Make executable
chmod +x .git/hooks/pre-commit
```

### Using Gradle Plugin

```kotlin
// build.gradle.kts
plugins {
    id("org.jlleitschuh.gradle.ktlint") version "11.6.1"
}

ktlint {
    android.set(true)
    outputColorName.set("RED")
    filter {
        exclude("**/generated/**")
    }
}

tasks.register("installGitHooks", Copy::class) {
    from("${rootProject.rootDir}/hooks/pre-commit")
    into("${rootProject.rootDir}/.git/hooks")
    fileMode = 0b111101101 // 755
}

tasks.named("preBuild") {
    dependsOn("installGitHooks")
}
```

## Bypass (Emergency Only)

```bash
# 긴급 시에만 사용
git commit --no-verify -m "Hotfix: ..."
```

## Troubleshooting

### ktlint가 너무 오래 걸림
```bash
# Gradle daemon 사용
./gradlew ktlintCheck --daemon
```

### 특정 파일 제외
```kotlin
// build.gradle.kts
ktlint {
    filter {
        exclude("**/generated/**")
        exclude("**/build/**")
    }
}
```
