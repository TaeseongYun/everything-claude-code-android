# /generate-screen - 단일 화면 생성

기존 Feature 모듈에 새로운 화면을 추가합니다.

## Usage

```bash
/generate-screen <ScreenName> [options]

Options:
  --module <module>     # 대상 모듈 (default: 현재 디렉토리)
  --pattern mvi|mvvm    # 아키텍처 패턴
  --type list|detail|form|empty  # 화면 타입
```

## Examples

```bash
# 기본 화면 생성
/generate-screen ClassDetail --module :feature:class

# 목록 화면 생성
/generate-screen ClassList --type list

# 폼 화면 생성
/generate-screen ClassCreate --type form
```

## Generated Files

```
feature/class/
└── src/main/kotlin/.../
    ├── ClassDetailContract.kt
    ├── ClassDetailViewModel.kt
    └── ui/
        ├── ClassDetailRoute.kt
        └── ClassDetailScreen.kt
```

## Screen Types

### List Screen (`--type list`)

```kotlin
@Composable
fun ClassListScreen(
    state: ClassListContract.State,
    onIntent: (ClassListContract.Intent) -> Unit
) {
    Scaffold(
        topBar = { ClassListTopBar(onSearch = { /* ... */ }) }
    ) { padding ->
        when {
            state.isLoading -> LoadingContent()
            state.error != null -> ErrorContent(state.error, onRetry = { onIntent(Intent.Refresh) })
            state.items.isEmpty() -> EmptyContent("No classes found")
            else -> {
                LazyColumn(
                    modifier = Modifier.padding(padding),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(state.items, key = { it.id }) { item ->
                        ClassListItem(
                            item = item,
                            onClick = { onIntent(Intent.SelectItem(item.id)) }
                        )
                    }
                }
            }
        }
    }
}
```

### Detail Screen (`--type detail`)

```kotlin
@Composable
fun ClassDetailScreen(
    state: ClassDetailContract.State,
    onIntent: (ClassDetailContract.Intent) -> Unit,
    onNavigateBack: () -> Unit
) {
    Scaffold(
        topBar = {
            DetailTopBar(
                title = state.item?.title ?: "",
                onBack = onNavigateBack,
                actions = {
                    IconButton(onClick = { onIntent(Intent.Edit) }) {
                        Icon(Icons.Default.Edit, contentDescription = "Edit")
                    }
                }
            )
        }
    ) { padding ->
        when {
            state.isLoading -> LoadingContent()
            state.error != null -> ErrorContent(state.error)
            state.item != null -> {
                ClassDetailContent(
                    item = state.item,
                    modifier = Modifier.padding(padding)
                )
            }
        }
    }
}
```

### Form Screen (`--type form`)

```kotlin
@Composable
fun ClassCreateScreen(
    state: ClassCreateContract.State,
    onIntent: (ClassCreateContract.Intent) -> Unit,
    onNavigateBack: () -> Unit
) {
    Scaffold(
        topBar = {
            FormTopBar(
                title = "Create Class",
                onBack = onNavigateBack,
                onSave = { onIntent(Intent.Submit) },
                saveEnabled = state.isValid && !state.isSubmitting
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .padding(16.dp)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            OutlinedTextField(
                value = state.title,
                onValueChange = { onIntent(Intent.UpdateTitle(it)) },
                label = { Text("Title") },
                isError = state.titleError != null,
                supportingText = state.titleError?.let { { Text(it) } },
                modifier = Modifier.fillMaxWidth()
            )

            OutlinedTextField(
                value = state.description,
                onValueChange = { onIntent(Intent.UpdateDescription(it)) },
                label = { Text("Description") },
                minLines = 3,
                modifier = Modifier.fillMaxWidth()
            )

            // More form fields...
        }

        if (state.isSubmitting) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator()
            }
        }
    }
}
```

### Empty/Static Screen (`--type empty`)

```kotlin
@Composable
fun AboutScreen(
    onNavigateBack: () -> Unit
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("About") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text("App Version 1.0.0")
            Spacer(modifier = Modifier.height(8.dp))
            Text("© 2024 Company Name")
        }
    }
}
```

## Contract Templates by Type

### List Contract

```kotlin
interface ClassListContract {
    @Immutable
    data class State(
        val isLoading: Boolean = false,
        val items: ImmutableList<ClassItem> = persistentListOf(),
        val error: String? = null,
        val searchQuery: String = "",
        val isRefreshing: Boolean = false
    )

    sealed interface Intent {
        data object LoadItems : Intent
        data object Refresh : Intent
        data class Search(val query: String) : Intent
        data class SelectItem(val id: String) : Intent
        data class DeleteItem(val id: String) : Intent
    }

    sealed interface SideEffect {
        data class NavigateToDetail(val id: String) : SideEffect
        data class ShowToast(val message: String) : SideEffect
    }
}
```

### Form Contract

```kotlin
interface ClassCreateContract {
    @Immutable
    data class State(
        val title: String = "",
        val titleError: String? = null,
        val description: String = "",
        val isSubmitting: Boolean = false
    ) {
        val isValid: Boolean get() = title.isNotBlank() && titleError == null
    }

    sealed interface Intent {
        data class UpdateTitle(val title: String) : Intent
        data class UpdateDescription(val description: String) : Intent
        data object Submit : Intent
    }

    sealed interface SideEffect {
        data object NavigateBack : SideEffect
        data class ShowError(val message: String) : SideEffect
    }
}
```

## Auto-Navigation Setup

```kotlin
// Generated navigation extension
fun NavGraphBuilder.classDetailScreen(
    onNavigateBack: () -> Unit,
    onNavigateToEdit: (String) -> Unit
) {
    composable(
        route = "class/{classId}",
        arguments = listOf(
            navArgument("classId") { type = NavType.StringType }
        )
    ) {
        ClassDetailRoute(
            onNavigateBack = onNavigateBack,
            onNavigateToEdit = onNavigateToEdit
        )
    }
}

fun NavController.navigateToClassDetail(classId: String) {
    navigate("class/$classId")
}
```

## Preview Generation

```kotlin
@Preview(showBackground = true)
@Preview(showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun ClassDetailScreenPreview() {
    AppTheme {
        ClassDetailScreen(
            state = ClassDetailContract.State(
                item = PreviewData.classItem
            ),
            onIntent = {},
            onNavigateBack = {}
        )
    }
}

@Preview(showBackground = true)
@Composable
private fun ClassDetailScreenLoadingPreview() {
    AppTheme {
        ClassDetailScreen(
            state = ClassDetailContract.State(isLoading = true),
            onIntent = {},
            onNavigateBack = {}
        )
    }
}
```
