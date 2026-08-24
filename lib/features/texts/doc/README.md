# Texts Feature

> **LLM context doc** — read this before changing anything under `lib/features/texts/`.

## Purpose

**Foundational text library** — browse, search, collections, TOC, version selection, segment actions. Powers **reader** pagination API and legacy chapter screen.

## User-facing functionality

- Text library browse, search (title, author, multilingual, segment)
- Table of contents, version/language selection
- Legacy `ChaptersScreen` with infinite scroll (parallel to reader feature)
- Segment commentary, translation, share, image export
- Font size preferences, continue-reading state
- Collections browsing

## Architecture

```
texts/
├── constants/
├── data/       4 datasources, rich models/, repositories
├── domain/     entities, repositories, usecases (grouped by concern)
├── presentation/  10+ provider files, screens, widgets
├── utils/
└── texts.dart    # large barrel
```

## Key files

| Area | Files |
|------|-------|
| Reader API | `textDetailsFutureProvider` + `GetTextDetailsUseCase` |
| Legacy reader | `presentation/screens/chapters/chapters_screen.dart` |
| Version pick | `version_selection/version_selection_screen.dart` |
| Search | `library_search`, `text_search` providers/delegates |
| Segments | `segment_repository`, segment providers |
| DI | `presentation/providers/use_case_providers.dart` |
| Barrel | `texts.dart` |

## State management

- `Either<Failure, T>` (fpdart) in async providers
- `TextDetailsParams` composite key for provider family equality
- `fontSizeNotifier` — global font size
- Pagination: `paginatedTextsProvider`
- Hooks + Riverpod in `ChaptersScreen`

## Data sources

- **TextRemoteDatasource** — list, TOC, versions, reader details
- **SegmentRemoteDatasource** — segment detail, commentary, translations
- **CollectionsRemoteDatasource**, **ShareRemoteDatasource**
- All via main **`dioProvider`**

## Cross-feature dependencies

- **reader** — consumes `textDetailsFutureProvider`, models, segment providers
- **recitation**, **plans**, **ai** — consume models/APIs
- **core** — locale, router, theme

## Dual reading paths

1. **Modern:** `reader` feature via `textDetailsFutureProvider`
2. **Legacy:** `ChaptersScreen`

Shared API — changes to reader pagination affect both.

---

## How to make changes (LLM playbook)

### Principles

1. **This is a foundation feature** — breaking API/provider changes ripple to reader, recitation, plans, AI.
2. **Domain entities ≠ data models** — map at repository boundary.
3. **Use composite param keys** for provider families (`TextDetailsParams.key`).
4. Prefer extending use cases over bypassing repository layer.

### Do

- Add new segment actions in widgets + segment providers
- Extend search via `text_search_usecases.dart` + delegates
- Keep `textDetailsFutureProvider` stable or coordinate reader migration
- Export new public APIs through `texts.dart` when cross-feature

### Don't

- Don't break `TextDetailsParams` equality casually — causes provider cache bugs
- Don't duplicate reader pagination logic in reader feature
- Don't mix domain entities into presentation without mapping

### Common tasks

| Task | Where to start |
|------|----------------|
| Reader pagination API | text remote datasource → `GetTextDetailsUseCase` → `textDetailsFutureProvider` |
| New search facet | search use cases + delegate + provider |
| Commentary | segment datasource → segment providers → `CommentaryPanel` |
| Collections | collections repository + providers |

### Testing

- Test provider family key stability
- Test Either failure paths in UI
- Regression-test reader integration after API model changes
