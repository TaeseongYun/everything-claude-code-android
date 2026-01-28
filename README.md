# Everything Claude Code - Android

<p align="center">
  <img src="https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" />
  <img src="https://img.shields.io/badge/Kotlin-7F52FF?style=for-the-badge&logo=kotlin&logoColor=white" />
  <img src="https://img.shields.io/badge/Jetpack%20Compose-4285F4?style=for-the-badge&logo=jetpackcompose&logoColor=white" />
</p>


> **Based on [everything-claude-code](https://github.com/affaan-m/everything-claude-code)** by [@affaan-m](https://github.com/affaan-m)
> **Based on [everything-claude-code-ios](https://github.com/OkminLee/everything-claude-code-ios)** by [@Okmin](https://github.com/OkminLee)
> — An Anthropic hackathon winner's comprehensive Claude Code configuration collection.

Claude Code plugin optimized for Android/Kotlin development with **real code generation** and **Compose performance analysis**.

[한국어](#한국어-가이드)

## ✨ Key Differentiators

### 🎯 1. Compose Performance Analyzer

Unlike simple linting tools, this plugin provides **deep analysis** of Compose stability:

```bash
/compose-stability :feature:home
```

**Output:**
```
📊 Compose Stability Report

🔴 Critical: HomeUiState (Unstable)
   └─ unstable val items: List<Item>

   Auto-fix suggestion:
   @Immutable
   data class HomeUiState(
       val items: ImmutableList<Item>  // Changed
   )

Skippable Rate: 75% → Target: 90%
```

### 🚀 2. Real Code Generation (Not Just Guides)

Generate **production-ready code** with a single command:

```bash
./scripts/generate-feature.sh UserProfile --pattern mvi
```

**Creates 7 files instantly:**
```
feature/userprofile/
├── UserProfileContract.kt      # State/Intent/SideEffect
├── UserProfileViewModel.kt     # Full MVI implementation
├── ui/
│   ├── UserProfileRoute.kt     # Navigation entry
│   └── UserProfileScreen.kt    # Compose UI with previews
├── navigation/
│   └── UserProfileNavigation.kt
├── UserProfileViewModelTest.kt # Unit tests ready
└── build.gradle.kts            # Module config
```

## 📦 Installation

```bash
# Clone
git clone https://github.com/user/everything-claude-code-android.git

# Copy to Claude Code plugins
cp -r everything-claude-code-android ~/.claude/plugins/
```

## 🛠 Quick Start

```bash
# Generate complete feature module
/generate-feature Payment --pattern mvi

# Analyze Compose stability issues
/compose-stability --all

# Get performance metrics
/compose-metrics :feature:home --compare baseline

# Code review with auto-fix suggestions
/kotlin-review feature/auth/
```

## 📁 Project Structure

```
everything-claude-code-android/
├── 🤖 agents/          # 9 specialized AI agents
├── 💬 commands/        # 12 slash commands
├── 📚 skills/          # 8 architecture guides
├── 🪝 hooks/           # Git hooks (ktlint, log detection)
├── 📝 templates/       # Code generation templates
│   └── mvi/           # MVI pattern templates
├── 🔧 scripts/         # Automation scripts
│   ├── generate-feature.sh
│   ├── analyze-compose-stability.sh
│   └── detect-logs.sh
└── ⚙️ .claude/         # Plugin configuration
```

## 🎨 Commands

### Code Generation

| Command | Description |
|---------|-------------|
| `/generate-feature <Name>` | Generate complete feature module |
| `/generate-screen <Name>` | Add screen to existing module |
| `/mvi-create <Name>` | Create MVI components |
| `/mvvm-create <Name>` | Create MVVM components |
| `/compose-preview` | Generate preview functions |

### Performance Analysis

| Command | Description |
|---------|-------------|
| `/compose-stability` | Analyze class stability |
| `/compose-metrics` | Performance metrics & trends |

### Development

| Command | Description |
|---------|-------------|
| `/plan` | Plan development tasks |
| `/kotlin-tdd` | Test-Driven Development |
| `/kotlin-review` | Code review |
| `/gradle-build-fix` | Fix build issues |
| `/security-audit` | Security audit |
| `/refactor` | Refactoring assistance |
| `/document` | Generate documentation |

## 🤖 Agents

| Agent | Description |
|-------|-------------|
| `planner` | Project planning & task breakdown |
| `architect` | Architecture design (MVVM, MVI, Clean) |
| `tdd` | Test-Driven Development |
| `code-reviewer` | Kotlin & Compose review |
| `security-auditor` | OWASP compliance |
| `build-fixer` | Gradle issue resolution |
| `e2e-tester` | End-to-end testing |
| `refactorer` | Code modernization |
| `documenter` | Documentation (KDoc, ADR) |

## 📚 Skills (Architecture Guides)

| Skill | Description |
|-------|-------------|
| `compose-patterns` | Jetpack Compose best practices |
| `mvi-pattern` | MVI with Contract pattern |
| `mvvm-pattern` | MVVM with StateFlow |
| `coding-standards` | Kotlin idioms |
| `security` | Android security |
| `tdd` | Testing strategies |
| `hilt-di` | Dependency injection |
| `coroutines` | Coroutines & Flow |

## 🔧 Scripts

### Feature Generator

```bash
# Basic MVI feature
./scripts/generate-feature.sh UserProfile

# With custom package
./scripts/generate-feature.sh Payment --package com.myapp --pattern mvi
```

### Compose Stability Analyzer

```bash
# Analyze specific module
./scripts/analyze-compose-stability.sh app

# Output includes:
# - Unstable classes with fix suggestions
# - Non-skippable composables
# - Stability rate calculation
```

## 🪝 Git Hooks

Pre-configured hooks for code quality:

- **Pre-Commit**: ktlint check, debug log detection
- **Pre-Push**: unit tests, build verification
- **Post-Edit**: auto-format (optional)

## 📊 Compose Metrics Integration

### Gradle Setup

```kotlin
// build.gradle.kts
android {
    composeCompiler {
        reportsDestination = layout.buildDirectory.dir("compose-reports")
        metricsDestination = layout.buildDirectory.dir("compose-metrics")
    }
}
```

### CI Integration

```yaml
# .github/workflows/compose-check.yml
- name: Analyze Compose Stability
  run: ./scripts/analyze-compose-stability.sh app
```

---

# 한국어 가이드

Android/Kotlin 개발에 최적화된 Claude Code 플러그인입니다.
**실제 코드 생성**과 **Compose 성능 분석** 기능이 핵심입니다.

## ✨ 차별화 포인트

### 🎯 1. Compose 성능 분석기

단순 린팅이 아닌 **심층 안정성 분석**을 제공합니다:

```bash
/compose-stability :feature:home
```

**결과:**
```
📊 Compose 안정성 리포트

🔴 Critical: HomeUiState (불안정)
   └─ unstable val items: List<Item>

   자동 수정 제안:
   @Immutable
   data class HomeUiState(
       val items: ImmutableList<Item>  // 변경됨
   )

Skippable Rate: 75% → 목표: 90%
```

### 🚀 2. 실제 코드 생성 (가이드가 아닌 실행)

한 번의 명령으로 **프로덕션 레디 코드** 생성:

```bash
./scripts/generate-feature.sh UserProfile --pattern mvi
```

**즉시 7개 파일 생성:**
```
feature/userprofile/
├── UserProfileContract.kt      # State/Intent/SideEffect
├── UserProfileViewModel.kt     # 완전한 MVI 구현
├── ui/
│   ├── UserProfileRoute.kt     # Navigation 진입점
│   └── UserProfileScreen.kt    # Preview 포함 Compose UI
├── navigation/
│   └── UserProfileNavigation.kt
├── UserProfileViewModelTest.kt # 단위 테스트 준비됨
└── build.gradle.kts            # 모듈 설정
```

## 🛠 빠른 시작

```bash
# Feature 모듈 전체 생성
/generate-feature Payment --pattern mvi

# Compose 안정성 이슈 분석
/compose-stability --all

# 성능 메트릭 확인
/compose-metrics :feature:home --compare baseline

# 자동 수정 제안과 함께 코드 리뷰
/kotlin-review feature/auth/
```

## 📝 명령어

### 코드 생성

| 명령어 | 설명 |
|--------|------|
| `/generate-feature <Name>` | 완전한 Feature 모듈 생성 |
| `/generate-screen <Name>` | 기존 모듈에 화면 추가 |
| `/mvi-create <Name>` | MVI 컴포넌트 생성 |
| `/mvvm-create <Name>` | MVVM 컴포넌트 생성 |

### 성능 분석

| 명령어 | 설명 |
|--------|------|
| `/compose-stability` | 클래스 안정성 분석 |
| `/compose-metrics` | 성능 메트릭 및 트렌드 |

## 🔧 스크립트

### Feature 생성기

```bash
# 기본 MVI feature
./scripts/generate-feature.sh UserProfile

# 커스텀 패키지
./scripts/generate-feature.sh Payment --package com.myapp
```

### Compose 안정성 분석기

```bash
# 특정 모듈 분석
./scripts/analyze-compose-stability.sh app

# 출력 내용:
# - 불안정 클래스와 수정 제안
# - Skip 불가능한 Composable
# - 안정성 비율 계산
```
