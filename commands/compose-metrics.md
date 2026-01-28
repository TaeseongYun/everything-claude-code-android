# /compose-metrics - Compose 성능 메트릭 분석

Compose 앱의 상세 성능 메트릭을 분석하고 최적화 포인트를 찾습니다.

## Usage

```bash
/compose-metrics [module]
/compose-metrics :feature:home --compare baseline
/compose-metrics --trend
```

## Metrics Categories

### 1. Recomposition Metrics

```kotlin
// 측정 항목
- recomposition count
- skip count
- recomposition rate (recomposition / (recomposition + skip))
```

### 2. Composable Metrics

```
// composables.csv 분석
name,composable,skippable,restartable,readonly,inline,isLambda
HomeScreen,1,1,1,0,0,0
ItemRow,1,0,1,0,0,0  // ⚠️ skippable=0
```

### 3. Class Stability Metrics

```
// classes.txt 분석
stable class Item
unstable class UiState  // ⚠️
```

## Output Format

```markdown
## Compose Metrics Report: :feature:home

### 📊 Overview

| Metric | Value | Target | Status |
|--------|-------|--------|--------|
| Skippable Rate | 75% | >90% | 🔴 |
| Stable Classes | 12/15 | 100% | 🟡 |
| Inline Composables | 3 | - | ✅ |

### 📈 Recomposition Analysis

#### High Recomposition Composables
| Composable | Recompositions | Skips | Rate |
|------------|----------------|-------|------|
| HomeScreen | 45 | 12 | 79% 🔴 |
| ItemRow | 180 | 0 | 100% 🔴 |
| TopBar | 10 | 90 | 10% ✅ |

#### Recomposition Hotspots
```
HomeScreen (45 recompositions)
└── ItemList (45 recompositions)
    └── ItemRow x 20 (180 total) ← 🔥 Hotspot
        └── ItemImage (180 recompositions)
```

### 🔍 Detailed Analysis

#### ItemRow - Critical Issue
**Problem:** 0% skip rate, recomposes on every frame
**Root Cause:**
1. Parent passes unstable lambda: `onClick = { onItemClick(item.id) }`
2. `Item` class is unstable (contains `List<Tag>`)

**Estimated Impact:**
- ~16ms per recomposition
- Causes frame drops during scroll

**Solution:**
```kotlin
// 1. Stabilize Item class
@Immutable
data class Item(
    val id: String,
    val tags: ImmutableList<Tag>  // Was List<Tag>
)

// 2. Use key for LazyColumn
LazyColumn {
    items(items, key = { it.id }) { item ->
        ItemRow(item = item, onClick = onItemClick)
    }
}

// 3. Hoist callback
@Composable
fun ItemList(
    items: ImmutableList<Item>,
    onItemClick: (String) -> Unit  // Already stable reference
) {
    LazyColumn {
        items(items, key = { it.id }) { item ->
            ItemRow(
                item = item,
                onClick = { onItemClick(item.id) }
            )
        }
    }
}
```

### 📉 Trend Analysis (--trend)

```
Week    Skippable%  Unstable Classes  Avg Recomp/Frame
─────────────────────────────────────────────────────
W1      65%         8                 12.3
W2      70%         6                 9.8
W3      75%         3                 7.2  ← Current
Target  90%         0                 <5.0
```

### 🎯 Action Items

Priority 1 (This Sprint):
- [ ] Fix ItemRow stability (estimated: -60% recompositions)
- [ ] Add @Immutable to UiState classes

Priority 2 (Next Sprint):
- [ ] Optimize UserAvatar image loading
- [ ] Implement derivedStateOf for filtered lists
```

## Real-time Monitoring

### Layout Inspector Integration

```kotlin
// Debug build only
@Composable
fun RecompositionCounter(name: String) {
    if (BuildConfig.DEBUG) {
        val count = remember { mutableIntStateOf(0) }
        SideEffect { count.intValue++ }
        Text("$name: ${count.intValue}", style = debugTextStyle)
    }
}
```

### Compose Metrics Gradle Task

```kotlin
// build.gradle.kts
tasks.register("analyzeComposeMetrics") {
    dependsOn("assembleRelease")
    doLast {
        val metricsDir = layout.buildDirectory.dir("compose-metrics").get()
        // Parse and analyze metrics
        exec {
            commandLine("./scripts/analyze-metrics.sh", metricsDir.asFile.path)
        }
    }
}
```

## Baseline Comparison

```bash
# 베이스라인 저장
/compose-metrics --save-baseline

# 베이스라인과 비교
/compose-metrics --compare baseline
```

```markdown
## Comparison with Baseline

| Metric | Baseline | Current | Change |
|--------|----------|---------|--------|
| Skippable Rate | 70% | 75% | +5% ✅ |
| Unstable Classes | 5 | 3 | -2 ✅ |
| Avg Recomp/Frame | 9.8 | 7.2 | -27% ✅ |
```

## CI Integration

```yaml
# .github/workflows/compose-metrics.yml
name: Compose Metrics

on:
  pull_request:
    paths:
      - '**/*.kt'

jobs:
  metrics:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Generate Metrics
        run: ./gradlew assembleRelease -PcomposeCompilerMetrics=true

      - name: Compare with Baseline
        run: ./scripts/compare-metrics.sh

      - name: Comment on PR
        uses: actions/github-script@v7
        with:
          script: |
            const metrics = require('./compose-metrics-summary.json')
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              body: metrics.summary
            })
```
