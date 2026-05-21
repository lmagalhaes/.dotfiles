---
paths:
  - "**/*.php"
  - "**/composer.json"
  - "**/composer.lock"
  - "**/phpunit.xml"
  - "**/phpunit.xml.dist"
---

# PHP Standards

## Coding Style
- PSR-12 coding standard — run `composer cs-fix` before committing
- Type hints required on all function parameters and return types
- No abbreviations — full, meaningful names for variables, methods, classes

## Package Management
- Composer for all dependency management
- Commit composer.lock; never commit vendor/
- Prefer well-maintained packages with PSR compliance

## Testing
- PHPUnit as the test framework
- TDD: write test first, minimal implementation to pass, refactor
- Test classes mirror source structure: src/Service/Foo.php → tests/Service/FooTest.php
- Descriptive test method names: test_it_does_x_when_y()

## Static Analysis
- Run PHPStan (or Psalm) at the project's configured level before committing
- Fix all issues at the current level; don't suppress without justification

## Architecture
- Follow SOLID principles; single responsibility per class
- Repository pattern for data access; no raw queries in controllers
- Use dependency injection; avoid static calls and global state
- Guard clauses over nested conditionals; early return on invalid state

## Before Committing
1. `composer cs-fix` — fix coding standard violations
2. `./vendor/bin/phpstan analyse` — static analysis
3. `./vendor/bin/phpunit` — all tests pass
