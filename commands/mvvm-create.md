# /mvvm-create - Create MVVM Architecture Components

Generate MVVM (Model-View-ViewModel) architecture boilerplate for a feature.

## Usage

```
/mvvm-create [FeatureName]
```

## Examples

```
/mvvm-create Settings
/mvvm-create Notification
/mvvm-create Search
```

## Generated Files

```
feature/[name]/
├── [Name]UiState.kt       # UI State data class
├── [Name]ViewModel.kt     # ViewModel with StateFlow
├── [Name]Route.kt         # Navigation composable
├── [Name]Screen.kt        # UI composable
└── navigation/
    └── [Name]Navigation.kt # Navigation setup
```

## UiState Template

```kotlin
@Immutable
data class SettingsUiState(
    val isLoading: Boolean = false,
    val settings: Settings? = null,
    val error: String? = null,
    val isSaving: Boolean = false
) {
    companion object {
        val Initial = SettingsUiState()
        val Loading = SettingsUiState(isLoading = true)
    }
}
```

## ViewModel Template

```kotlin
@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val getSettingsUseCase: GetSettingsUseCase,
    private val updateSettingsUseCase: UpdateSettingsUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow(SettingsUiState.Initial)
    val uiState: StateFlow<SettingsUiState> = _uiState.asStateFlow()

    private val _events = Channel<SettingsEvent>()
    val events: Flow<SettingsEvent> = _events.receiveAsFlow()

    init {
        loadSettings()
    }

    fun loadSettings() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            getSettingsUseCase()
                .onSuccess { settings ->
                    _uiState.update {
                        it.copy(settings = settings, isLoading = false)
                    }
                }
                .onFailure { error ->
                    _uiState.update {
                        it.copy(error = error.message, isLoading = false)
                    }
                }
        }
    }

    fun updateNotificationEnabled(enabled: Boolean) {
        val currentSettings = _uiState.value.settings ?: return

        viewModelScope.launch {
            _uiState.update { it.copy(isSaving = true) }

            val newSettings = currentSettings.copy(notificationEnabled = enabled)
            updateSettingsUseCase(newSettings)
                .onSuccess {
                    _uiState.update {
                        it.copy(settings = newSettings, isSaving = false)
                    }
                    _events.send(SettingsEvent.SettingsSaved)
                }
                .onFailure { error ->
                    _uiState.update { it.copy(isSaving = false) }
                    _events.send(SettingsEvent.Error(error.message ?: "Failed to save"))
                }
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }
}

sealed interface SettingsEvent {
    data object SettingsSaved : SettingsEvent
    data class Error(val message: String) : SettingsEvent
}
```

## Route Template

```kotlin
@Composable
fun SettingsRoute(
    viewModel: SettingsViewModel = hiltViewModel(),
    onNavigateBack: () -> Unit
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val context = LocalContext.current

    LaunchedEffect(Unit) {
        viewModel.events.collect { event ->
            when (event) {
                is SettingsEvent.SettingsSaved -> {
                    Toast.makeText(context, "Settings saved", Toast.LENGTH_SHORT).show()
                }
                is SettingsEvent.Error -> {
                    Toast.makeText(context, event.message, Toast.LENGTH_SHORT).show()
                }
            }
        }
    }

    SettingsScreen(
        uiState = uiState,
        onNotificationToggle = viewModel::updateNotificationEnabled,
        onRetry = viewModel::loadSettings,
        onNavigateBack = onNavigateBack
    )
}
```

## Screen Template

```kotlin
@Composable
fun SettingsScreen(
    uiState: SettingsUiState,
    onNotificationToggle: (Boolean) -> Unit,
    onRetry: () -> Unit,
    onNavigateBack: () -> Unit
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Settings") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { padding ->
        when {
            uiState.isLoading -> {
                LoadingContent(modifier = Modifier.padding(padding))
            }
            uiState.error != null -> {
                ErrorContent(
                    message = uiState.error,
                    onRetry = onRetry,
                    modifier = Modifier.padding(padding)
                )
            }
            uiState.settings != null -> {
                SettingsContent(
                    settings = uiState.settings,
                    isSaving = uiState.isSaving,
                    onNotificationToggle = onNotificationToggle,
                    modifier = Modifier.padding(padding)
                )
            }
        }
    }
}
```

## MVVM vs MVI Comparison

| Aspect | MVVM | MVI |
|--------|------|-----|
| State | Single StateFlow | Contract.State |
| Actions | Multiple functions | Single processIntent |
| Events | Event Channel | SideEffect Channel |
| Complexity | Simpler | More structured |
| Use Case | Simple screens | Complex interactions |

## Options

| Option | Description |
|--------|-------------|
| `--with-test` | Generate test file |
| `--with-preview` | Generate preview functions |
| `--with-repository` | Include repository pattern |

## Tips

- Use MVVM for simpler screens
- Consider MVI for complex user interactions
- Keep UI state immutable
- Use events/channels for one-time UI actions
