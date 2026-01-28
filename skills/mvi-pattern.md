# MVI Pattern (Model-View-Intent)

Comprehensive guide for implementing MVI architecture in Android.

## Overview

MVI는 단방향 데이터 흐름을 강조하는 아키텍처 패턴입니다.

```
┌─────────────────────────────────────────────┐
│                    View                      │
│  ┌─────────┐              ┌──────────────┐  │
│  │  State  │◄─────────────│   Render     │  │
│  └────┬────┘              └──────────────┘  │
│       │                          ▲          │
│       │                          │          │
│       ▼                          │          │
│  ┌─────────┐              ┌──────────────┐  │
│  │ Intent  │─────────────►│  ViewModel   │  │
│  └─────────┘              └──────────────┘  │
└─────────────────────────────────────────────┘
```

## Contract Pattern

```kotlin
interface FeatureContract {

    /**
     * UI State - 화면에 표시할 모든 데이터
     * Immutable이어야 함
     */
    @Immutable
    data class State(
        val isLoading: Boolean = false,
        val items: ImmutableList<Item> = persistentListOf(),
        val selectedItem: Item? = null,
        val error: String? = null,
        val searchQuery: String = ""
    ) {
        companion object {
            val Initial = State()
        }
    }

    /**
     * Intent - 사용자 액션 또는 시스템 이벤트
     * Sealed interface로 정의하여 exhaustive when 보장
     */
    sealed interface Intent {
        // 데이터 로딩
        data object LoadItems : Intent
        data object Refresh : Intent

        // 사용자 액션
        data class SelectItem(val id: String) : Intent
        data class DeleteItem(val id: String) : Intent
        data class UpdateSearchQuery(val query: String) : Intent

        // 에러 처리
        data object DismissError : Intent
    }

    /**
     * SideEffect - 일회성 이벤트 (Toast, Navigation, etc.)
     * State에 포함되지 않아야 하는 이벤트들
     */
    sealed interface SideEffect {
        data class ShowToast(val message: String) : SideEffect
        data class ShowSnackbar(val message: String, val action: String? = null) : SideEffect
        data class NavigateToDetail(val itemId: String) : SideEffect
        data object NavigateBack : SideEffect
    }
}
```

## ViewModel Implementation

```kotlin
@HiltViewModel
class FeatureViewModel @Inject constructor(
    private val getItemsUseCase: GetItemsUseCase,
    private val deleteItemUseCase: DeleteItemUseCase,
    savedStateHandle: SavedStateHandle
) : ViewModel() {

    // State
    private val _state = MutableStateFlow(FeatureContract.State.Initial)
    val state: StateFlow<FeatureContract.State> = _state.asStateFlow()

    // SideEffect
    private val _sideEffect = Channel<FeatureContract.SideEffect>(Channel.BUFFERED)
    val sideEffect: Flow<FeatureContract.SideEffect> = _sideEffect.receiveAsFlow()

    init {
        // 초기 데이터 로딩
        processIntent(FeatureContract.Intent.LoadItems)
    }

    /**
     * 단일 진입점: 모든 Intent 처리
     */
    fun processIntent(intent: FeatureContract.Intent) {
        when (intent) {
            is FeatureContract.Intent.LoadItems -> loadItems()
            is FeatureContract.Intent.Refresh -> refresh()
            is FeatureContract.Intent.SelectItem -> selectItem(intent.id)
            is FeatureContract.Intent.DeleteItem -> deleteItem(intent.id)
            is FeatureContract.Intent.UpdateSearchQuery -> updateSearchQuery(intent.query)
            is FeatureContract.Intent.DismissError -> dismissError()
        }
    }

    private fun loadItems() {
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true, error = null) }

            getItemsUseCase()
                .onSuccess { items ->
                    _state.update {
                        it.copy(
                            items = items.toImmutableList(),
                            isLoading = false
                        )
                    }
                }
                .onFailure { error ->
                    _state.update {
                        it.copy(
                            error = error.message ?: "Unknown error",
                            isLoading = false
                        )
                    }
                }
        }
    }

    private fun selectItem(id: String) {
        viewModelScope.launch {
            _sideEffect.send(
                FeatureContract.SideEffect.NavigateToDetail(id)
            )
        }
    }

    private fun deleteItem(id: String) {
        viewModelScope.launch {
            deleteItemUseCase(id)
                .onSuccess {
                    _sideEffect.send(
                        FeatureContract.SideEffect.ShowToast("Item deleted")
                    )
                    // 목록 새로고침
                    processIntent(FeatureContract.Intent.Refresh)
                }
                .onFailure { error ->
                    _sideEffect.send(
                        FeatureContract.SideEffect.ShowToast(
                            error.message ?: "Failed to delete"
                        )
                    )
                }
        }
    }

    private fun updateSearchQuery(query: String) {
        _state.update { it.copy(searchQuery = query) }
    }

    private fun dismissError() {
        _state.update { it.copy(error = null) }
    }
}
```

## UI Layer

### Route (Navigation Entry Point)

```kotlin
@Composable
fun FeatureRoute(
    viewModel: FeatureViewModel = hiltViewModel(),
    onNavigateToDetail: (String) -> Unit,
    onNavigateBack: () -> Unit
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val context = LocalContext.current
    val snackbarHostState = remember { SnackbarHostState() }

    // SideEffect 처리
    LaunchedEffect(Unit) {
        viewModel.sideEffect.collect { effect ->
            when (effect) {
                is FeatureContract.SideEffect.ShowToast -> {
                    Toast.makeText(context, effect.message, Toast.LENGTH_SHORT).show()
                }
                is FeatureContract.SideEffect.ShowSnackbar -> {
                    snackbarHostState.showSnackbar(
                        message = effect.message,
                        actionLabel = effect.action
                    )
                }
                is FeatureContract.SideEffect.NavigateToDetail -> {
                    onNavigateToDetail(effect.itemId)
                }
                FeatureContract.SideEffect.NavigateBack -> {
                    onNavigateBack()
                }
            }
        }
    }

    FeatureScreen(
        state = state,
        snackbarHostState = snackbarHostState,
        onIntent = viewModel::processIntent
    )
}
```

### Screen

```kotlin
@Composable
fun FeatureScreen(
    state: FeatureContract.State,
    snackbarHostState: SnackbarHostState,
    onIntent: (FeatureContract.Intent) -> Unit
) {
    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            SearchTopBar(
                query = state.searchQuery,
                onQueryChange = { onIntent(FeatureContract.Intent.UpdateSearchQuery(it)) }
            )
        }
    ) { padding ->
        Box(modifier = Modifier.padding(padding)) {
            when {
                state.isLoading -> {
                    LoadingContent()
                }
                state.error != null -> {
                    ErrorContent(
                        message = state.error,
                        onRetry = { onIntent(FeatureContract.Intent.LoadItems) },
                        onDismiss = { onIntent(FeatureContract.Intent.DismissError) }
                    )
                }
                state.items.isEmpty() -> {
                    EmptyContent()
                }
                else -> {
                    ItemList(
                        items = state.items,
                        onItemClick = { onIntent(FeatureContract.Intent.SelectItem(it)) },
                        onItemDelete = { onIntent(FeatureContract.Intent.DeleteItem(it)) }
                    )
                }
            }
        }
    }
}
```

## Testing MVI

```kotlin
@OptIn(ExperimentalCoroutinesApi::class)
class FeatureViewModelTest {

    @get:Rule
    val mainDispatcherRule = MainDispatcherRule()

    private lateinit var viewModel: FeatureViewModel
    private val getItemsUseCase: GetItemsUseCase = mockk()
    private val deleteItemUseCase: DeleteItemUseCase = mockk()

    @Before
    fun setup() {
        coEvery { getItemsUseCase() } returns Result.success(emptyList())
        viewModel = FeatureViewModel(getItemsUseCase, deleteItemUseCase, SavedStateHandle())
    }

    @Test
    fun `when LoadItems intent, should update state with items`() = runTest {
        // Given
        val items = listOf(Item("1", "Test"))
        coEvery { getItemsUseCase() } returns Result.success(items)

        // When
        viewModel.processIntent(FeatureContract.Intent.LoadItems)

        // Then
        val state = viewModel.state.value
        assertThat(state.items).hasSize(1)
        assertThat(state.isLoading).isFalse()
    }

    @Test
    fun `when SelectItem intent, should emit NavigateToDetail side effect`() = runTest {
        // Given
        val itemId = "123"

        // When
        viewModel.processIntent(FeatureContract.Intent.SelectItem(itemId))

        // Then
        val effect = viewModel.sideEffect.first()
        assertThat(effect).isEqualTo(
            FeatureContract.SideEffect.NavigateToDetail(itemId)
        )
    }
}
```

## Best Practices

1. **State는 항상 Immutable** - data class와 ImmutableList 사용
2. **Intent는 Sealed Interface** - exhaustive when 보장
3. **단일 진입점** - processIntent를 통해 모든 액션 처리
4. **SideEffect는 일회성** - Channel을 사용하여 한 번만 소비
5. **Reducer 패턴** - State 업데이트는 순수 함수로

```kotlin
// Reducer pattern example
private fun reduce(state: State, result: Result): State {
    return when (result) {
        is Result.Loading -> state.copy(isLoading = true)
        is Result.Success -> state.copy(items = result.items, isLoading = false)
        is Result.Error -> state.copy(error = result.message, isLoading = false)
    }
}
```
