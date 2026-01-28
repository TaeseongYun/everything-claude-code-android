# Pre-Push Hook

푸시 전에 자동으로 실행되는 검사들.

## Setup

`.claude/settings.json`에 다음 hook 설정을 추가:

```json
{
  "hooks": {
    "prePush": [
      "unitTests",
      "buildCheck",
      "codeReview"
    ]
  }
}
```

## Available Hooks

### 1. unitTests - 단위 테스트

푸시 전에 단위 테스트를 실행합니다.

```bash
# 전체 테스트
./gradlew test

# 변경된 모듈만 테스트 (권장)
./gradlew test --continue
```

### 2. buildCheck - 빌드 검증

디버그 빌드가 성공하는지 확인합니다.

```bash
./gradlew assembleDebug
```

### 3. codeReview - AI 코드 리뷰

변경된 파일에 대해 자동 코드 리뷰를 실행합니다.

## Git Hook Installation

```bash
# .git/hooks/pre-push
#!/bin/bash

echo "🚀 Running pre-push checks..."

# 현재 브랜치
BRANCH=$(git rev-parse --abbrev-ref HEAD)

# main/master로 직접 푸시 방지
if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
    echo "❌ Direct push to $BRANCH is not allowed!"
    echo "   Please create a pull request instead."
    exit 1
fi

# 단위 테스트
echo "Running unit tests..."
./gradlew test --daemon
if [ $? -ne 0 ]; then
    echo "❌ Unit tests failed!"
    exit 1
fi

# 빌드 검증
echo "Checking build..."
./gradlew assembleDebug --daemon
if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ All pre-push checks passed!"
exit 0
```

```bash
chmod +x .git/hooks/pre-push
```

## Branch Protection

### Feature Branch Naming

```bash
# 허용되는 브랜치 이름 패턴
feature/*
bugfix/*
hotfix/*
release/*
```

### Validation Script

```bash
#!/bin/bash
# hooks/validate-branch-name.sh

BRANCH=$(git rev-parse --abbrev-ref HEAD)

VALID_PATTERNS=(
    "^feature/.*"
    "^bugfix/.*"
    "^hotfix/.*"
    "^release/.*"
    "^develop$"
    "^main$"
    "^master$"
)

VALID=0
for pattern in "${VALID_PATTERNS[@]}"; do
    if [[ $BRANCH =~ $pattern ]]; then
        VALID=1
        break
    fi
done

if [ $VALID -eq 0 ]; then
    echo "❌ Invalid branch name: $BRANCH"
    echo "   Use: feature/*, bugfix/*, hotfix/*, release/*"
    exit 1
fi

exit 0
```

## Quick Tests

변경된 모듈만 테스트하여 시간 절약:

```bash
#!/bin/bash
# hooks/quick-test.sh

# 변경된 파일 목록
CHANGED_FILES=$(git diff --name-only origin/develop...HEAD)

# 변경된 모듈 추출
MODULES=""
for file in $CHANGED_FILES; do
    if [[ $file == feature/* ]]; then
        MODULE=$(echo $file | cut -d'/' -f1-2)
        MODULES="$MODULES :$MODULE:test"
    elif [[ $file == core/* ]]; then
        MODULE=$(echo $file | cut -d'/' -f1-2)
        MODULES="$MODULES :$MODULE:test"
    fi
done

# 중복 제거
MODULES=$(echo $MODULES | tr ' ' '\n' | sort -u | tr '\n' ' ')

if [ -n "$MODULES" ]; then
    echo "Running tests for changed modules: $MODULES"
    ./gradlew $MODULES --daemon
else
    echo "No testable modules changed"
fi
```

## Bypass (Emergency Only)

```bash
# 긴급 핫픽스 시에만 사용
git push --no-verify
```

## CI Integration

GitHub Actions와 연동:

```yaml
# .github/workflows/pr-check.yml
name: PR Check

on:
  pull_request:
    branches: [develop, main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up JDK
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Run tests
        run: ./gradlew test

      - name: Build
        run: ./gradlew assembleDebug
```
