# Notifications Feature

> **LLM context doc** — read this before changing anything under `lib/features/notifications/`.

## Purpose

App-level notification toggles, OS permission status, and **local scheduling** for recitation, mala, and timer daily repeats. Routine reminders gate server-side plan/series push.

## User-facing functionality

- Master + per-type toggles: routine, recitation, practice, timer
- OS permission / exact-alarm / battery optimization status display
- Local scheduling for recitation, mala (accumulator), timer repeats
- Routine reminder scheduling (hydrated from practice routine)
- Deep-link payload handling (`notification_nav`)
- Settings screen from More/Settings

## Architecture

```
notifications/
├── application/    notification_sync_engine, notification_sync_bootstrap
├── data/           channels, local datasource, models, repository, services
├── domain/         entities, repository, usecases
├── presentation/   notification_provider, settings screen
└── notifications.dart
```

## Key files

| Area | Files |
|------|-------|
| Sync engine | `application/notification_sync_engine.dart` |
| Bootstrap | `application/notification_sync_bootstrap.dart` |
| Toggles | `presentation/providers/notification_provider.dart` |
| Local OS | `data/services/notification_service.dart` |
| Routine scheduling | `data/services/routine_notification_service.dart` |
| Settings UI | `presentation/notification_settings_screen.dart` |
| Barrel | `notifications.dart` |

## State management

- `notificationProvider` — `NotificationNotifier` for app toggles + OS status refresh on resume
- `notificationSyncBootstrapProvider` — waits for auth before routine hydration
- `notificationSyncEngineProvider` — single reconciliation point

## Data sources

- **flutter_local_notifications** — schedule/cancel
- **SharedPreferences** — app-level toggle flags
- **Hive (via practice)** — routine time blocks
- **FCM (push_notifications)** — plan/series only (not scheduled locally here)

## Two-layer toggles

1. **App flags** (SharedPreferences) — user intent
2. **OS permissions** — read-only in UI, prompt to open settings

## Cross-feature dependencies

- **practice** — `RoutineData`, `routineProvider`, routine API
- **auth** — login/logout triggers sync; must settle before hydration
- **push_notifications** — listens to `notificationProvider` for preference sync

---

## How to make changes (LLM playbook)

### Principles

1. **`NotificationSyncEngine` is the single reconciliation point** — use `SyncTrigger` enum for logging.
2. **Plan/series reminders are server push** — do not schedule them locally.
3. **Bootstrap must wait for auth** — avoid cold-start 403 on routine fetch.
4. App flags vs OS permissions are separate — never write OS state from app toggles.

### Do

- Add new local-only notification types through sync engine + ID scheme
- Reconcile on login/logout via bootstrap
- Export shared services through barrel when practice needs them

### Don't

- Don't schedule FCM-delivered types locally (plan/series)
- Don't hydrate routine before auth settles
- Don't bypass sync engine with ad-hoc `NotificationService` calls from random features

### Common tasks

| Task | Where to start |
|------|----------------|
| New toggle | `NotificationSettings` entity, notifier, settings screen, sync engine |
| Routine time change | practice `routineProvider` → sync engine trigger |
| Deep link on tap | `notification_nav` model, push feature navigator |
| Permission UX | `NotificationNotifier.refreshOsStatus` |

### Testing

- Test auth-gated bootstrap (no fetch while loading)
- Test toggle off cancels scheduled locals
- Test sync engine idempotency
