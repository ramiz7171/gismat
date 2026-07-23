# Contributing to GISMAT

## Workflow

1. Branch from `main` (`feat/...`, `fix/...`, `docs/...`).
2. Use **Conventional Commits** (`feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`).
3. Before pushing: `dart run build_runner build --delete-conflicting-outputs && flutter analyze && flutter test` — CI enforces zero analyzer issues and green tests.
4. Open a PR; CI must pass before merge.

## Ground rules

- No hardcoded secrets — use `--dart-define` and Supabase secrets (see docs/SETUP.md).
- Tier limits, quotas and privileges are **server-side only** (`tier_limits` table + RPCs + triggers). Never gate them in the client alone.
- Never expose exact user coordinates — distances are bucketed server-side.
- Every user-facing string goes through ARB files (AZ/EN/RU/TR).
- UI must pass the accessibility checklist in the spec: ≥44pt touch targets, semantics labels, dynamic type up to 200%, gesture alternatives, reduce-motion.
- Architecture is feature-first clean architecture: presentation → domain → data; UI never touches Supabase directly.
