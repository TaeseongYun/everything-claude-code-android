# MVVM Pattern (Model-View-ViewModel)

Comprehensive guide for implementing MVVM architecture in Android.

## Overview

MVVM은 UI와 비즈니스 로직을 분리하는 아키텍처 패턴입니다.

```
┌─────────────────────────────────────────────┐
│                    View                      │
│  (Composable / Activity / Fragment)          │
│                     │                        │
│              observes state                  │
│                     ▼                        │
│  ┌─────────────────────────────────────────┐ │
│  │              ViewModel                   │ │
│  │  ┌─────────┐    ┌──────────────────┐    │ │
│  │  │  State  │    │  Event Channel   │    │ │
│  │  └─────────┘    └──────────────────┘    │ │
│  │         │                               │ │
│  │         ▼                               │ │
│  │  ┌─────────────────────────────────┐    │ │
│  │  │         Use Cases               │    │ │
│  │  └─────────────────────────────────┘    │ │
│  └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

## UI State

```kotlin
/**
 * 화면의 모든 상태를 담는 단일 data class
 */
@Immutable
data class ProfileUiState(
    val isLoading: Boolean = false,
    val user: User? = null,
    val error: String? = null,
    val isEditing: Boolean = false,
    val isSaving: Boolean = false
) {
    // Derived state
    val canSave: Boolean get() = user != null && !isSaving
    val showContent: Boolean get() = !isLoading && error == null

    companion object {
        val Initial = ProfileUiState()
        val Loading = ProfileUiState(isLoading = true)
    }
}
```

## ViewModel

```kotlin
@HiltViewModel
class ProfileViewModel @Inject constructor(
    private val getUserUseCase: GetUserUseCase,
    private val updateUserUseCase: UpdateUserUseCase,
    savedStateHandle: SavedStateHandle
) : ViewModel() {

    private val userId: String = checkNotNull(savedStateHandle["userId"])

    // UI State
    private val _uiState = MutableStateFlow(ProfileUiState.Initial)
    val uiState: StateFlow<ProfileUiState> = _uiState.asStateFlow()

    // One-time events
    private val _events = Channel<ProfileEvent>(Channel.BUFFERED)
    val events: Flow<ProfileEvent> = _events.receiveAsFlow()

    init {
        loadUser()
    }

    // Public functions for UI actions
    fun loadUser() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            getUserUseCase(userId)
                .onSuccess { user ->
                    _uiState.update { it.copy(user = user, isLoading = false) }
                }
                .onFailure { error ->
                    _uiState.update { it.copy(error = error.message, isLoading = false) }
                }
        }
    }

    fun startEditing() {
        _uiState.update { it.copy(isEditing = true) }
    }

    fun cancelEditing() {
        _uiState.update { it.copy(isEditing = false) }
    }

    fun updateName(name: String) {
        _uiState.update { state ->
            state.copy(user = state.user?.copy(name = name))
        }
    }

    fun saveChanges() {
        val user = _uiState.value.user ?: return

        viewModelScope.launch {
            _uiState.update { it.copy(isSaving = true) }

            updateUserUseCase(user)
                .onSuccess {
                    _uiState.update { it.copy(isEditing = false, isSaving = false) }
                    _events.send(ProfileEvent.SaveSuccess)
                }
                .onFailure { error ->
                    _uiState.update { it.copy(isSaving = false) }
                    _events.send(ProfileEvent.SaveError(error.message ?: "Save failed"))
                }
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }
}

// One-time events
sealed interface ProfileEvent {
    data object SaveSuccess : ProfileEvent
    data class SaveError(val message: String) : ProfileEvent
    data object NavigateBack : ProfileEvent
}
```

## UI Layer

### Route

```kotlin
@Composable
fun ProfileRoute(
    viewModel: ProfileViewModel = hiltViewModel(),
    onNavigateBack: () -> Unit
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val context = LocalContext.current

    // Handle one-time events
    LaunchedEffect(Unit) {
        viewModel.events.collect { event ->
            when (event) {
                ProfileEvent.SaveSuccess -> {
                    Toast.makeText(context, "Saved successfully", Toast.LENGTH_SHORT).show()
                }
                is ProfileEvent.SaveError -> {
                    Toast.makeText(context, event.message, Toast.LENGTH_LONG).show()
                }
                ProfileEvent.NavigateBack -> {
                    onNavigateBack()
                }
            }
        }
    }

    ProfileScreen(
        uiState = uiState,
        onRetry = viewModel::loadUser,
        onStartEditing = viewModel::startEditing,
        onCancelEditing = viewModel::cancelEditing,
        onNameChange = viewModel::updateName,
        onSave = viewModel::saveChanges,
        onNavigateBack = onNavigateBack
    )
}
```

### Screen

```kotlin
@Composable
fun ProfileScreen(
    uiState: ProfileUiState,
    onRetry: () -> Unit,
    onStartEditing: () -> Unit,
    onCancelEditing: () -> Unit,
    onNameChange: (String) -> Unit,
    onSave: () -> Unit,
    onNavigateBack: () -> Unit
) {
    Scaffold(
        topBar = {
            ProfileTopBar(
                isEditing = uiState.isEditing,
                onNavigateBack = onNavigateBack,
                onEdit = onStartEditing,
                onCancel = onCancelEditing,
                onSave = onSave,
                canSave = uiState.canSave
            )
        }
    ) { padding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            when {
                uiState.isLoading -> {
                    CircularProgressIndicator(
                        modifier = Modifier.align(Alignment.Center)
                    )
                }
                uiState.error != null -> {
                    ErrorContent(
                        message = uiState.error,
                        onRetry = onRetry,
                        modifier = Modifier.align(Alignment.Center)
                    )
                }
                uiState.user != null -> {
                    ProfileContent(
                        user = uiState.user,
                        isEditing = uiState.isEditing,
                        onNameChange = onNameChange
                    )
                }
            }

            // Saving indicator overlay
            if (uiState.isSaving) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(Color.Black.copy(alpha = 0.3f)),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator()
                }
            }
        }
    }
}
```

## State Update Patterns

### Simple Update

```kotlin
fun toggleDarkMode() {
    _uiState.update { it.copy(isDarkMode = !it.isDarkMode) }
}
```

### Async Update

```kotlin
fun loadData() {
    viewModelScope.launch {
        _uiState.update { it.copy(isLoading = true) }

        repository.getData()
            .onSuccess { data ->
                _uiState.update { it.copy(data = data, isLoading = false) }
            }
            .onFailure { error ->
                _uiState.update { it.copy(error = error.message, isLoading = false) }
            }
    }
}
```

### Multiple State Updates

```kotlin
fun submitForm(form: Form) {
    viewModelScope.launch {
        // Validate
        val validationError = validateForm(form)
        if (validationError != null) {
            _uiState.update { it.copy(validationError = validationError) }
            return@launch
        }

        // Submit
        _uiState.update { it.copy(isSubmitting = true, validationError = null) }

        repository.submit(form)
            .onSuccess {
                _events.send(FormEvent.SubmitSuccess)
            }
            .onFailure { error ->
                _uiState.update { it.copy(isSubmitting = false) }
                _events.send(FormEvent.SubmitError(error.message))
            }
    }
}
```

## Testing MVVM

```kotlin
@OptIn(ExperimentalCoroutinesApi::class)
class ProfileViewModelTest {

    @get:Rule
    val mainDispatcherRule = MainDispatcherRule()

    private lateinit var viewModel: ProfileViewModel
    private val getUserUseCase: GetUserUseCase = mockk()
    private val updateUserUseCase: UpdateUserUseCase = mockk()

    @Before
    fun setup() {
        coEvery { getUserUseCase(any()) } returns Result.success(testUser)
        viewModel = ProfileViewModel(
            getUserUseCase,
            updateUserUseCase,
            SavedStateHandle(mapOf("userId" to "123"))
        )
    }

    @Test
    fun `loadUser should update state with user data`() = runTest {
        // Initial load happens in init
        val state = viewModel.uiState.value

        assertThat(state.user).isEqualTo(testUser)
        assertThat(state.isLoading).isFalse()
    }

    @Test
    fun `startEditing should set isEditing to true`() = runTest {
        viewModel.startEditing()

        assertThat(viewModel.uiState.value.isEditing).isTrue()
    }

    @Test
    fun `saveChanges should emit SaveSuccess event`() = runTest {
        coEvery { updateUserUseCase(any()) } returns Result.success(Unit)

        viewModel.saveChanges()

        val event = viewModel.events.first()
        assertThat(event).isEqualTo(ProfileEvent.SaveSuccess)
    }
}
```

## MVVM vs MVI 선택 가이드

| 기준 | MVVM | MVI |
|-----|------|-----|
| 복잡도 | 단순한 화면 | 복잡한 상호작용 |
| 액션 처리 | 개별 함수 | 단일 processIntent |
| 상태 추적 | 개별 StateFlow 또는 단일 | 항상 단일 State |
| 디버깅 | 상태별 추적 | 전체 상태 스냅샷 |
| 학습 곡선 | 낮음 | 중간 |

### MVVM 추천 상황
- 단순한 CRUD 화면
- 상태가 독립적인 경우
- 팀이 MVVM에 익숙한 경우

### MVI 추천 상황
- 복잡한 사용자 상호작용
- 상태 간 의존성이 있는 경우
- 상태 히스토리/디버깅이 중요한 경우
