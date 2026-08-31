# Practice Feature

> **LLM context doc** — read this before changing anything under `lib/features/practice/`.

## Purpose

**Practice Explore tab** (main nav) — hub for plans, chants, accumulations, timers, and **daily routine** with server sync + local Hive mirror.

## User-facing functionality

- Practice Explore: sections for plans, recitations, mala, timers
- Daily routine: server-synced time blocks + Hive offline mirror + notification scheduling
- Build/edit routine with mixed session types (plan, series, recitation, mala, timer, group practice)
- Bookmarks, paginated "see all" + search screens
- Guest gating on routine editing

## Architecture

```
practice/
├── data/       datasources, models, repositories, utils
├── domain/     entities, repositories, usecases
├── presentation/  controllers, providers, screens, utils, widgets
└── practice.dart
```

## Key files

| Area | Files |
|------|-------|
| Explore tab | `presentation/screens/practice_explore_screen.dart` |
| Routine | `presentation/providers/routine_provider.dart` (`RoutineNotifier`) |
| Remote routine | `routine_api_providers.dart` |
| Session picker | `select_session_screen.dart`, `SessionSelection` model |
| Local storage | `routine_local_storage.dart` — **must override in main.dart** |
| Barrel | `practice.dart` |

## State management

- **Dual routine stack:** remote API + local Hive (`routineProvider`)
- `userRoutineProvider` — server routine
- Paginated providers for explore sections
- `BookmarkController` for imperative bookmark flows
- Sealed `PracticeItem` for plan vs series branching

## Data sources

- **Remote:** routine time blocks, practice items, bookmarks
- **Local Hive:** routine mirror for offline + notifications
- **SharedPreferences:** session/progress via practice repository

## Cross-feature dependencies

Heavy integration feature:
- **plans**, **home**, **mala**, **recitation**, **timer**, **group_profile**
- **notifications** — routine notification service, sync engine
- **reader** — recitation navigation utils
- **auth** — guest gating

## Critical setup

`routineLocalStorageProvider` **must be overridden** in root `ProviderContainer` (see provider comment + `main.dart`).

---

## How to make changes (LLM playbook)

### Principles

1. **SessionSelection aggregates picks** from multiple features — extend it when adding session types.
2. **Mirror server routine to Hive on login** — notification bootstrap depends on it.
3. **Don't break Hive override** in app entrypoint.
4. Strip `Exception:` prefix in friendly error messages (existing UI pattern).

### Do

- Add new session type: extend `SessionSelection` + picker screen + routine item display utils
- Schedule notifications via notifications sync engine after routine save
- Use sealed `PracticeItem` for type-safe branching
- Invalidate explore providers when bookmarks change

### Don't

- Don't store routine only locally without API sync path
- Don't duplicate plan/recitation/mala pickers — link to existing select screens
- Don't skip notification reconciliation after routine edits

### Common tasks

| Task | Where to start |
|------|----------------|
| New routine session type | `SessionSelection`, `routine_item_display.dart`, select screens |
| Explore section | section widget + explore provider |
| Bookmark | `bookmark_controller.dart`, bookmark repository |
| Routine sync bug | routine API providers + `RoutineNotifier` + notification bootstrap |

### Testing

- Test routine save triggers notification sync
- Test guest cannot edit routine
- Test Hive mirror matches server after login
