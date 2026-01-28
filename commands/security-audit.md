# /security-audit - Android Security Audit

Perform comprehensive security audit on Android code.

## Usage

```
/security-audit [target]
/security-audit --full    # Full project audit
/security-audit --owasp   # OWASP Mobile Top 10 focused
```

## Examples

```
/security-audit feature/auth/
/security-audit UserRepository.kt
/security-audit --full
```

## Security Categories

### 1. Data Storage
- SharedPreferences security
- Database encryption
- File storage permissions
- Sensitive data in logs

### 2. Network Security
- HTTPS enforcement
- Certificate pinning
- API key exposure
- Request/response logging

### 3. Authentication
- Token storage
- Biometric implementation
- Session management
- Password handling

### 4. Input Validation
- SQL injection
- Path traversal
- Intent injection
- WebView vulnerabilities

### 5. Code Security
- ProGuard/R8 configuration
- Debug code in release
- Exported components
- Content provider security

## Audit Checklist

```markdown
## Data Storage
- [ ] EncryptedSharedPreferences for sensitive data
- [ ] SQLCipher for database encryption
- [ ] No sensitive data in logs
- [ ] Proper file permissions

## Network
- [ ] HTTPS only (network_security_config.xml)
- [ ] Certificate pinning implemented
- [ ] No hardcoded API keys
- [ ] Sensitive data not logged

## Authentication
- [ ] Secure token storage
- [ ] Biometric with CryptoObject
- [ ] Session timeout implemented
- [ ] No password in plain text

## Components
- [ ] android:exported properly set
- [ ] Intent filters validated
- [ ] Content providers protected
- [ ] Broadcast receivers secured

## Build
- [ ] ProGuard/R8 enabled for release
- [ ] Debug code removed
- [ ] Signing keys secured
- [ ] Version info not exposed
```

## Output Format

```markdown
## Security Audit Report

### Executive Summary
- Critical: X issues
- High: X issues
- Medium: X issues
- Low: X issues

### Critical Vulnerabilities 🔴

#### [VULN-001] Sensitive Data in Logs
- **Location**: `UserRepository.kt:45`
- **Description**: Auth token logged in debug output
- **Impact**: Token exposure in logcat
- **Remediation**:
```kotlin
// Remove or use Timber with release tree
Timber.d("User authenticated") // Don't log token
```

### High Risk ⚠️
...

### OWASP Mobile Top 10 Compliance
| Category | Status |
|----------|--------|
| M1: Improper Platform Usage | ⚠️ |
| M2: Insecure Data Storage | ✅ |
| M3: Insecure Communication | ✅ |
| ... | ... |

### Recommendations
1. Implement EncryptedSharedPreferences
2. Add certificate pinning
3. Review exported components
```

## Quick Fixes

### Encrypted Preferences
```kotlin
val masterKey = MasterKey.Builder(context)
    .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
    .build()

val prefs = EncryptedSharedPreferences.create(
    context, "secure_prefs", masterKey,
    PrefKeyEncryptionScheme.AES256_SIV,
    PrefValueEncryptionScheme.AES256_GCM
)
```

### Network Security Config
```xml
<network-security-config>
    <domain-config cleartextTrafficPermitted="false">
        <domain includeSubdomains="true">api.example.com</domain>
    </domain-config>
</network-security-config>
```

## Tips

- Run audit before releases
- Focus on authentication and data storage
- Check third-party library vulnerabilities
- Review ProGuard rules for sensitive classes
