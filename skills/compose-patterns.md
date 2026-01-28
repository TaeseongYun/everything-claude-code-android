# Jetpack Compose Patterns

Best practices and patterns for Jetpack Compose UI development.

## Composable Naming Convention

### Route / Screen / Content Pattern

```kotlin
// Route: ViewModel 연결, Navigation 처리, DI
@Composable
fun HomeRoute(
    viewModel: HomeViewModel = hiltViewModel(),
    onNavigateToDetail: (String) -> Unit
) {
    val state by viewModel.state.collectAsStateWithLifecycle()

    LaunchedEffect(Unit) {
        viewModel.sideEffect.collect { effect ->
            when (effect) {
                is SideEffect.NavigateToDetail -> onNavigateToDetail(effect.id)
            }
        }
    }

    HomeScreen(
        state = state,
        onIntent = viewModel::processIntent
    )
}

// Screen: 전체 화면 레이아웃, Scaffold
@Composable
fun HomeScreen(
    state: HomeState,
    onIntent: (HomeIntent) -> Unit
) {
    Scaffold(
        topBar = { HomeTopBar() }
    ) { padding ->
        HomeContent(
            state = state,
            onIntent = onIntent,
            modifier = Modifier.padding(padding)
        )
    }
}

// Content: 실제 UI 구현
@Composable
private fun HomeContent(
    state: HomeState,
    onIntent: (HomeIntent) -> Unit,
    modifier: Modifier = Modifier
) {
    LazyColumn(modifier = modifier) {
        items(state.items, key = { it.id }) { item ->
            ItemRow(
                item = item,
                onClick = { onIntent(HomeIntent.SelectItem(item.id)) }
            )
        }
    }
}
```

## State Hoisting

```kotlin
// ❌ Bad: State inside composable
@Composable
fun Counter() {
    var count by remember { mutableStateOf(0) }
    Button(onClick = { count++ }) {
        Text("Count: $count")
    }
}

// ✅ Good: State hoisted
@Composable
fun Counter(
    count: Int,
    onIncrement: () -> Unit
) {
    Button(onClick = onIncrement) {
        Text("Count: $count")
    }
}

// Usage
@Composable
fun CounterScreen() {
    var count by remember { mutableStateOf(0) }
    Counter(
        count = count,
        onIncrement = { count++ }
    )
}
```

## Stability and Recomposition

### Stable Types

```kotlin
// ❌ Bad: Unstable list causes recomposition
data class UiState(
    val items: List<Item>  // List is unstable
)

// ✅ Good: Use immutable collections
@Immutable
data class UiState(
    val items: ImmutableList<Item>
)

// Or use @Stable annotation for custom classes
@Stable
class StableWrapper<T>(val value: T)
```

### Lambda Stability

```kotlin
// ❌ Bad: Lambda recreated every recomposition
@Composable
fun ItemList(viewModel: ViewModel) {
    LazyColumn {
        items(items) { item ->
            ItemRow(
                onClick = { viewModel.onItemClick(item.id) }  // New lambda
            )
        }
    }
}

// ✅ Good: Remember lambda or hoist to parent
@Composable
fun ItemList(
    items: List<Item>,
    onItemClick: (String) -> Unit
) {
    LazyColumn {
        items(items, key = { it.id }) { item ->
            ItemRow(
                onClick = remember(item.id) { { onItemClick(item.id) } }
            )
        }
    }
}
```

## Side Effects

### LaunchedEffect

```kotlin
// 한 번만 실행
LaunchedEffect(Unit) {
    viewModel.loadData()
}

// key가 변경될 때마다 실행
LaunchedEffect(userId) {
    viewModel.loadUser(userId)
}

// Flow 수집
LaunchedEffect(Unit) {
    viewModel.events.collect { event ->
        when (event) {
            is Event.ShowToast -> showToast(event.message)
        }
    }
}
```

### DisposableEffect

```kotlin
@Composable
fun LifecycleAwareComponent(
    lifecycleOwner: LifecycleOwner = LocalLifecycleOwner.current
) {
    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            when (event) {
                Lifecycle.Event.ON_RESUME -> { /* ... */ }
                Lifecycle.Event.ON_PAUSE -> { /* ... */ }
                else -> {}
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)

        onDispose {
            lifecycleOwner.lifecycle.removeObserver(observer)
        }
    }
}
```

### derivedStateOf

```kotlin
@Composable
fun FilteredList(items: List<Item>, query: String) {
    // ✅ Only recomputes when items or query changes
    val filteredItems by remember(items, query) {
        derivedStateOf {
            items.filter { it.name.contains(query, ignoreCase = true) }
        }
    }

    LazyColumn {
        items(filteredItems) { item ->
            ItemRow(item)
        }
    }
}
```

## Modifier Best Practices

```kotlin
// ✅ Accept modifier parameter
@Composable
fun CustomButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier  // Default to Modifier
) {
    Button(
        onClick = onClick,
        modifier = modifier  // Apply first
            .padding(8.dp)   // Then internal modifiers
    ) {
        Text(text)
    }
}

// ✅ Chain modifiers properly
Box(
    modifier = Modifier
        .fillMaxWidth()
        .padding(16.dp)      // Padding outside
        .background(Color.White)
        .padding(8.dp)       // Padding inside
)
```

## LazyColumn Optimization

```kotlin
@Composable
fun OptimizedList(items: ImmutableList<Item>) {
    LazyColumn {
        items(
            items = items,
            key = { it.id },  // ✅ Always provide key
            contentType = { it.type }  // ✅ Content type for reuse
        ) { item ->
            // Use remember for expensive calculations
            val formattedDate = remember(item.date) {
                formatDate(item.date)
            }

            ItemRow(
                item = item,
                formattedDate = formattedDate
            )
        }
    }
}
```

## Preview Best Practices

```kotlin
@Preview(showBackground = true)
@Preview(showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun ItemCardPreview() {
    AppTheme {
        ItemCard(
            item = PreviewData.sampleItem,
            onClick = {}
        )
    }
}

// Preview with different states
@Preview
@Composable
private fun HomeScreenPreview(
    @PreviewParameter(HomeStateProvider::class) state: HomeState
) {
    AppTheme {
        HomeScreen(state = state, onIntent = {})
    }
}

class HomeStateProvider : PreviewParameterProvider<HomeState> {
    override val values = sequenceOf(
        HomeState(isLoading = true),
        HomeState(items = PreviewData.items),
        HomeState(error = "Error message")
    )
}
```

## CompositionLocal

```kotlin
// Define
val LocalAppColors = compositionLocalOf { AppColors.Light }

// Provide
CompositionLocalProvider(
    LocalAppColors provides if (isDark) AppColors.Dark else AppColors.Light
) {
    Content()
}

// Consume
@Composable
fun ThemedButton() {
    val colors = LocalAppColors.current
    Button(
        colors = ButtonDefaults.buttonColors(
            containerColor = colors.primary
        )
    ) {
        Text("Button")
    }
}
```
