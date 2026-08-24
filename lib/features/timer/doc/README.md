# Timer Feature

> **LLM context doc** — read this before changing anything under `lib/features/timer/`.

## Purpose

Preset meditation timers with countdown, pause/resume, lock-screen display, session reporting, and offline stop queue.

## User-facing functionality

- Browse preset timers (authenticated)
- 5-second countdown → running phase
- Pause/resume with **wall-clock** remaining time (survives backgrounding)
- Completion bell (in-app + scheduled local notification)
- Android ongoing lock-screen notification
- iOS Live Activity
- Report elapsed duration to backend
- Offline stop queue flushed on reconnect
- Bookmarks on preset screen (via practice)

## Architecture

```
timer/
├── data/       remote + local datasources, repository, session notifier, live activity
├── domain/     preset_timer entity, repository interface, usecases
└── presentation/  providers, screens, sound player, widgets
```

**No barrel file.**

## Key files

| Area | Files |
|------|-------|
| Presets | `presentation/screens/preset_timers_screen.dart` |
| Active session | `presentation/screens/active_timer_screen.dart` |
| Providers | `presentation/providers/timers_providers.dart` |
| Offline queue | `data/datasource/timers_local_datasource.dart` |
| Android notif | `data/services/timer_session_notifier.dart` |
| iOS | `data/services/timer_live_activity.dart` |
| Bootstrap | `timerSyncBootstrapProvider` |

## State management

- `presetTimersFutureProvider` — **StreamProvider**, cache-first
- **Session state is local to `ActiveTimerScreen`** — not Riverpod (`_endsAt` wall-clock)
- `timerSyncBootstrapProvider` — flush pending stops on reconnect
- Auth gate: guests get `AuthenticationFailure`

## Data sources

- **Remote:** `GET /timers`, `POST /timers/user/timer_stop`
- **Hive:** cached presets per user, pending stop queue
- **PreferencesService:** user ID namespacing
- **notifications** channels for session + completion bell

## Cross-feature dependencies

- **auth** — preset list and stop reporting
- **notifications** — channels, ID scheme, completion scheduling
- **practice** — bookmarks on preset screen
- **push_notifications** — timer deep link → `/home/timers`

## Notable patterns

- **Wall-clock timing:** `_endsAt` is source of truth
- **Best-effort notifications** — never crash session on notif failure
- **Offline-first writes** for stop reports
- Completion bell scheduled only on backgrounding (avoid double-ring with in-app sound)

---

## How to make changes (LLM playbook)

### Principles

1. **Don't move active session to Riverpod** without strong reason — wall-clock local state is intentional.
2. **Enqueue failed stops locally** — flush via bootstrap on reconnect.
3. **Per-user Hive namespacing** — use same user ID pattern as mala.
4. Notification failures must not abort timer session.

### Do

- Cache presets cache-first (emit cached, refresh background)
- Use `StopUserTimerUseCase` for all session reporting
- Platform-specific lock screen: Android notifier vs iOS Live Activity
- Gate preset list for auth loading/guest states

### Don't

- Don't use periodic Timer for remaining time without wall-clock anchor
- Don't schedule completion bell in foreground if in-app sound plays (double-ring)
- Don't skip offline queue on API failure

### Common tasks

| Task | Where to start |
|------|----------------|
| Preset UI | `preset_timer_card.dart`, presets screen |
| Session UX | `active_timer_screen.dart`, `timer_progress_ring.dart` |
| Offline sync | local datasource + `timerSyncBootstrapProvider` |
| Lock screen | `timer_session_notifier.dart` / `timer_live_activity.dart` |

### Testing

- Test pause/resume after backgrounding
- Test pending stop flush on reconnect
- Test guest cannot load presets
