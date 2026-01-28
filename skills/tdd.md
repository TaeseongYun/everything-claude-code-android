# Test-Driven Development for Android

Android 앱을 위한 TDD 가이드.

## TDD Cycle

```
🔴 RED    → 실패하는 테스트 작성
🟢 GREEN  → 테스트를 통과하는 최소한의 코드 작성
🔵 REFACTOR → 코드 개선 (테스트는 계속 통과)
```

## Test Types

### 1. Unit Tests (JVM)

ViewModel, UseCase, Repository 등 비즈니스 로직 테스트.

```kotlin
// 위치: src/test/java/...
// 실행: ./gradlew test
```

### 2. Instrumented Tests (Android)

Compose UI, Room DB, Context 필요 테스트.

```kotlin
// 위치: src/androidTest/java/...
// 실행: ./gradlew connectedAndroidTest
```

## Test Setup

### Dependencies

```kotlin
// build.gradle.kts
dependencies {
    // Unit Test
    testImplementation("junit:junit:4.13.2")
    testImplementation("io.mockk:mockk:1.13.8")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.7.3")
    testImplementation("com.google.truth:truth:1.1.5")
    testImplementation("app.cash.turbine:turbine:1.0.0")

    // Android Test
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")
    androidTestImplementation("io.mockk:mockk-android:1.13.8")
    debugImplementation("androidx.compose.ui:ui-test-manifest")
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
```

## ViewModel Testing

### Basic Test

```kotlin
@OptIn(ExperimentalCoroutinesApi::class)
class HomeViewModelTest {

    @get:Rule
    val mainDispatcherRule = MainDispatcherRule()

    private lateinit var viewModel: HomeViewModel
    private val getItemsUseCase: GetItemsUseCase = mockk()

    @Before
    fun setup() {
        // 기본 동작 설정
        coEvery { getItemsUseCase() } returns Result.success(emptyList())
        viewModel = HomeViewModel(getItemsUseCase)
    }

    @Test
    fun `초기 상태는 Loading이다`() = runTest {
        // Given: 새로운 ViewModel 생성 전

        // When: ViewModel 생성
        val viewModel = HomeViewModel(getItemsUseCase)

        // Then: 초기 상태 확인 (init에서 loadItems 호출 후)
        // Note: 실제로는 init에서 로딩이 완료된 후 상태 확인
    }

    @Test
    fun `loadItems 성공 시 items가 업데이트된다`() = runTest {
        // Given
        val items = listOf(Item("1", "Test Item"))
        coEvery { getItemsUseCase() } returns Result.success(items)

        // When
        viewModel.processIntent(HomeContract.Intent.LoadItems)

        // Then
        val state = viewModel.state.value
        assertThat(state.items).hasSize(1)
        assertThat(state.items[0].name).isEqualTo("Test Item")
        assertThat(state.isLoading).isFalse()
    }

    @Test
    fun `loadItems 실패 시 error가 설정된다`() = runTest {
        // Given
        val errorMessage = "Network error"
        coEvery { getItemsUseCase() } returns Result.failure(Exception(errorMessage))

        // When
        viewModel.processIntent(HomeContract.Intent.LoadItems)

        // Then
        val state = viewModel.state.value
        assertThat(state.error).isEqualTo(errorMessage)
        assertThat(state.isLoading).isFalse()
    }
}
```

### Testing Side Effects

```kotlin
@Test
fun `SelectItem Intent는 NavigateToDetail SideEffect를 발생시킨다`() = runTest {
    // Given
    val itemId = "123"

    // When
    viewModel.processIntent(HomeContract.Intent.SelectItem(itemId))

    // Then: Turbine 사용
    viewModel.sideEffect.test {
        val effect = awaitItem()
        assertThat(effect).isEqualTo(
            HomeContract.SideEffect.NavigateToDetail(itemId)
        )
    }
}
```

### Testing StateFlow with Turbine

```kotlin
@Test
fun `상태 변화를 순서대로 검증한다`() = runTest {
    // Given
    val items = listOf(Item("1", "Test"))
    coEvery { getItemsUseCase() } coAnswers {
        delay(100) // 지연 시뮬레이션
        Result.success(items)
    }

    // When & Then
    viewModel.state.test {
        // 초기 상태
        assertThat(awaitItem().isLoading).isFalse()

        // LoadItems 호출
        viewModel.processIntent(HomeContract.Intent.LoadItems)

        // Loading 상태
        assertThat(awaitItem().isLoading).isTrue()

        // 완료 상태
        val finalState = awaitItem()
        assertThat(finalState.isLoading).isFalse()
        assertThat(finalState.items).hasSize(1)
    }
}
```

## Repository Testing

```kotlin
@OptIn(ExperimentalCoroutinesApi::class)
class UserRepositoryTest {

    private lateinit var repository: UserRepository
    private val remoteDataSource: UserRemoteDataSource = mockk()
    private val localDataSource: UserLocalDataSource = mockk()
    private val testDispatcher = UnconfinedTestDispatcher()

    @Before
    fun setup() {
        repository = UserRepositoryImpl(
            remoteDataSource = remoteDataSource,
            localDataSource = localDataSource,
            dispatcher = testDispatcher
        )
    }

    @Test
    fun `getUser는 로컬 데이터를 먼저 반환한다`() = runTest {
        // Given
        val localUser = UserEntity("1", "Local User")
        every { localDataSource.getUser("1") } returns flowOf(localUser)

        // When
        val result = repository.getUser("1").first()

        // Then
        assertThat(result.name).isEqualTo("Local User")
    }

    @Test
    fun `refresh는 원격에서 가져와 로컬에 저장한다`() = runTest {
        // Given
        val remoteUser = UserDto("1", "Remote User")
        coEvery { remoteDataSource.fetchUser("1") } returns remoteUser
        coEvery { localDataSource.insertUser(any()) } just Runs

        // When
        repository.refresh("1")

        // Then
        coVerify { remoteDataSource.fetchUser("1") }
        coVerify { localDataSource.insertUser(match { it.name == "Remote User" }) }
    }
}
```

## Compose UI Testing

```kotlin
class HomeScreenTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun `로딩 중일 때 프로그레스 인디케이터가 표시된다`() {
        // Given
        val state = HomeContract.State(isLoading = true)

        // When
        composeTestRule.setContent {
            AppTheme {
                HomeScreen(state = state, onIntent = {})
            }
        }

        // Then
        composeTestRule
            .onNodeWithTag("loading_indicator")
            .assertIsDisplayed()
    }

    @Test
    fun `아이템 클릭 시 SelectItem Intent가 호출된다`() {
        // Given
        val items = persistentListOf(Item("1", "Test Item"))
        val state = HomeContract.State(items = items)
        var capturedIntent: HomeContract.Intent? = null

        // When
        composeTestRule.setContent {
            AppTheme {
                HomeScreen(
                    state = state,
                    onIntent = { capturedIntent = it }
                )
            }
        }

        composeTestRule
            .onNodeWithText("Test Item")
            .performClick()

        // Then
        assertThat(capturedIntent).isEqualTo(
            HomeContract.Intent.SelectItem("1")
        )
    }

    @Test
    fun `에러 메시지가 표시된다`() {
        // Given
        val state = HomeContract.State(error = "Something went wrong")

        // When
        composeTestRule.setContent {
            AppTheme {
                HomeScreen(state = state, onIntent = {})
            }
        }

        // Then
        composeTestRule
            .onNodeWithText("Something went wrong")
            .assertIsDisplayed()
    }
}
```

## Fakes vs Mocks

### Fake (선호)

```kotlin
class FakeUserRepository : UserRepository {
    private val users = mutableMapOf<String, User>()
    var shouldReturnError = false

    override fun getUser(id: String): Flow<User?> {
        return flow {
            if (shouldReturnError) {
                throw Exception("Test error")
            }
            emit(users[id])
        }
    }

    override suspend fun saveUser(user: User) {
        users[user.id] = user
    }

    fun addUser(user: User) {
        users[user.id] = user
    }

    fun clear() {
        users.clear()
    }
}
```

### Mock (필요시)

```kotlin
// MockK 사용
val repository: UserRepository = mockk()

// 동작 정의
coEvery { repository.getUser("1") } returns flowOf(testUser)

// 호출 검증
coVerify { repository.saveUser(any()) }
```

## Test Naming Convention

```kotlin
// 패턴: `when_조건_then_결과` 또는 한글 설명
@Test
fun `when loadItems succeeds then state contains items`()

@Test
fun `loadItems 성공 시 state에 items가 포함된다`()

@Test
fun `빈 검색어로 검색하면 전체 목록이 반환된다`()
```

## Coverage Goals

| Layer | Target |
|-------|--------|
| ViewModel | 90%+ |
| UseCase | 100% |
| Repository | 80%+ |
| UI (핵심 상호작용) | 70%+ |

## Running Tests

```bash
# 전체 Unit Test
./gradlew test

# 특정 모듈 테스트
./gradlew :feature:home:test

# 커버리지 리포트
./gradlew jacocoTestReport

# Android Instrumented Test
./gradlew connectedAndroidTest
```
