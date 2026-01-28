# /plan - Android Project Planning

Plan and structure Android development tasks with comprehensive breakdown.

## Usage

```
/plan [feature description]
```

## Examples

```
/plan Add user authentication with Kakao login
/plan Implement pull-to-refresh for home screen
/plan Create payment settlement feature
```

## What This Command Does

1. **Analyzes Requirements**
   - Identifies affected modules
   - Lists required dependencies
   - Determines API requirements

2. **Creates Task Breakdown**
   - Data layer tasks (models, entities, repositories)
   - Domain layer tasks (use cases)
   - Presentation layer tasks (ViewModel, UI)
   - Navigation setup
   - Testing tasks

3. **Identifies Dependencies**
   - Module dependencies
   - External library needs
   - API contracts

4. **Generates Implementation Plan**
   - Ordered task list
   - File locations
   - Acceptance criteria

## Output Format

```markdown
# Feature: [Feature Name]

## Overview
[Brief description]

## Affected Modules
- :feature:xxx
- :core:xxx
- :data:xxx

## Task Breakdown

### Phase 1: Data Layer
- [ ] Create data models
- [ ] Add Room entities
- [ ] Implement repository

### Phase 2: Domain Layer
- [ ] Create use cases
- [ ] Define business logic

### Phase 3: Presentation Layer
- [ ] Design UI state (State/Intent/SideEffect)
- [ ] Implement ViewModel
- [ ] Create Compose screens

### Phase 4: Integration
- [ ] Add navigation
- [ ] Configure Hilt modules
- [ ] Update feature flags

### Phase 5: Testing
- [ ] Unit tests
- [ ] UI tests

## Dependencies
- [List of dependencies]

## Notes
- [Important considerations]
```

## Tips

- Be specific about the feature requirements
- Mention any constraints or preferences
- Include target modules if known
