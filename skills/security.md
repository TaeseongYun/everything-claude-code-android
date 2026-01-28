# Android Security Best Practices

Android 앱 보안을 위한 가이드라인.

## Data Storage Security

### EncryptedSharedPreferences

```kotlin
// ✅ 민감한 데이터는 암호화된 SharedPreferences 사용
class SecurePreferences @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val masterKey = MasterKey.Builder(context)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build()

    private val prefs = EncryptedSharedPreferences.create(
        context,
        "secure_prefs",
        masterKey,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )

    fun saveAuthToken(token: String) {
        prefs.edit().putString(KEY_AUTH_TOKEN, token).apply()
    }

    fun getAuthToken(): String? {
        return prefs.getString(KEY_AUTH_TOKEN, null)
    }

    companion object {
        private const val KEY_AUTH_TOKEN = "auth_token"
    }
}
```

### Database Encryption (SQLCipher)

```kotlin
// build.gradle.kts
implementation("net.zetetic:android-database-sqlcipher:4.5.4")
implementation("androidx.sqlite:sqlite-ktx:2.4.0")

// Database setup
@Database(entities = [UserEntity::class], version = 1)
abstract class AppDatabase : RoomDatabase() {
    companion object {
        fun create(context: Context, passphrase: ByteArray): AppDatabase {
            val factory = SupportFactory(passphrase)
            return Room.databaseBuilder(
                context,
                AppDatabase::class.java,
                "app_database"
            )
                .openHelperFactory(factory)
                .build()
        }
    }
}
```

## Network Security

### Network Security Config

```xml
<!-- res/xml/network_security_config.xml -->
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <!-- 기본: cleartext 비허용 -->
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>

    <!-- 특정 도메인 설정 -->
    <domain-config cleartextTrafficPermitted="false">
        <domain includeSubdomains="true">api.example.com</domain>
        <pin-set expiration="2025-12-31">
            <pin digest="SHA-256">AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=</pin>
            <pin digest="SHA-256">BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=</pin>
        </pin-set>
    </domain-config>

    <!-- Debug용 설정 (release에서는 제외) -->
    <debug-overrides>
        <trust-anchors>
            <certificates src="user" />
        </trust-anchors>
    </debug-overrides>
</network-security-config>
```

```xml
<!-- AndroidManifest.xml -->
<application
    android:networkSecurityConfig="@xml/network_security_config"
    ... >
```

### Certificate Pinning (OkHttp)

```kotlin
@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

    @Provides
    @Singleton
    fun provideOkHttpClient(): OkHttpClient {
        val certificatePinner = CertificatePinner.Builder()
            .add(
                "api.example.com",
                "sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
            )
            .add(
                "api.example.com",
                "sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB="
            )
            .build()

        return OkHttpClient.Builder()
            .certificatePinner(certificatePinner)
            .connectTimeout(30, TimeUnit.SECONDS)
            .build()
    }
}
```

## Authentication Security

### Biometric Authentication

```kotlin
class BiometricAuthManager @Inject constructor(
    private val activity: FragmentActivity
) {
    private val executor = ContextCompat.getMainExecutor(activity)

    fun authenticate(
        onSuccess: () -> Unit,
        onError: (String) -> Unit
    ) {
        val biometricPrompt = BiometricPrompt(
            activity,
            executor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(result: AuthenticationResult) {
                    onSuccess()
                }

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    onError(errString.toString())
                }

                override fun onAuthenticationFailed() {
                    // 인증 실패 (다시 시도 가능)
                }
            }
        )

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("인증 필요")
            .setSubtitle("생체 인증으로 로그인하세요")
            .setNegativeButtonText("취소")
            .setAllowedAuthenticators(
                BiometricManager.Authenticators.BIOMETRIC_STRONG
            )
            .build()

        biometricPrompt.authenticate(promptInfo)
    }

    fun canAuthenticate(): Boolean {
        val biometricManager = BiometricManager.from(activity)
        return biometricManager.canAuthenticate(
            BiometricManager.Authenticators.BIOMETRIC_STRONG
        ) == BiometricManager.BIOMETRIC_SUCCESS
    }
}
```

### Secure Token Storage

```kotlin
class TokenManager @Inject constructor(
    private val securePreferences: SecurePreferences,
    private val keyStore: KeyStoreManager
) {
    suspend fun saveToken(token: AuthToken) {
        // 토큰 암호화 저장
        val encryptedToken = keyStore.encrypt(token.accessToken)
        securePreferences.saveEncryptedToken(encryptedToken)

        // 만료 시간 저장
        securePreferences.saveTokenExpiry(token.expiresAt)
    }

    suspend fun getToken(): AuthToken? {
        val encryptedToken = securePreferences.getEncryptedToken() ?: return null
        val decryptedToken = keyStore.decrypt(encryptedToken)

        return AuthToken(
            accessToken = decryptedToken,
            expiresAt = securePreferences.getTokenExpiry()
        )
    }

    fun clearToken() {
        securePreferences.clearAll()
    }
}
```

## Input Validation

### SQL Injection Prevention

```kotlin
// ❌ Bad - SQL injection vulnerable
@Query("SELECT * FROM users WHERE name = " + name)
fun findUser(name: String): User

// ✅ Good - Parameterized query
@Query("SELECT * FROM users WHERE name = :name")
fun findUser(name: String): User

// ✅ Good - RawQuery with safe binding
@RawQuery
fun searchUsers(query: SupportSQLiteQuery): List<User>

fun searchUsersSafely(searchTerm: String): List<User> {
    val query = SimpleSQLiteQuery(
        "SELECT * FROM users WHERE name LIKE ?",
        arrayOf("%$searchTerm%")
    )
    return searchUsers(query)
}
```

### Intent Validation

```kotlin
class DeepLinkHandler @Inject constructor() {

    private val allowedHosts = setOf(
        "example.com",
        "www.example.com"
    )

    fun handleDeepLink(intent: Intent): DeepLinkResult {
        val uri = intent.data ?: return DeepLinkResult.Invalid

        // Host 검증
        if (uri.host !in allowedHosts) {
            return DeepLinkResult.Invalid
        }

        // Scheme 검증
        if (uri.scheme !in setOf("https", "app")) {
            return DeepLinkResult.Invalid
        }

        // Path 파싱 및 검증
        return when {
            uri.path?.startsWith("/user/") == true -> {
                val userId = uri.lastPathSegment
                if (userId?.matches(Regex("^[a-zA-Z0-9]+$")) == true) {
                    DeepLinkResult.UserProfile(userId)
                } else {
                    DeepLinkResult.Invalid
                }
            }
            else -> DeepLinkResult.Home
        }
    }

    sealed interface DeepLinkResult {
        data object Invalid : DeepLinkResult
        data object Home : DeepLinkResult
        data class UserProfile(val userId: String) : DeepLinkResult
    }
}
```

## Logging Security

### Secure Logging

```kotlin
// ❌ Bad - 민감한 정보 로깅
Log.d("Auth", "User password: $password")
Log.d("API", "Token: $authToken")
Log.d("Payment", "Card number: $cardNumber")

// ✅ Good - 민감한 정보 제외
Log.d("Auth", "User authentication attempted for user: ${user.id}")
Log.d("API", "Request to: ${request.url}")
Log.d("Payment", "Payment initiated for order: ${order.id}")

// ✅ Best - Timber with release tree
class ReleaseTree : Timber.Tree() {
    override fun log(priority: Int, tag: String?, message: String, t: Throwable?) {
        // Release에서는 WARN 이상만 Crashlytics로 전송
        if (priority >= Log.WARN) {
            FirebaseCrashlytics.getInstance().log("$tag: $message")
            t?.let { FirebaseCrashlytics.getInstance().recordException(it) }
        }
        // DEBUG, VERBOSE, INFO는 무시
    }
}

// Application에서 설정
class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        if (BuildConfig.DEBUG) {
            Timber.plant(Timber.DebugTree())
        } else {
            Timber.plant(ReleaseTree())
        }
    }
}
```

## ProGuard/R8 Security

```proguard
# proguard-rules.pro

# 난독화 활성화
-optimizationpasses 5
-dontusemixedcaseclassnames
-verbose

# 보안 관련 클래스 보호
-keep class com.example.security.** { *; }
-keep class com.example.crypto.** { *; }

# 민감한 모델 클래스
-keepclassmembers class com.example.model.AuthToken {
    <fields>;
}

# Release에서 로그 제거
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# Retrofit 인터페이스 유지
-keep,allowobfuscation interface * {
    @retrofit2.http.* <methods>;
}

# Serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt

-keepclassmembers @kotlinx.serialization.Serializable class ** {
    *** Companion;
    kotlinx.serialization.KSerializer serializer(...);
}
```

## Component Security

### Exported Components

```xml
<!-- AndroidManifest.xml -->

<!-- ❌ Bad - 보호되지 않은 exported activity -->
<activity
    android:name=".PaymentActivity"
    android:exported="true" />

<!-- ✅ Good - 권한으로 보호 -->
<activity
    android:name=".PaymentActivity"
    android:exported="true"
    android:permission="com.example.permission.PAYMENT" />

<!-- ✅ Good - 명시적으로 내부용 표시 -->
<activity
    android:name=".InternalActivity"
    android:exported="false" />

<!-- Broadcast Receiver 보안 -->
<receiver
    android:name=".SecureReceiver"
    android:exported="true"
    android:permission="com.example.permission.SECURE_BROADCAST">
    <intent-filter>
        <action android:name="com.example.SECURE_ACTION" />
    </intent-filter>
</receiver>
```

## Security Checklist

- [ ] EncryptedSharedPreferences 사용
- [ ] Network Security Config 설정
- [ ] Certificate Pinning 구현
- [ ] 민감한 정보 로그 제거
- [ ] ProGuard/R8 활성화
- [ ] Exported 컴포넌트 검토
- [ ] SQL Injection 방지
- [ ] Intent 데이터 검증
- [ ] 생체 인증 구현 (필요시)
- [ ] OWASP Mobile Top 10 검토
