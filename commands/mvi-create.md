# /mvi-create - Create MVI Architecture Components

Generate MVI (Model-View-Intent) architecture boilerplate for a feature.

## Usage

```
/mvi-create [FeatureName]
```

## Examples

```
/mvi-create Home
/mvi-create UserProfile
/mvi-create ClassDetail
```

## Generated Files

```
feature/[name]/
├── [Name]Contract.kt      # State, Intent, SideEffect
├── [Name]ViewModel.kt     # ViewModel with MVI pattern
├── [Name]Route.kt         # Navigation composable
├── [Name]Screen.kt        # UI composable
└── navigation/
    └── [Name]Navigation.kt # Navigation setup
```

## Contract Template

```kotlin
interface HomeContract {

    @Immutable
    data class State(
        val isLoading: Boolean = false,
        val items: ImmutableList<Item> = persistentListOf(),
        val error: String? = null
    )

    sealed interface Intent {
        data object LoadItems : Intent
        data object Refresh : Intent
        data class SelectItem(val id: String) : Intent
        data class DeleteItem(val id: String) : Intent
    }

    sealed interface SideEffect {
        data class ShowToast(val message: String) : SideEffect
        data class NavigateToDetail(val id: String) : SideEffect
        data object NavigateBack : SideEffect
    }
}
```

## ViewModel Template

```kotlin
@HiltViewModel
class HomeViewModel @Inject constructor(
    private val getItemsUseCase: GetItemsUseCase,
    private val deleteItemUseCase: DeleteItemUseCase
) : ViewModel() {

    private val _state = MutableStateFlow(HomeContract.State())
    val state: StateFlow<HomeContract.State> = _state.asStateFlow()

    private val _sideEffect = Channel<HomeContract.SideEffect>()
    val sideEffect: Flow<HomeContract.SideEffect> = _sideEffect.receiveAsFlow()

    init {
        processIntent(HomeContract.Intent.LoadItems)
    }

    fun processIntent(intent: HomeContract.Intent) {
        when (intent) {
            is HomeContract.Intent.LoadItems -> loadItems()
            is HomeContract.Intent.Refresh -> refresh()
            is HomeContract.Intent.SelectItem -> selectItem(intent.id)
            is HomeContract.Intent.DeleteItem -> deleteItem(intent.id)
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
                            error = error.message,
                            isLoading = false
                        )
                    }
                }
        }
    }

    private fun selectItem(id: String) {
        viewModelScope.launch {
            _sideEffect.send(HomeContract.SideEffect.NavigateToDetail(id))
        }
    }

    private fun deleteItem(id: String) {
        viewModelScope.launch {
            deleteItemUseCase(id)
                .onSuccess {
                    _sideEffect.send(
                        HomeContract.SideEffect.ShowToast("Item deleted")
                    )
                    processIntent(HomeContract.Intent.Refresh)
                }
                .onFailure { error ->
                    _sideEffect.send(
                        HomeContract.SideEffect.ShowToast(
                            error.message ?: "Failed to delete"
                        )
                    )
                }
        }
    }
}
```

## Screen Template

```kotlin
@Composable
fun HomeRoute(
    viewModel: HomeViewModel = hiltViewModel(),
    onNavigateToDetail: (String) -> Unit,
    onNavigateBack: () -> Unit
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val context = LocalContext.current

    LaunchedEffect(Unit) {
        viewModel.sideEffect.collect { effect ->
            when (effect) {
                is HomeContract.SideEffect.ShowToast -> {
                    Toast.makeText(context, effect.message, Toast.LENGTH_SHORT).show()
                }
                is HomeContract.SideEffect.NavigateToDetail -> {
                    onNavigateToDetail(effect.id)
                }
                HomeContract.SideEffect.NavigateBack -> {
                    onNavigateBack()
                }
            }
        }
    }

    HomeScreen(
        state = state,
        onIntent = viewModel::processIntent
    )
}

@Composable
fun HomeScreen(
    state: HomeContract.State,
    onIntent: (HomeContract.Intent) -> Unit
) {
    // UI implementation
}
```

## Options

| Option | Description |
|--------|-------------|
| `--with-test` | Generate test file |
| `--with-preview` | Generate preview functions |
| `--simple` | Minimal implementation |

## Tips

- Use `ImmutableList` for stable Compose recomposition
- Keep State immutable
- Use SideEffect for one-time events
- Process intents through single function
