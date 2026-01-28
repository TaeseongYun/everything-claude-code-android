# /compose-stability - Compose 안정성 분석

Compose Compiler Reports를 분석하여 불안정한 클래스와 불필요한 recomposition을 감지합니다.

## Usage

```bash
/compose-stability [module]
/compose-stability :feature:home
/compose-stability --all
```

## What This Command Does

### 1. Compose Compiler Reports 생성

```bash
./gradlew assembleRelease \
  -PcomposeCompilerReports=true \
  -PcomposeCompilerMetrics=true
```

### 2. 리포트 분석

생성되는 파일들:
- `*-classes.txt` - 클래스별 안정성 정보
- `*-composables.txt` - Composable 함수 정보
- `*-composables.csv` - CSV 형식 데이터

### 3. 문제점 식별 및 해결책 제시

## 분석 항목

### Unstable Classes

```
// 리포트 예시
unstable class HomeUiState {
  unstable val items: List<Item>  // ❌ List는 불안정
  stable val isLoading: Boolean
}
```

**자동 감지 → 해결책 제시:**

```kotlin
// ❌ Before: Unstable
data class HomeUiState(
    val items: List<Item>,
    val isLoading: Boolean
)

// ✅ After: Stable
@Immutable
data class HomeUiState(
    val items: ImmutableList<Item>,
    val isLoading: Boolean
)
```

### Skippable Analysis

```
// 리포트 예시
restartable but not skippable fun HomeScreen(
  unstable state: HomeUiState,
  unstable onIntent: Function1<Intent, Unit>
)
```

**자동 감지 → 해결책 제시:**

```kotlin
// ❌ Before: Not skippable
@Composable
fun HomeScreen(
    state: HomeUiState,  // Unstable state
    onIntent: (Intent) -> Unit  // Lambda recreated
)

// ✅ After: Skippable
@Composable
fun HomeScreen(
    state: HomeUiState,  // Now stable with @Immutable
    onIntent: (Intent) -> Unit  // Stable if hoisted properly
)
```

## Output Format

```markdown
## Compose Stability Report: :feature:home

### Summary
- Total Composables: 24
- Skippable: 18 (75%)
- Restartable: 24 (100%)
- Unstable Classes: 3

### 🔴 Critical Issues

#### 1. HomeUiState (Unstable)
**Location:** `feature/home/HomeContract.kt:15`
**Problem:** Contains unstable `List<Item>`
**Impact:** HomeScreen recomposes on every parent recomposition

**Fix:**
```kotlin
@Immutable
data class HomeUiState(
    val items: ImmutableList<Item>,  // Changed
    val isLoading: Boolean
)
```

#### 2. ItemRow (Not Skippable)
**Location:** `feature/home/ui/ItemRow.kt:8`
**Problem:** Lambda parameter `onClick` recreated every recomposition

**Fix:**
```kotlin
// In parent composable
val onItemClick = remember<(String) -> Unit> { { id ->
    viewModel.onItemClick(id)
} }
```

### 🟡 Warnings

#### 1. UserAvatar uses unstable parameter
...

### ✅ Well Optimized
- LoadingIndicator (skippable)
- ErrorMessage (skippable)
- TopBar (skippable)

### Recommendations
1. Add `kotlinx-collections-immutable` dependency
2. Use `@Immutable` annotation for UI state classes
3. Hoist lambda callbacks to parent composables
```

## Gradle Setup Required

```kotlin
// build.gradle.kts (app or module)
android {
    composeCompiler {
        reportsDestination = layout.buildDirectory.dir("compose-reports")
        metricsDestination = layout.buildDirectory.dir("compose-metrics")
    }
}
```

## Auto-Fix Mode

```bash
/compose-stability --fix
```

자동으로 수정 가능한 항목:
- `List<T>` → `ImmutableList<T>` 변환
- `@Immutable` 어노테이션 추가
- `remember` 래핑 제안

## Integration with CI

```yaml
# .github/workflows/compose-check.yml
- name: Check Compose Stability
  run: |
    ./gradlew assembleRelease -PcomposeCompilerReports=true
    ./scripts/analyze-compose-stability.sh
```

## Related Commands

- `/compose-metrics` - 상세 성능 메트릭 분석
- `/compose-preview` - Preview 함수 생성
