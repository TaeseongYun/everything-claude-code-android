# /kotlin-review - Kotlin Code Review

Comprehensive code review for Kotlin and Jetpack Compose code.

## Usage

```
/kotlin-review [file path or code block]
/kotlin-review --staged  # Review staged changes
/kotlin-review --pr      # Review current PR changes
```

## Examples

```
/kotlin-review feature/home/HomeViewModel.kt
/kotlin-review --staged
/kotlin-review [paste code block]
```

## Review Categories

### 1. Kotlin Idioms
- Null safety patterns
- Extension functions usage
- Scope functions (let, run, with, apply, also)
- Collection operations
- Coroutine patterns

### 2. Compose Best Practices
- State hoisting
- Recomposition optimization
- Side effect handling
- Modifier usage
- Preview functions

### 3. Architecture
- Layer separation
- Dependency direction
- Single responsibility
- Testability

### 4. Performance
- Memory leaks
- Unnecessary recompositions
- Heavy operations on main thread
- Efficient collections

### 5. Security
- Data exposure
- Input validation
- Sensitive data handling

## Output Format

```markdown
## Code Review Summary

### Critical Issues 🔴
- [File:Line] Issue description
  - **Problem**: What's wrong
  - **Solution**: How to fix

### Warnings ⚠️
- [File:Line] Warning description
  - **Suggestion**: Recommended change

### Suggestions 💡
- [File:Line] Improvement opportunity
  - **Current**: Current approach
  - **Better**: Improved approach

### Positive Notes ✅
- Good patterns observed

### Code Quality Score
- Kotlin Idioms: ⭐⭐⭐⭐☆
- Architecture: ⭐⭐⭐⭐⭐
- Performance: ⭐⭐⭐☆☆
- Testability: ⭐⭐⭐⭐☆

### Actionable Items
1. [ ] Fix critical issue X
2. [ ] Address warning Y
3. [ ] Consider suggestion Z
```

## Common Issues Checked

| Issue | Example |
|-------|---------|
| Force unwrap | `user!!.name` |
| Memory leak | `Context` in ViewModel |
| Missing key | `LazyColumn` without key |
| State in Composable | `var count = 0` |
| Side effect in composition | Calling function directly |
| Unstable parameters | `List<Item>` instead of `ImmutableList` |

## Tips

- Review small chunks for better feedback
- Use `--staged` before commits
- Address critical issues first
