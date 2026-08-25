# Calendar Feature

> **LLM context doc** — read this before changing anything under `lib/features/calendar/`.

## Purpose

Tibetan lunar calendar: Gregorian grid with lunar day info, moon phases, and a "today" summary used by the home screen banner.

## User-facing functionality

- Full calendar screen with month grid (`TibetanCalendarScreen`)
- Header card for selected day (elemental year/month, lunar day)
- Month navigation with padded leading/trailing days
- Moon-phase events (new moon, first quarter, full moon)
- "Today" sync on open and when app resumes on a new calendar day
- Home banner via `todayCalendarDayProvider`

## Architecture

```
calendar/
├── data/       remote datasource, kharag engine, models, repository impl
├── domain/     entities, models (events/phases), repository, usecases, engine interface
└── presentation/  providers, screen, widgets, l10n utils
```

**No barrel file** — import paths directly.

## Key files

| Area | Files |
|------|-------|
| Screen | `presentation/screens/tibetan_calendar_screen.dart` |
| Providers | `presentation/providers/tibetan_calendar_providers.dart` |
| Offline engine | `data/kharag_tibetan_calendar_service.dart` |
| Engine interface | `domain/tibetan_calendar_service.dart` |
| Remote API | `data/datasource/calendar_remote_datasource.dart` |
| Home integration | `todayCalendarDayProvider` |

## State management

- `StateProvider`: `selectedCalendarDayProvider`, `focusedCalendarMonthProvider`
- `FutureProvider.family`: `calendarMonthProvider`, `backendMonthOverlayProvider`, `todayCalendarDayProvider`
- `Provider`: `resolvedMonthDaysProvider` — merges engine (sync) + backend (async)

## Data sources

- **Remote:** `GET /calendar/{year}/{month}`, `GET /calendar/today`
- **Offline engine:** `KharagTibetanCalendarService` — always available fallback
- No persistent cache; engine computes synchronously

## Cross-feature dependencies

- **home** — consumes `todayCalendarDayProvider` for `CalendarBannerCard`
- **core** — `dioProvider`, l10n

## Hybrid resolution pattern

**Backend-primary, engine-fallback.** UI never blocks on network. Backend refines when available. Do not invert this — the grid must render immediately from the engine.

---

## How to make changes (LLM playbook)

### Principles

1. **Never block UI on network** — engine data renders first.
2. **Register all `ref.watch` before first `await`** in async providers (documented in codebase).
3. **Gregorian-month keyed API** with neighbour-month prefetch for grid padding.
4. Keep `domain/models/` for events/phases; `domain/entities/` for full entities.

### Do

- Extend moon-phase logic in `domain/models/moon_phase.dart`
- Add festival events in `monthEventsProvider` when backend supports them
- Update l10n via `calendar_l10n_utils.dart`
- Mirror home banner changes when `todayCalendarDayProvider` shape changes

### Don't

- Don't remove offline engine fallback
- Don't add blocking loading states for the month grid
- Don't create a barrel file without team agreement (feature has none today)

### Common tasks

| Task | Where to start |
|------|----------------|
| New lunar event type | `calendar_event.dart`, `monthEventsProvider`, widgets |
| Cell UI change | `calendar_day_cell.dart`, `tibetan_calendar_grid.dart` |
| API shape change | models → repository → `resolvedMonthDaysProvider` merge logic |
| Home banner | `home/.../calendar_banner_card.dart` + `todayCalendarDayProvider` |

### Testing

- Test engine-only path (no network)
- Test backend overlay merge
- Test month boundary / padding days
