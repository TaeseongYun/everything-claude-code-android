# /kotlin-tdd - Test-Driven Development for Kotlin

Write tests first, then implement the feature following TDD principles.

## Usage

```
/kotlin-tdd [feature or class to implement]
```

## Examples

```
/kotlin-tdd UserRepository.fetchUser
/kotlin-tdd HomeViewModel load items functionality
/kotlin-tdd LoginUseCase with validation
```

## TDD Cycle

```
🔴 RED    → Write failing test
🟢 GREEN  → Write minimal code to pass
🔵 REFACTOR → Improve code quality
```

## What This Command Does

1. **Analyzes the requirement**
2. **Writes test cases first**
   - Unit tests for ViewModel
   - Repository tests
   - Use case tests
3. **Implements minimal code to pass**
4. **Refactors while keeping tests green**

## Test Templates

### ViewModel Test
```kotlin
@Test
fun `when loadData called, should update state with data`() = runTest {
    // Given
    coEvery { useCase() } returns Result.success(testData)

    // When
    viewModel.loadData()

    // Then
    assertThat(viewModel.uiState.value.data).isEqualTo(testData)
}
```

### Repository Test
```kotlin
@Test
fun `when fetch succeeds, should return data`() = runTest {
    // Given
    coEvery { api.getData() } returns testResponse

    // When
    val result = repository.fetchData()

    // Then
    assertThat(result.isSuccess).isTrue()
}
```

### Use Case Test
```kotlin
@Test
fun `when input is valid, should return success`() = runTest {
    // Given
    val validInput = "test@email.com"

    // When
    val result = useCase(validInput)

    // Then
    assertThat(result.isSuccess).isTrue()
}
```

## Output

The command will:
1. Create test file with failing tests
2. Implement the feature code
3. Verify all tests pass
4. Suggest refactoring if needed

## Dependencies Used

```kotlin
testImplementation("junit:junit:4.13.2")
testImplementation("io.mockk:mockk:1.13.8")
testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.7.3")
testImplementation("com.google.truth:truth:1.1.5")
testImplementation("app.cash.turbine:turbine:1.0.0")
```

## Tips

- Start with the simplest test case
- One assertion per test when possible
- Test behavior, not implementation
- Use descriptive test names with backticks
