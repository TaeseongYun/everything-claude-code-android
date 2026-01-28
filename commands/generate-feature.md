# /generate-feature - Feature 모듈 전체 생성

MVI/MVVM 아키텍처 기반의 완전한 Feature 모듈을 자동 생성합니다.

## Usage

```bash
/generate-feature <FeatureName> [options]

Options:
  --pattern mvi|mvvm    # 아키텍처 패턴 (default: mvi)
  --package <package>   # 패키지명 (default: 프로젝트 설정)
  --with-list          # 목록 화면 포함
  --with-detail        # 상세 화면 포함
  --with-create        # 생성 화면 포함
```

## Examples

```bash
# 기본 MVI feature 생성
/generate-feature UserProfile

# MVVM 패턴으로 생성
/generate-feature Settings --pattern mvvm

# 목록 + 상세 화면 포함
/generate-feature Product --with-list --with-detail
```

## Generated Structure

```
feature/userprofile/
├── build.gradle.kts
├── src/main/kotlin/com/example/feature/userprofile/
│   ├── UserProfileContract.kt      # State/Intent/SideEffect
│   ├── UserProfileViewModel.kt     # ViewModel
│   ├── ui/
│   │   ├── UserProfileRoute.kt     # Navigation entry
│   │   ├── UserProfileScreen.kt    # Main screen
│   │   └── components/             # Screen-specific components
│   │       ├── UserProfileHeader.kt
│   │       └── UserProfileContent.kt
│   └── navigation/
│       └── UserProfileNavigation.kt
├── src/test/kotlin/com/example/feature/userprofile/
│   └── UserProfileViewModelTest.kt
└── src/androidTest/kotlin/com/example/feature/userprofile/
    └── UserProfileScreenTest.kt
```

## Generated Code Examples

### Contract (MVI)

```kotlin
// UserProfileContract.kt
package com.example.feature.userprofile

import androidx.compose.runtime.Immutable
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.persistentListOf

interface UserProfileContract {

    @Immutable
    data class State(
        val isLoading: Boolean = false,
        val user: User? = null,
        val error: String? = null
    ) {
        companion object {
            val Initial = State()
        }
    }

    sealed interface Intent {
        data object LoadProfile : Intent
        data object Refresh : Intent
        data class UpdateName(val name: String) : Intent
    }

    sealed interface SideEffect {
        data class ShowToast(val message: String) : SideEffect
        data object NavigateBack : SideEffect
    }
}
```

### ViewModel

```kotlin
// UserProfileViewModel.kt
package com.example.feature.userprofile

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class UserProfileViewModel @Inject constructor(
    private val getUserUseCase: GetUserUseCase,
    private val updateUserUseCase: UpdateUserUseCase,
    savedStateHandle: SavedStateHandle
) : ViewModel() {

    private val userId: String = checkNotNull(savedStateHandle["userId"])

    private val _state = MutableStateFlow(UserProfileContract.State.Initial)
    val state: StateFlow<UserProfileContract.State> = _state.asStateFlow()

    private val _sideEffect = Channel<UserProfileContract.SideEffect>(Channel.BUFFERED)
    val sideEffect: Flow<UserProfileContract.SideEffect> = _sideEffect.receiveAsFlow()

    init {
        processIntent(UserProfileContract.Intent.LoadProfile)
    }

    fun processIntent(intent: UserProfileContract.Intent) {
        when (intent) {
            is UserProfileContract.Intent.LoadProfile -> loadProfile()
            is UserProfileContract.Intent.Refresh -> refresh()
            is UserProfileContract.Intent.UpdateName -> updateName(intent.name)
        }
    }

    private fun loadProfile() {
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true, error = null) }
            getUserUseCase(userId)
                .onSuccess { user ->
                    _state.update { it.copy(user = user, isLoading = false) }
                }
                .onFailure { error ->
                    _state.update { it.copy(error = error.message, isLoading = false) }
                }
        }
    }

    private fun refresh() {
        loadProfile()
    }

    private fun updateName(name: String) {
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true) }
            updateUserUseCase(userId, name)
                .onSuccess {
                    _sideEffect.send(UserProfileContract.SideEffect.ShowToast("Updated"))
                    loadProfile()
                }
                .onFailure { error ->
                    _sideEffect.send(UserProfileContract.SideEffect.ShowToast(error.message ?: "Failed"))
                    _state.update { it.copy(isLoading = false) }
                }
        }
    }
}
```

### Screen

```kotlin
// UserProfileRoute.kt
package com.example.feature.userprofile.ui

import android.widget.Toast
import androidx.compose.runtime.*
import androidx.compose.ui.platform.LocalContext
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.feature.userprofile.UserProfileContract
import com.example.feature.userprofile.UserProfileViewModel

@Composable
fun UserProfileRoute(
    viewModel: UserProfileViewModel = hiltViewModel(),
    onNavigateBack: () -> Unit
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val context = LocalContext.current

    LaunchedEffect(Unit) {
        viewModel.sideEffect.collect { effect ->
            when (effect) {
                is UserProfileContract.SideEffect.ShowToast -> {
                    Toast.makeText(context, effect.message, Toast.LENGTH_SHORT).show()
                }
                UserProfileContract.SideEffect.NavigateBack -> {
                    onNavigateBack()
                }
            }
        }
    }

    UserProfileScreen(
        state = state,
        onIntent = viewModel::processIntent,
        onNavigateBack = onNavigateBack
    )
}
```

### Test

```kotlin
// UserProfileViewModelTest.kt
package com.example.feature.userprofile

import androidx.lifecycle.SavedStateHandle
import app.cash.turbine.test
import com.google.common.truth.Truth.assertThat
import io.mockk.*
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runTest
import org.junit.Before
import org.junit.Rule
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class UserProfileViewModelTest {

    @get:Rule
    val mainDispatcherRule = MainDispatcherRule()

    private lateinit var viewModel: UserProfileViewModel
    private val getUserUseCase: GetUserUseCase = mockk()
    private val updateUserUseCase: UpdateUserUseCase = mockk()

    @Before
    fun setup() {
        coEvery { getUserUseCase(any()) } returns Result.success(testUser)
        viewModel = UserProfileViewModel(
            getUserUseCase = getUserUseCase,
            updateUserUseCase = updateUserUseCase,
            savedStateHandle = SavedStateHandle(mapOf("userId" to "123"))
        )
    }

    @Test
    fun `LoadProfile intent should update state with user`() = runTest {
        // Given: ViewModel initialized with LoadProfile in init

        // Then
        val state = viewModel.state.value
        assertThat(state.user).isEqualTo(testUser)
        assertThat(state.isLoading).isFalse()
    }

    @Test
    fun `UpdateName intent should emit ShowToast side effect`() = runTest {
        // Given
        coEvery { updateUserUseCase(any(), any()) } returns Result.success(Unit)

        // When
        viewModel.sideEffect.test {
            viewModel.processIntent(UserProfileContract.Intent.UpdateName("New Name"))

            // Then
            val effect = awaitItem()
            assertThat(effect).isInstanceOf(UserProfileContract.SideEffect.ShowToast::class.java)
        }
    }

    companion object {
        private val testUser = User(id = "123", name = "Test User")
    }
}
```

## build.gradle.kts Template

```kotlin
// feature/userprofile/build.gradle.kts
plugins {
    id("nhnad.android.feature")
}

android {
    namespace = "com.example.feature.userprofile"
}

dependencies {
    implementation(project(":core:ui"))
    implementation(project(":core:common"))
    implementation(project(":domain"))
    implementation(project(":designsystem"))

    testImplementation(project(":core:testing"))
}
```

## Interactive Mode

```bash
/generate-feature
```

```
🚀 Feature Generator

Feature Name: UserProfile
Package: com.example.feature.userprofile

Select Architecture Pattern:
  ● MVI (Model-View-Intent)
  ○ MVVM (Model-View-ViewModel)

Include Screens:
  [x] Main Screen
  [ ] List Screen
  [x] Detail Screen
  [ ] Create/Edit Screen

Generate Tests:
  [x] ViewModel Unit Tests
  [x] UI Tests
  [ ] Screenshot Tests

Generating files...
✅ UserProfileContract.kt
✅ UserProfileViewModel.kt
✅ UserProfileRoute.kt
✅ UserProfileScreen.kt
✅ UserProfileNavigation.kt
✅ UserProfileViewModelTest.kt
✅ UserProfileScreenTest.kt
✅ build.gradle.kts

📁 Created 8 files in feature/userprofile/

Next steps:
1. Add module to settings.gradle.kts
2. Implement UseCase dependencies
3. Add navigation route in NavHost
```
