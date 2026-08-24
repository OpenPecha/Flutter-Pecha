# Home Feature

> **LLM context doc** — read this before changing anything under `lib/features/home/`.

## Purpose

Home dashboard and **main navigation shell** (bottom nav: Home, Practice, Connect, Me). Aggregates verse of the day, streak, series, events, calendar banner, and shortcuts.

## User-facing functionality

- Home dashboard cards: verse, practice stats/streak, featured series/plans, today's events, group events preview, calendar banner, shortcuts
- **MainNavigationScreen** — bottom nav host + `MainTab` enum
- Series browse, detail, enrollment
- Plan list by tag / featured day
- Group events aggregated view
- Notification permission prompt on first home load
- Tag search overlay, share verse prompts

## Architecture

```
home/
├── home.dart           # partial barrel
├── data/               many datasources, models, repositories, week_plan_*.dart
├── domain/             entities, multiple repository interfaces in one file, usecases
└── presentation/       providers (one per concern), screens, widgets, constants
```

## Key files

| Area | Files |
|------|-------|
| Nav shell | `presentation/screens/main_navigation_screen.dart`, `MainTab`, `mainNavigationIndexProvider` |
| Dashboard | `presentation/screens/home_screen.dart` |
| DI hub | `presentation/providers/use_case_providers.dart` |
| Local cache | `data/datasource/home_local_datasource.dart` |
| Series | `series_repository.dart`, `series_enrollment_provider` |
| Barrel | `home.dart` (partial — many symbols need direct import) |

## State management

- `StreamProvider` / `FutureProvider` for reactive data
- `StateNotifierProvider`: `seriesEnrollmentProvider`
- `StateProvider`: `mainNavigationIndexProvider`, `pendingOnboardingPlanProvider`
- Repositories expose `get*` and `watch*` backed by local cache

## Data sources

- **Remote:** featured day, tags, series, verse, events, routine info, streak
- **Local:** `HomeLocalDatasource` — offline/stream replay
- **Bundled:** `week_plan_en.dart` / `_bo.dart` / `_zh.dart` for action-of-the-day

## Cross-feature dependencies

- **auth**, **calendar** (`todayCalendarDayProvider`), **group_profile**, **plans**, **notifications**, **connect**, **practice**, **more** (nav tabs)

## Notable patterns

- Multiple repository interfaces in one `home_repository.dart`
- Stream + local cache: remote writes to local, UI watches streams
- Skeleton widgets paired with async cards
- Notification permission: capture `ProviderContainer` before await

---

## How to make changes (LLM playbook)

### Principles

1. **Main nav lives here** — tab changes affect the whole app.
2. **Prefer stream + cache pattern** for new home feed data.
3. **Check barrel exports** — many providers aren't in `home.dart`; import directly when needed.
4. Use `home_screen_constants.dart` for layout magic numbers.

### Do

- Add new dashboard sections as widget + provider + repository triplet
- Pair async cards with skeleton widgets
- Invalidate related providers on enrollment changes
- Use existing share sheet patterns for new shareable content

### Don't

- Don't block home render on optional cards — use AsyncValue / skeletons
- Don't move main navigation to another feature without team decision
- Don't implement placeholder use cases in `home_usecases.dart` (DailyPrayer, etc.) without backend

### Common tasks

| Task | Where to start |
|------|----------------|
| New home card | widget + provider + datasource/repo |
| Nav tab change | `main_navigation_screen.dart`, `MainTab`, routes |
| Series enrollment | `series_enrollment_provider`, group_profile helpers |
| Featured content | featured day / tags providers |

### Testing

- Test offline stream replay from local datasource
- Test guest vs authenticated card visibility
- Test nav index persistence
