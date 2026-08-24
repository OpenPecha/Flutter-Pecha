# Plans Feature

> **LLM context doc** — read this before changing anything under `lib/features/plans/`.

## Purpose

Browse, enroll in, and track meditation/practice plans — daily tasks, subtasks, progress, authors, and sharing.

## User-facing functionality

- My Plans / Browse Plans tabbed hub
- Plan detail, preview, enrollment
- Day carousel, task/subtask completion
- Mixed subtask navigation (text, images → reader)
- Author profiles and listings
- Plan search, share, missed-day / on-track badges
- Audio segment playback in plan navigation

## Architecture

```
plans/
├── constants/
├── data/         datasources, models, repositories, utils
├── domain/       entities, repositories, usecases, subtask_navigation
├── exceptions/
├── presentation/ providers, screens, search, widgets, plan_info
├── services/     plan_share_service
└── plans.dart    # large barrel
```

## Key files

| Area | Files |
|------|-------|
| Hub | `presentation/screens/plans_screen.dart` |
| Detail | `presentation/plan_info.dart` |
| Navigation | `presentation/widgets/plan_navigation/plan_navigator.dart` |
| Subtask bar | `plan_navigation_bottom_bar.dart` |
| Pagination | `findPlansPaginatedProvider`, `myPlansPaginatedProvider` |
| Sync | `plansSyncBootstrapProvider` |
| Barrel | `plans.dart` |

## State management

- Paginated notifiers for browse/my lists
- `userPlansFutureProvider`, `planDaysProviders` (family)
- `planSearchProvider`, author providers
- DI in `use_case_providers.dart`

## Data sources

- **Remote:** catalogue, enrollment, progress, day content, authors
- **Local:** plans local datasource for cache/offline catalogue sync

## Cross-feature dependencies

- **auth** — guest gating on enroll
- **reader** — `NavigationContext`, `NavigationService` for SOURCE_REFERENCE subtasks
- **onboarding** — event enrollment in `PlanInfo`
- **home** — featured day overlap

## Notable patterns

- Richest feature module — subtask navigation in `PlanNavigator`
- `ResponsiveImage` on `Plan` entity
- Tibetan/English title via `getDisplayTitle(preferTibetan)`
- Domain exceptions in `exceptions/` folder

---

## How to make changes (LLM playbook)

### Principles

1. **Subtask navigation is centralized** — extend `PlanNavigator` / `subtask_navigation.dart`, don't one-off routes.
2. **Pagination providers** for lists — follow existing page/load-more pattern.
3. **Reader integration** for text subtasks — pass `NavigationContext` correctly.
4. Use plan utils for dates/sharing (`plan_date_format.dart`, `plan_share_service.dart`).

### Do

- Add new subtask types in domain + navigator switch + bottom bar
- Cache catalogue changes through local datasource + sync bootstrap
- Gate enrollment with auth + login drawer
- Add skeleton widgets for new list views

### Don't

- Don't bypass `PlanNavigator` for prev/next between subtasks
- Don't hardcode plan IDs except documented promos (onboarding)
- Don't break completion API when changing task UI

### Common tasks

| Task | Where to start |
|------|----------------|
| New subtask type | domain entity → day content model → navigator + screen |
| Progress badge | track widgets + completion status providers |
| Search | `plan_search_delegate.dart`, search provider |
| Share | `plan_share_service.dart`, `plan_day_share.dart` |

### Testing

- Test subtask navigation edge cases (first/last day)
- Test guest enroll blocked
- Test offline catalogue cache
