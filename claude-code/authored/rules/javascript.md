---
paths:
  - "**/*.js"
  - "**/*.ts"
  - "**/*.jsx"
  - "**/*.tsx"
  - "**/package.json"
  - "**/tsconfig.json"
---

# JavaScript / TypeScript Standards

## Toolchain
- **TypeScript** preferred over plain JS for anything non-trivial
- **ESLint** — linting; follow project config, don't suppress without justification
- **Prettier** — formatting; use project defaults, don't override
- Use the project's existing test framework (Jest, Vitest, etc.)

## Code Style
- Strict TypeScript: use `unknown` over `any`; no `any` without explicit justification
- Prefer `type` over `interface` for type definitions
- Prefer `const` over `let`; avoid `var`
- Arrow functions for callbacks; named functions for top-level declarations
- Guard clauses and early returns over nested conditionals
- No abbreviations — full, meaningful names
- Numeric separators for large numbers: `1_000_000` not `1000000`
- Never disable lint rules inline without a comment explaining why
- Always use strict equality (`===` / `!==`); never `==` or `!=`

## Naming
- Components: PascalCase
- Hooks: camelCase with `use` prefix (`useUserProfile`)
- Utilities/helpers: camelCase
- Types: PascalCase, no `I` prefix (`UserProfile` not `IUserProfile`)
- Test files: co-located with source (`Foo.tsx` → `Foo.test.tsx`)

## Testing
- TDD: write test first, minimal code to pass, refactor
- Test behavior, not implementation details
- Co-locate test files next to source — not in a separate `__tests__/` tree
- Mock at the boundary (HTTP, DB) — not internal functions

## Package Management
- Commit lockfile (package-lock.json or yarn.lock or pnpm-lock.yaml)
- Audit dependencies: `npm audit` before shipping
- Prefer well-maintained packages; check bundle size impact for frontend

## Before Committing
1. `npm run lint` (or `eslint .`) — fix all issues
2. `npm run format` (or `prettier --check .`) — formatting
3. `npm test` — all tests pass
4. `npm run typecheck` (or `tsc --noEmit`) — if TypeScript project
