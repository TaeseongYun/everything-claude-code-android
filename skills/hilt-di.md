# Hilt Dependency Injection

Android를 위한 Hilt 의존성 주입 가이드.

## Setup

### Dependencies

```kotlin
// build.gradle.kts (project)
plugins {
    id("com.google.dagger.hilt.android") version "2.48" apply false
    id("com.google.devtools.ksp") version "1.9.22-1.0.17" apply false
}

// build.gradle.kts (app)
plugins {
    id("com.google.dagger.hilt.android")
    id("com.google.devtools.ksp")
}

dependencies {
    implementation("com.google.dagger:hilt-android:2.48")
    ksp("com.google.dagger:hilt-compiler:2.48")

    // ViewModel integration
    implementation("androidx.hilt:hilt-navigation-compose:1.1.0")
}
```

### Application Setup

```kotlin
@HiltAndroidApp
class MyApplication : Application()
```

```xml
<!-- AndroidManifest.xml -->
<application
    android:name=".MyApplication"
    ... >
```

## Module Structure

### SingletonComponent (Application Scope)

```kotlin
@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

    @Provides
    @Singleton
    fun provideOkHttpClient(): OkHttpClient {
        return OkHttpClient.Builder()
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .build()
    }

    @Provides
    @Singleton
    fun provideRetrofit(okHttpClient: OkHttpClient): Retrofit {
        return Retrofit.Builder()
            .baseUrl(BuildConfig.API_BASE_URL)
            .client(okHttpClient)
            .addConverterFactory(Json.asConverterFactory("application/json".toMediaType()))
            .build()
    }

    @Provides
    @Singleton
    fun provideUserApi(retrofit: Retrofit): UserApi {
        return retrofit.create(UserApi::class.java)
    }
}
```

### Database Module

```kotlin
@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideAppDatabase(@ApplicationContext context: Context): AppDatabase {
        return Room.databaseBuilder(
            context,
            AppDatabase::class.java,
            "app_database"
        ).build()
    }

    @Provides
    fun provideUserDao(database: AppDatabase): UserDao {
        return database.userDao()
    }
}
```

### Repository Module

```kotlin
@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {

    @Binds
    @Singleton
    abstract fun bindUserRepository(
        impl: UserRepositoryImpl
    ): UserRepository

    @Binds
    @Singleton
    abstract fun bindAuthRepository(
        impl: AuthRepositoryImpl
    ): AuthRepository
}
```

### ViewModelComponent (ViewModel Scope)

```kotlin
@Module
@InstallIn(ViewModelComponent::class)
object UseCaseModule {

    @Provides
    @ViewModelScoped
    fun provideGetUserUseCase(
        userRepository: UserRepository
    ): GetUserUseCase {
        return GetUserUseCase(userRepository)
    }

    @Provides
    @ViewModelScoped
    fun provideUpdateUserUseCase(
        userRepository: UserRepository,
        validator: UserValidator
    ): UpdateUserUseCase {
        return UpdateUserUseCase(userRepository, validator)
    }
}
```

## Constructor Injection

### Repository

```kotlin
class UserRepositoryImpl @Inject constructor(
    private val userApi: UserApi,
    private val userDao: UserDao,
    @IoDispatcher private val dispatcher: CoroutineDispatcher
) : UserRepository {
    // ...
}
```

### ViewModel

```kotlin
@HiltViewModel
class UserViewModel @Inject constructor(
    private val getUserUseCase: GetUserUseCase,
    private val updateUserUseCase: UpdateUserUseCase,
    savedStateHandle: SavedStateHandle
) : ViewModel() {

    private val userId: String = checkNotNull(savedStateHandle["userId"])

    // ...
}
```

### Use Case

```kotlin
class GetUserUseCase @Inject constructor(
    private val userRepository: UserRepository
) {
    suspend operator fun invoke(userId: String): Result<User> {
        return runCatching {
            userRepository.getUser(userId)
        }
    }
}
```

## Qualifiers

### Dispatcher Qualifiers

```kotlin
@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class IoDispatcher

@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class DefaultDispatcher

@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class MainDispatcher

@Module
@InstallIn(SingletonComponent::class)
object DispatcherModule {

    @Provides
    @IoDispatcher
    fun provideIoDispatcher(): CoroutineDispatcher = Dispatchers.IO

    @Provides
    @DefaultDispatcher
    fun provideDefaultDispatcher(): CoroutineDispatcher = Dispatchers.Default

    @Provides
    @MainDispatcher
    fun provideMainDispatcher(): CoroutineDispatcher = Dispatchers.Main
}
```

### Usage

```kotlin
class UserRepositoryImpl @Inject constructor(
    private val userApi: UserApi,
    @IoDispatcher private val ioDispatcher: CoroutineDispatcher
) : UserRepository {

    override suspend fun fetchUser(id: String): User = withContext(ioDispatcher) {
        userApi.getUser(id).toDomain()
    }
}
```

## Activity & Fragment

### Activity

```kotlin
@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    // Field injection (가능하면 constructor injection 선호)
    @Inject
    lateinit var analyticsTracker: AnalyticsTracker

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            AppTheme {
                MainNavHost()
            }
        }
    }
}
```

### Fragment (필요시)

```kotlin
@AndroidEntryPoint
class UserFragment : Fragment() {

    private val viewModel: UserViewModel by viewModels()

    @Inject
    lateinit var imageLoader: ImageLoader
}
```

## Compose Integration

### hiltViewModel()

```kotlin
@Composable
fun UserRoute(
    viewModel: UserViewModel = hiltViewModel(),
    onNavigateBack: () -> Unit
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    UserScreen(
        uiState = uiState,
        onAction = viewModel::onAction,
        onNavigateBack = onNavigateBack
    )
}
```

### Navigation with Arguments

```kotlin
// NavGraph
composable(
    route = "user/{userId}",
    arguments = listOf(
        navArgument("userId") { type = NavType.StringType }
    )
) {
    UserRoute(onNavigateBack = { navController.popBackStack() })
}

// ViewModel에서 SavedStateHandle로 받음
@HiltViewModel
class UserViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle
) : ViewModel() {
    private val userId: String = checkNotNull(savedStateHandle["userId"])
}
```

## Testing with Hilt

### Test Setup

```kotlin
@HiltAndroidTest
class UserViewModelTest {

    @get:Rule
    val hiltRule = HiltAndroidRule(this)

    @Inject
    lateinit var userRepository: FakeUserRepository

    @Before
    fun setup() {
        hiltRule.inject()
    }

    @Test
    fun testUserLoading() {
        // Test with injected fake
    }
}
```

### Test Module

```kotlin
@Module
@TestInstallIn(
    components = [SingletonComponent::class],
    replaces = [RepositoryModule::class]
)
abstract class TestRepositoryModule {

    @Binds
    @Singleton
    abstract fun bindUserRepository(
        fake: FakeUserRepository
    ): UserRepository
}

@Singleton
class FakeUserRepository @Inject constructor() : UserRepository {
    // Fake implementation
}
```

## Best Practices

### 1. Constructor Injection 선호

```kotlin
// ✅ Good
class UserRepository @Inject constructor(
    private val api: UserApi
)

// ❌ Avoid field injection when possible
class UserRepository {
    @Inject lateinit var api: UserApi
}
```

### 2. Interface에 Bind

```kotlin
// ✅ Good - Interface 사용
@Binds
abstract fun bindRepository(impl: UserRepositoryImpl): UserRepository

// 사용처에서는 interface 타입으로 주입
class UseCase @Inject constructor(
    private val repository: UserRepository // Interface
)
```

### 3. Scope 적절히 사용

```kotlin
// Singleton: 앱 전체에서 하나의 인스턴스
@Singleton

// ViewModelScoped: ViewModel 수명 동안 유지
@ViewModelScoped

// ActivityScoped: Activity 수명 동안 유지
@ActivityScoped

// No scope: 매번 새 인스턴스 생성
```

### 4. Module 분리

```kotlin
// 기능별로 Module 분리
@Module
@InstallIn(SingletonComponent::class)
object NetworkModule { ... }

@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule { ... }

@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule { ... }

@Module
@InstallIn(ViewModelComponent::class)
object UseCaseModule { ... }
```

## Common Issues

### Unresolved Reference

```kotlin
// ❌ Error: Hilt_MyApplication not found
// Solution: Clean and rebuild
./gradlew clean assembleDebug
```

### Missing @AndroidEntryPoint

```kotlin
// ❌ Error: injection failed
// Solution: Add annotation to Activity/Fragment
@AndroidEntryPoint
class MainActivity : ComponentActivity()
```

### Circular Dependency

```kotlin
// ❌ Error: Circular dependency between A and B
// Solution: Use Lazy or Provider
class ServiceA @Inject constructor(
    private val serviceB: Lazy<ServiceB>
)
```
