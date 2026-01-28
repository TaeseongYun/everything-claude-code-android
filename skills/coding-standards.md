# Kotlin Coding Standards

Android/Kotlin 프로젝트를 위한 코딩 표준 가이드.

## Naming Conventions

### Classes and Interfaces

```kotlin
// Classes: PascalCase
class UserRepository
class HomeViewModel
class AuthenticationManager

// Interfaces: PascalCase (no I prefix)
interface UserRepository
interface OnClickListener

// Abstract classes: PascalCase with Abstract prefix or Base prefix
abstract class BaseViewModel
abstract class AbstractRepository
```

### Functions and Properties

```kotlin
// Functions: camelCase, verb-first
fun fetchUsers(): List<User>
fun calculateTotal(items: List<Item>): Int
fun isValid(): Boolean
fun shouldShowDialog(): Boolean

// Properties: camelCase
val userName: String
val isLoading: Boolean
private val _uiState: MutableStateFlow<UiState>

// Constants: SCREAMING_SNAKE_CASE
const val MAX_RETRY_COUNT = 3
const val API_BASE_URL = "https://api.example.com"

// Companion object constants
companion object {
    private const val TAG = "UserRepository"
    private const val DEFAULT_PAGE_SIZE = 20
}
```

### Packages

```kotlin
// lowercase, no underscores
package com.example.feature.home
package com.example.data.repository
package com.example.core.util
```

## Code Organization

### Class Structure

```kotlin
class UserViewModel @Inject constructor(
    private val userRepository: UserRepository,
    private val analyticsTracker: AnalyticsTracker
) : ViewModel() {

    // 1. Companion object
    companion object {
        private const val TAG = "UserViewModel"
    }

    // 2. Properties (public → private)
    val uiState: StateFlow<UiState> = _uiState.asStateFlow()

    private val _uiState = MutableStateFlow(UiState())
    private val _events = Channel<Event>()

    // 3. Init block
    init {
        loadUser()
    }

    // 4. Public functions
    fun loadUser() { ... }
    fun updateProfile(name: String) { ... }

    // 5. Private functions
    private fun handleError(error: Throwable) { ... }

    // 6. Inner classes
    data class UiState(...)
    sealed interface Event
}
```

### File Organization

```kotlin
// 한 파일에 관련된 클래스들 그룹화 가능
// FeatureContract.kt
interface FeatureContract {
    data class State(...)
    sealed interface Intent
    sealed interface SideEffect
}

// 하지만 대부분의 경우 파일당 하나의 top-level 클래스
// UserRepository.kt
class UserRepository { ... }
```

## Kotlin Idioms

### Null Safety

```kotlin
// ❌ Bad
if (user != null) {
    process(user)
}

// ✅ Good
user?.let { process(it) }

// ❌ Bad
val name = if (user != null) user.name else "Unknown"

// ✅ Good
val name = user?.name ?: "Unknown"

// ❌ Bad - Force unwrap
val name = user!!.name

// ✅ Good - Safe call with default
val name = user?.name.orEmpty()
```

### Scope Functions

```kotlin
// let: null check, transform
user?.let { nonNullUser ->
    repository.save(nonNullUser)
}

// apply: object configuration
val user = User().apply {
    name = "John"
    email = "john@example.com"
}

// also: side effects
return user.also {
    analytics.trackUserCreated(it.id)
}

// run: compute result
val result = user.run {
    "$name ($email)"
}

// with: multiple operations on object
with(binding) {
    nameText.text = user.name
    emailText.text = user.email
}
```

### Collections

```kotlin
// ❌ Bad
val names = mutableListOf<String>()
for (user in users) {
    names.add(user.name)
}

// ✅ Good
val names = users.map { it.name }

// Filter and transform
val activeUserNames = users
    .filter { it.isActive }
    .map { it.name }

// First or null
val admin = users.firstOrNull { it.role == Role.ADMIN }

// Group by
val usersByRole = users.groupBy { it.role }

// Associate
val usersById = users.associateBy { it.id }
```

### Extension Functions

```kotlin
// Context extensions
fun Context.showToast(message: String) {
    Toast.makeText(this, message, Toast.LENGTH_SHORT).show()
}

// String extensions
fun String.isValidEmail(): Boolean {
    return android.util.Patterns.EMAIL_ADDRESS.matcher(this).matches()
}

// Flow extensions
fun <T> Flow<T>.throttleFirst(windowDuration: Long): Flow<T> = flow {
    var lastEmitTime = 0L
    collect { value ->
        val currentTime = System.currentTimeMillis()
        if (currentTime - lastEmitTime >= windowDuration) {
            lastEmitTime = currentTime
            emit(value)
        }
    }
}
```

## Coroutines

### Structured Concurrency

```kotlin
// ❌ Bad - GlobalScope
GlobalScope.launch {
    fetchData()
}

// ✅ Good - ViewModel scope
viewModelScope.launch {
    fetchData()
}

// ✅ Good - Lifecycle scope
lifecycleScope.launch {
    repeatOnLifecycle(Lifecycle.State.STARTED) {
        viewModel.uiState.collect { state ->
            updateUI(state)
        }
    }
}
```

### Exception Handling

```kotlin
// ❌ Bad - Swallowing exceptions
viewModelScope.launch {
    try {
        repository.fetchData()
    } catch (e: Exception) {
        // Silent failure
    }
}

// ✅ Good - Proper error handling
viewModelScope.launch {
    runCatching { repository.fetchData() }
        .onSuccess { data -> _uiState.update { it.copy(data = data) } }
        .onFailure { error -> _uiState.update { it.copy(error = error.message) } }
}
```

### Dispatchers

```kotlin
// ❌ Bad - Heavy work on Main
suspend fun parseJson(json: String): Data {
    return Json.decodeFromString(json) // Blocks main thread
}

// ✅ Good - Use appropriate dispatcher
suspend fun parseJson(json: String): Data = withContext(Dispatchers.Default) {
    Json.decodeFromString(json)
}

// IO operations
suspend fun readFile(path: String): String = withContext(Dispatchers.IO) {
    File(path).readText()
}
```

## Documentation

### KDoc

```kotlin
/**
 * Repository for user data operations.
 *
 * @property remoteDataSource Network data source
 * @property localDataSource Local database data source
 */
class UserRepository(
    private val remoteDataSource: UserRemoteDataSource,
    private val localDataSource: UserLocalDataSource
) {
    /**
     * Fetches user by ID.
     *
     * @param userId Unique identifier of the user
     * @return User if found, null otherwise
     * @throws NetworkException if network request fails
     */
    suspend fun getUser(userId: String): User?
}
```

## Formatting

```kotlin
// Line length: 120 characters max
// Indentation: 4 spaces

// Function parameters
fun processUser(
    userId: String,
    name: String,
    email: String,
    callback: (Result<User>) -> Unit
)

// Chained calls
users
    .filter { it.isActive }
    .sortedBy { it.name }
    .map { it.toDto() }

// When expressions
when (state) {
    is State.Loading -> showLoading()
    is State.Success -> showContent(state.data)
    is State.Error -> showError(state.message)
}
```

## Code Quality Tools

```bash
# ktlint - Kotlin linter
./gradlew ktlintCheck
./gradlew ktlintFormat

# detekt - Static analysis
./gradlew detekt

# Android Lint
./gradlew lint
```
