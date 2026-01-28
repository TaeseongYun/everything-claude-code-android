# /refactor - Code Refactoring

Refactor Android code for better quality, performance, and maintainability.

## Usage

```
/refactor [target] [refactoring type]
```

## Examples

```
/refactor HomeViewModel extract-state
/refactor UserFragment view-to-compose
/refactor AuthRepository callback-to-coroutine
/refactor feature/home decompose-god-class
```

## Refactoring Types

### view-to-compose
Convert XML layouts and Fragments to Jetpack Compose.

```
/refactor ProfileFragment view-to-compose
```

### livedata-to-stateflow
Migrate from LiveData to StateFlow.

```
/refactor SettingsViewModel livedata-to-stateflow
```

### callback-to-coroutine
Convert callback-based code to coroutines.

```
/refactor ApiService callback-to-coroutine
```

### mvvm-to-mvi
Migrate from MVVM to MVI pattern.

```
/refactor HomeViewModel mvvm-to-mvi
```

### extract-state
Extract UI state to dedicated data class.

```
/refactor DetailViewModel extract-state
```

### decompose-god-class
Break down large classes into smaller, focused ones.

```
/refactor UserManager decompose-god-class
```

### extract-common
Extract common logic to reusable components.

```
/refactor feature/ extract-common
```

## Output Format

```markdown
## Refactoring Plan

### Target
[File or module to refactor]

### Type
[Refactoring type]

### Before
```kotlin
[Original code]
```

### After
```kotlin
[Refactored code]
```

### Changes
1. [Change 1]
2. [Change 2]
3. [Change 3]

### Migration Steps
1. [ ] Step 1
2. [ ] Step 2
3. [ ] Step 3

### Testing
- [ ] Existing tests pass
- [ ] New tests added
- [ ] Manual verification
```

## Safe Refactoring Process

1. **Ensure tests exist** for current behavior
2. **Make small, incremental changes**
3. **Run tests after each change**
4. **Commit frequently**
5. **Review diff before merging**

## Common Refactoring Patterns

### Extract Extension Function
```kotlin
// Before
val formatted = SimpleDateFormat("yyyy-MM-dd").format(date)

// After
fun Date.formatYMD(): String = SimpleDateFormat("yyyy-MM-dd").format(this)
val formatted = date.formatYMD()
```

### Replace Nested Callbacks
```kotlin
// Before
api.getUser { user ->
    api.getProfile(user.id) { profile ->
        api.getSettings(user.id) { settings ->
            // Use all data
        }
    }
}

// After
suspend fun loadUserData(): UserData {
    val user = api.getUser()
    val profile = api.getProfile(user.id)
    val settings = api.getSettings(user.id)
    return UserData(user, profile, settings)
}
```

### State Consolidation
```kotlin
// Before
private val _loading = MutableStateFlow(false)
private val _error = MutableStateFlow<String?>(null)
private val _data = MutableStateFlow<Data?>(null)

// After
data class UiState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val data: Data? = null
)
private val _uiState = MutableStateFlow(UiState())
```

## Tips

- Always have tests before refactoring
- Use IDE refactoring tools when possible
- Keep refactoring commits separate from feature commits
- Document breaking changes
