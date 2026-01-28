# Post-Edit Hook

파일 편집 후 자동으로 실행되는 검사들.

## Setup

`.claude/settings.json`에 다음 hook 설정을 추가:

```json
{
  "hooks": {
    "postEdit": [
      "autoFormat",
      "importOptimize"
    ]
  }
}
```

## Available Hooks

### 1. autoFormat - 자동 포맷팅

Kotlin 파일 저장 시 자동으로 ktlint 포맷을 적용합니다.

```bash
# 특정 파일 포맷
./gradlew ktlintFormat -PktlintFiles="path/to/file.kt"

# 전체 포맷
./gradlew ktlintFormat
```

### 2. importOptimize - Import 최적화

사용하지 않는 import를 제거합니다.

```kotlin
// Before
import android.util.Log
import android.view.View  // 사용 안 함
import kotlinx.coroutines.*

// After
import android.util.Log
import kotlinx.coroutines.*
```

### 3. composeStabilityCheck - Compose 안정성 검사

Composable 함수의 파라미터 안정성을 검사합니다.

```bash
# Compose Compiler Reports 생성
./gradlew assembleDebug -PcomposeCompilerReports=true
```

검사 항목:
- Unstable 파라미터 (List, Map 등)
- Skippable하지 않은 Composable
- 불필요한 recomposition

## Auto-Format Configuration

### ktlint 설정

```ini
# .editorconfig
[*.{kt,kts}]
indent_size = 4
indent_style = space
max_line_length = 120
insert_final_newline = true
trim_trailing_whitespace = true

# ktlint specific
ktlint_standard_no-wildcard-imports = disabled
ktlint_standard_filename = disabled
```

### IDE 설정 (Android Studio)

```
Preferences > Editor > Code Style > Kotlin
  > Set from... > Kotlin style guide
```

## File Watchers

IDE에서 파일 저장 시 자동 실행:

### Android Studio

1. `Preferences > Tools > File Watchers`
2. `+` 클릭하여 추가
3. 설정:
   - File type: `Kotlin`
   - Program: `./gradlew`
   - Arguments: `ktlintFormat -PktlintFiles=$FilePath$`

### VS Code (with Kotlin extension)

```json
// .vscode/settings.json
{
  "editor.formatOnSave": true,
  "[kotlin]": {
    "editor.defaultFormatter": "fwcd.kotlin"
  }
}
```

## Compose Compiler Reports

Compose 성능 분석 리포트 생성:

```kotlin
// build.gradle.kts (app)
android {
    composeCompiler {
        metricsDestination = layout.buildDirectory.dir("compose-metrics")
        reportsDestination = layout.buildDirectory.dir("compose-reports")
    }
}
```

```bash
# 리포트 생성
./gradlew assembleRelease

# 결과 확인
cat app/build/compose-reports/*-composables.txt
```

## Post-Edit Checklist

파일 편집 후 자동 검사:

- [ ] 코드 포맷팅 적용됨
- [ ] 사용하지 않는 import 제거됨
- [ ] Trailing whitespace 제거됨
- [ ] 파일 끝에 newline 추가됨
- [ ] Compose 파라미터 안정성 확인

## Script Example

```bash
#!/bin/bash
# hooks/post-edit.sh

FILE=$1

# Kotlin 파일만 처리
if [[ ! $FILE =~ \.kt$ ]]; then
    exit 0
fi

echo "🔧 Post-edit processing: $FILE"

# ktlint format
./gradlew ktlintFormat -PktlintFiles="$FILE" --daemon -q

# 결과 확인
if [ $? -eq 0 ]; then
    echo "✅ File formatted: $FILE"
else
    echo "⚠️  Format issues found in: $FILE"
fi
```

## Integration with Claude Code

Claude Code에서 파일 편집 후 자동 실행되도록 설정:

```json
{
  "hooks": {
    "postEdit": {
      "enabled": true,
      "actions": [
        {
          "name": "ktlint",
          "command": "./gradlew ktlintFormat -PktlintFiles=\"$FILE\"",
          "filePattern": "*.kt"
        }
      ]
    }
  }
}
```
