# /compose-preview - Generate Compose Preview Functions

Generate preview functions for Compose UI components.

## Usage

```
/compose-preview [composable name or file]
```

## Examples

```
/compose-preview HomeScreen
/compose-preview feature/home/ui/HomeScreen.kt
/compose-preview ItemCard
```

## What This Command Does

1. Analyzes the Composable function
2. Identifies required parameters
3. Creates preview data/state
4. Generates multiple preview variants

## Preview Templates

### Screen Preview
```kotlin
@Preview(showBackground = true)
@Preview(showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun HomeScreenPreview() {
    AppTheme {
        HomeScreen(
            state = HomeUiState(
                items = listOf(
                    Item("1", "Preview Item 1"),
                    Item("2", "Preview Item 2")
                ),
                isLoading = false
            ),
            onIntent = {}
        )
    }
}

@Preview(showBackground = true)
@Composable
private fun HomeScreenLoadingPreview() {
    AppTheme {
        HomeScreen(
            state = HomeUiState(isLoading = true),
            onIntent = {}
        )
    }
}

@Preview(showBackground = true)
@Composable
private fun HomeScreenEmptyPreview() {
    AppTheme {
        HomeScreen(
            state = HomeUiState(items = emptyList()),
            onIntent = {}
        )
    }
}

@Preview(showBackground = true)
@Composable
private fun HomeScreenErrorPreview() {
    AppTheme {
        HomeScreen(
            state = HomeUiState(error = "Failed to load data"),
            onIntent = {}
        )
    }
}
```

### Component Preview
```kotlin
@Preview(showBackground = true)
@Composable
private fun ItemCardPreview() {
    AppTheme {
        ItemCard(
            item = Item(
                id = "1",
                title = "Preview Title",
                description = "Preview description text"
            ),
            onClick = {}
        )
    }
}
```

### Multi-Device Preview
```kotlin
@Preview(name = "Phone", device = Devices.PHONE)
@Preview(name = "Tablet", device = Devices.TABLET)
@Preview(name = "Foldable", device = Devices.FOLDABLE)
@Composable
private fun ResponsiveScreenPreview() {
    AppTheme {
        ResponsiveScreen(state = previewState)
    }
}
```

### Font Scale Preview
```kotlin
@Preview(fontScale = 1.0f)
@Preview(fontScale = 1.5f)
@Preview(fontScale = 2.0f)
@Composable
private fun TextComponentPreview() {
    AppTheme {
        TextComponent(text = "Sample Text")
    }
}
```

## Preview Data Pattern

```kotlin
// In the same file or PreviewData.kt
internal object PreviewData {
    val sampleItem = Item(
        id = "preview-1",
        title = "Sample Title",
        description = "Sample description for preview"
    )

    val sampleItems = listOf(
        Item("1", "Item 1", "Description 1"),
        Item("2", "Item 2", "Description 2"),
        Item("3", "Item 3", "Description 3")
    )

    val loadingState = HomeUiState(isLoading = true)
    val successState = HomeUiState(items = sampleItems)
    val errorState = HomeUiState(error = "Network error")
    val emptyState = HomeUiState(items = emptyList())
}
```

## Output

Generates:
1. Default preview
2. Dark mode preview
3. Loading state preview
4. Error state preview
5. Empty state preview (if applicable)

## Tips

- Use meaningful preview names
- Include edge cases (empty, error, loading)
- Test with different font scales
- Use `@PreviewParameter` for data-driven previews
