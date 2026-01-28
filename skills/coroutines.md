# Kotlin Coroutines & Flow

Android를 위한 코루틴 및 Flow 가이드.

## Coroutine Basics

### Scope

```kotlin
// ViewModel scope - ViewModel이 clear될 때 자동 취소
class MyViewModel : ViewModel() {
    fun loadData() {
        viewModelScope.launch {
            // ...
        }
    }
}

// Lifecycle scope - Lifecycle에 따라 관리
class MyActivity : ComponentActivity() {
    fun observeData() {
        lifecycleScope.launch {
            repeatOnLifecycle(Lifecycle.State.STARTED) {
                viewModel.uiState.collect { state ->
                    // UI 업데이트
                }
            }
        }
    }
}

// Custom scope
class MyRepository {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    fun close() {
        scope.cancel()
    }
}
```

### Dispatchers

```kotlin
// Main: UI 작업
withContext(Dispatchers.Main) {
    textView.text = "Updated"
}

// IO: 네트워크, 파일 I/O
withContext(Dispatchers.IO) {
    api.fetchData()
}

// Default: CPU 집약적 작업
withContext(Dispatchers.Default) {
    heavyComputation()
}
```

### suspend Functions

```kotlin
// suspend function은 coroutine 내에서만 호출 가능
suspend fun fetchUser(id: String): User {
    return withContext(Dispatchers.IO) {
        api.getUser(id)
    }
}

// Main-safe function
suspend fun loadAndProcess(): Result {
    val data = withContext(Dispatchers.IO) {
        repository.fetchData()
    }
    val processed = withContext(Dispatchers.Default) {
        processData(data)
    }
    return processed
}
```

## Exception Handling

### try-catch

```kotlin
viewModelScope.launch {
    try {
        val result = repository.fetchData()
        _uiState.update { it.copy(data = result) }
    } catch (e: Exception) {
        _uiState.update { it.copy(error = e.message) }
    }
}
```

### runCatching

```kotlin
viewModelScope.launch {
    repository.fetchData()
        .onSuccess { data ->
            _uiState.update { it.copy(data = data) }
        }
        .onFailure { error ->
            _uiState.update { it.copy(error = error.message) }
        }
}

// Repository에서
suspend fun fetchData(): Result<Data> = runCatching {
    api.getData()
}
```

### SupervisorJob

```kotlin
// 하나의 자식 코루틴 실패가 다른 자식에 영향 안 줌
private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

scope.launch {
    // 이 코루틴이 실패해도
}

scope.launch {
    // 이 코루틴은 계속 실행
}
```

### CoroutineExceptionHandler

```kotlin
val handler = CoroutineExceptionHandler { _, exception ->
    Timber.e(exception, "Coroutine failed")
    crashlytics.recordException(exception)
}

scope.launch(handler) {
    // 예외 발생 시 handler가 처리
}
```

## Flow

### Basic Flow

```kotlin
// Flow 생성
fun getItems(): Flow<List<Item>> = flow {
    val items = repository.fetchItems()
    emit(items)
}

// Room에서 Flow 반환
@Query("SELECT * FROM items")
fun getItems(): Flow<List<ItemEntity>>

// 수집
viewModelScope.launch {
    repository.getItems().collect { items ->
        _uiState.update { it.copy(items = items) }
    }
}
```

### StateFlow

```kotlin
class MyViewModel : ViewModel() {
    // 내부 mutable
    private val _uiState = MutableStateFlow(UiState())

    // 외부 immutable
    val uiState: StateFlow<UiState> = _uiState.asStateFlow()

    fun updateName(name: String) {
        _uiState.update { it.copy(name = name) }
    }
}

// Compose에서 수집
@Composable
fun MyScreen(viewModel: MyViewModel = hiltViewModel()) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    // ...
}
```

### SharedFlow

```kotlin
class MyViewModel : ViewModel() {
    // 일회성 이벤트용
    private val _events = MutableSharedFlow<Event>()
    val events: SharedFlow<Event> = _events.asSharedFlow()

    fun onButtonClick() {
        viewModelScope.launch {
            _events.emit(Event.NavigateToDetail)
        }
    }
}
```

### Channel (일회성 이벤트)

```kotlin
class MyViewModel : ViewModel() {
    private val _events = Channel<Event>(Channel.BUFFERED)
    val events: Flow<Event> = _events.receiveAsFlow()

    fun showToast(message: String) {
        viewModelScope.launch {
            _events.send(Event.ShowToast(message))
        }
    }
}
```

## Flow Operators

### Transform

```kotlin
// map
userFlow
    .map { user -> user.name }

// filter
itemsFlow
    .filter { item -> item.isActive }

// flatMapLatest
searchQueryFlow
    .flatMapLatest { query ->
        repository.search(query)
    }
```

### Combine

```kotlin
// 여러 Flow 결합
combine(
    userFlow,
    settingsFlow,
    notificationsFlow
) { user, settings, notifications ->
    UiState(
        user = user,
        settings = settings,
        notifications = notifications
    )
}
```

### Debounce & Throttle

```kotlin
// debounce: 마지막 값만 (검색 쿼리에 유용)
searchQueryFlow
    .debounce(300)
    .flatMapLatest { query ->
        repository.search(query)
    }

// 첫 번째 값만 (버튼 클릭에 유용)
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

### Error Handling

```kotlin
repository.getItems()
    .catch { error ->
        emit(emptyList()) // 에러 시 기본값
        _events.send(Event.ShowError(error.message))
    }
    .collect { items ->
        _uiState.update { it.copy(items = items) }
    }
```

### Retry

```kotlin
repository.fetchData()
    .retry(3) { cause ->
        cause is IOException // IOException일 때만 재시도
    }
    .catch { /* 최종 실패 처리 */ }
```

## Compose Integration

### collectAsStateWithLifecycle

```kotlin
@Composable
fun MyScreen(viewModel: MyViewModel = hiltViewModel()) {
    // ✅ Lifecycle aware collection
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    // ❌ Lifecycle 고려 안 함
    // val uiState by viewModel.uiState.collectAsState()
}
```

### LaunchedEffect for Events

```kotlin
@Composable
fun MyScreen(viewModel: MyViewModel = hiltViewModel()) {
    val context = LocalContext.current

    LaunchedEffect(Unit) {
        viewModel.events.collect { event ->
            when (event) {
                is Event.ShowToast -> {
                    Toast.makeText(context, event.message, Toast.LENGTH_SHORT).show()
                }
                is Event.Navigate -> {
                    // navigation
                }
            }
        }
    }
}
```

## Testing

### runTest

```kotlin
@Test
fun `test coroutine`() = runTest {
    // Given
    coEvery { repository.fetchData() } returns testData

    // When
    viewModel.loadData()

    // Then
    assertThat(viewModel.uiState.value.data).isEqualTo(testData)
}
```

### Turbine for Flow Testing

```kotlin
@Test
fun `test flow emissions`() = runTest {
    viewModel.uiState.test {
        // 초기 상태
        assertThat(awaitItem().isLoading).isFalse()

        // 액션 실행
        viewModel.loadData()

        // Loading 상태
        assertThat(awaitItem().isLoading).isTrue()

        // 완료 상태
        val finalState = awaitItem()
        assertThat(finalState.isLoading).isFalse()
        assertThat(finalState.data).isNotNull()
    }
}
```

### MainDispatcherRule

```kotlin
@OptIn(ExperimentalCoroutinesApi::class)
class MainDispatcherRule(
    private val dispatcher: TestDispatcher = UnconfinedTestDispatcher()
) : TestWatcher() {
    override fun starting(description: Description) {
        Dispatchers.setMain(dispatcher)
    }

    override fun finished(description: Description) {
        Dispatchers.resetMain()
    }
}

class MyViewModelTest {
    @get:Rule
    val mainDispatcherRule = MainDispatcherRule()

    @Test
    fun myTest() = runTest {
        // Main dispatcher가 TestDispatcher로 대체됨
    }
}
```

## Best Practices

1. **viewModelScope 사용** - ViewModel에서 코루틴 시작
2. **Main-safe functions** - suspend 함수는 어느 dispatcher에서든 호출 가능하게
3. **StateFlow for UI state** - 항상 값을 가지므로 UI에 적합
4. **Channel for events** - 일회성 이벤트에 사용
5. **collectAsStateWithLifecycle** - Compose에서 lifecycle aware 수집
6. **적절한 error handling** - runCatching 또는 try-catch 사용
7. **취소 지원** - CancellationException은 다시 throw
