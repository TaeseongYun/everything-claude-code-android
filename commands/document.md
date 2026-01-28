# /document - Generate Documentation

Generate comprehensive documentation for Android code.

## Usage

```
/document [target] [doc type]
```

## Examples

```
/document UserRepository kdoc
/document feature/home readme
/document HomeViewModel api
/document --module :feature:auth
```

## Documentation Types

### kdoc
Generate KDoc comments for classes and functions.

```
/document UserRepository kdoc
```

### readme
Generate README.md for module or feature.

```
/document feature/home readme
```

### api
Generate API documentation for public interfaces.

```
/document AuthApi api
```

### adr
Generate Architecture Decision Record.

```
/document "MVI pattern adoption" adr
```

### changelog
Generate changelog from git commits.

```
/document --changelog v1.0.0..v1.1.0
```

## KDoc Template

```kotlin
/**
 * Repository responsible for user data operations.
 *
 * Coordinates between remote API and local database to provide
 * user data with offline-first approach.
 *
 * ## Usage
 * ```kotlin
 * val user = userRepository.getUser(userId).first()
 * userRepository.refresh()
 * ```
 *
 * ## Threading
 * All suspend functions are main-safe.
 *
 * @property remoteDataSource Network data source
 * @property localDataSource Database data source
 * @property dispatcher IO dispatcher for background operations
 *
 * @see UserRemoteDataSource
 * @see UserLocalDataSource
 */
class UserRepository @Inject constructor(...)
```

## README Template

```markdown
# :feature:home

Home feature module for the main dashboard.

## Overview

This module provides:
- Home screen with item list
- Pull-to-refresh functionality
- Item search and filtering

## Architecture

```
├── ui/
│   ├── HomeRoute.kt
│   ├── HomeScreen.kt
│   └── components/
├── HomeViewModel.kt
├── HomeContract.kt
└── navigation/
```

## Dependencies

```kotlin
implementation(project(":core:ui"))
implementation(project(":domain"))
```

## Usage

```kotlin
NavHost {
    homeScreen(onNavigateToDetail = { ... })
}
```

## Testing

```bash
./gradlew :feature:home:test
```
```

## ADR Template

```markdown
# ADR-XXX: [Title]

## Status
[Proposed | Accepted | Deprecated | Superseded]

## Context
[What is the issue that we're seeing that is motivating this decision?]

## Decision
[What is the change that we're proposing and/or doing?]

## Consequences

### Positive
- [Benefit 1]
- [Benefit 2]

### Negative
- [Drawback 1]
- [Drawback 2]

## Alternatives Considered
- [Alternative 1]
- [Alternative 2]
```

## Output Options

| Option | Description |
|--------|-------------|
| `--format md` | Markdown output |
| `--format html` | HTML output |
| `--output file` | Write to file |
| `--verbose` | Include private members |

## Documentation Standards

### Class Documentation
- Purpose and responsibility
- Usage examples
- Threading behavior
- Related classes

### Function Documentation
- What it does
- Parameters with descriptions
- Return value
- Exceptions thrown
- Usage example for complex functions

### Module Documentation
- Overview and purpose
- Architecture diagram
- Dependencies
- Usage instructions
- Testing commands

## Tips

- Keep documentation close to code
- Update docs when code changes
- Use examples liberally
- Document the "why", not just the "what"
