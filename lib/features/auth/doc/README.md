# Auth Feature

> **LLM context doc** — read this before changing anything under `lib/features/auth/`.

## Purpose

App-wide authentication and user profile. Auth0 handles credentials; backend stores user profile. Nearly every authenticated feature depends on this module.

## User-facing functionality

- Auth0 sign-in: Google, Apple, phone/SMS
- Guest mode ("continue as guest")
- Session restore on launch (offline-tolerant)
- Access token lifecycle (proactive + reactive refresh)
- Profile view/edit: name, avatar, username, bio
- Account deletion
- Onboarding completion flag (route guards)
- `LoginDrawer` — reusable login prompt app-wide

## Architecture

```
auth/
├── auth.dart, auth_service.dart
├── application/     Auth0 config
├── data/            remote datasource, user_model, repository impl
├── domain/          entities, repository interface, usecases (one file each)
└── presentation/    providers, notifiers, screens, state, widgets
```

## Key files

| Area | Files |
|------|-------|
| Session | `presentation/providers/auth_notifier.dart`, `auth_state.dart` |
| Profile | `presentation/providers/user_notifier.dart`, `user_state.dart` |
| Auth0 | `auth_service.dart` (singleton) |
| Token refresh | `domain/usecases/get_valid_access_token_usecase.dart` |
| Init | `domain/usecases/initialize_auth_usecase.dart` |
| Login UI | `presentation/widgets/login_drawer.dart`, `login_page.dart` |
| Barrel | `auth.dart` |

## State management

- **`authProvider`** — session: login, logout, guest, init, onboarding flags
- **`userProvider`** — profile CRUD, separate from auth session
- Per-use-case providers in `use_case_providers.dart`

**Critical:** auth and user state are intentionally split. Do not merge them.

## Data sources

- **Auth0 SDK** — credentials, web auth, secure storage
- **Backend API** — `GET/POST/PATCH/DELETE /users/...`
- **SharedPreferences** — guest mode, cached user ID
- **Auth0 credential manager** — token storage

## Cross-feature dependencies

- **Consumes:** onboarding (status), notifications (cleanup on logout), mala (sync reset)
- **Consumed by:** almost every feature via `authProvider` / `userProvider`

Side effects on logout: clear guest mode, reset mala sync, cancel routine notifications.

## Public API

Import from `features/auth/auth.dart`. Does **not** export `splash_screen.dart` or `user_session_bootstrap.dart`.

---

## How to make changes (LLM playbook)

### Principles

1. **Auth is app-critical** — prefer small, well-tested changes.
2. **One use case per file** in `domain/usecases/`.
3. **Auth epoch** — respect stale-async guards after logout; check existing patterns in `AuthNotifier`.
4. **Offline-first restore** — unknown onboarding status fail-opens to home; retry in background.
5. **Single-flight token refresh** — do not add parallel refresh paths.

### Do

- Add new profile fields: entity → model → datasource → repository → use case → `UserNotifier`
- Gate new protected API calls via existing token use cases / interceptors
- Use `LoginDrawer` for guest gating in other features (don't duplicate login UI)
- Persist `currentUserId` before auth state flips (race guard used by mala, timer, etc.)

### Don't

- Don't store tokens in SharedPreferences — Auth0 secure storage only
- Don't merge `AuthNotifier` and `UserNotifier`
- Don't break guest mode flows when adding auth requirements
- Don't skip logout cleanup hooks (notifications, mala sync, cache)

### Common tasks

| Task | Where to start |
|------|----------------|
| New profile field | `domain/entities/user.dart` → model → remote datasource → use case → `UserNotifier` |
| New login method | `auth_service.dart`, `login_page.dart`, `auth_notifier.dart` |
| Route guard change | `core/config/router/route_guard.dart` + `auth_state.dart` |
| Token issue | `get_valid_access_token_usecase.dart`, `auth_interceptor.dart` |

### Testing

- Test logout clears dependent feature state
- Test offline session restore
- Test guest → login transition without stale user ID races
