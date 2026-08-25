# Recitation Feature

> **LLM context doc** — read this before changing anything under `lib/features/recitation/`.

## Purpose

Browse recitation catalogue, save/reorder "My Recitations", display multi-language content, and open texts in the reader.

## User-facing functionality

- Tabbed: My Recitations / All Recitations
- Multi-language display: recitation, translation, transliteration, adaptation
- Language-specific content ordering via `RecitationLanguageConfig`
- Toggle secondary/tertiary segments on/off
- Save/unsave (auth required), reorder saved list
- Debounced search, navigate to reader by `textId`

## Architecture

```
recitation/
├── data/       datasource, models, repositories (dual naming)
├── domain/     entities, content_type, language config, repository, usecases
├── presentation/  controllers, providers, screens, search, widgets
└── recitation.dart
```

Internal docs also exist: `ARCHITECTURE_DIAGRAM.md`, `REFACTORING_SUMMARY.md`, `BEST_PRACTICES_APPLIED.md`.

## Key files

| Area | Files |
|------|-------|
| Screen | `presentation/screens/recitations_screen.dart` |
| Cache repo | `data/repositories/recitations_repository.dart` |
| Domain repo | `recitation_repository_impl.dart` |
| Save flow | `presentation/controllers/recitation_save_controller.dart` |
| Language matrix | `domain/recitation_language_config.dart` |
| Search | `recitation_search_provider.dart` |
| Barrel | `recitation.dart` |

## State management

- `recitationsFutureProvider`, `savedRecitationsFutureProvider`
- `recitationContentProvider` (family)
- `RecitationSearchNotifier` — debounced
- `showSecondSegmentProvider`, `showThirdSegmentProvider` — global toggles
- Save/unsave via `FutureProvider.autoDispose.family`

## Data sources

- **Remote API** — list, saved, content, save/unsave, reorder, search
- **Hive cache** — stale-while-revalidate; offline fallback
- **ConnectivityService** — online/offline strategy

## Cross-feature dependencies

- **auth** — guest check for save; login drawer
- **core** — `contentLanguageProvider`, `CacheService`
- **reader** — navigation from cards

## Notable patterns

- **Dual repository:** `RecitationsRepository` (concrete, cache) vs `RecitationRepository` (domain)
- **Cache-first:** return stale immediately, refresh in background when online
- **Controller for imperative flows** — `RecitationSaveController`, not a notifier

---

## How to make changes (LLM playbook)

### Principles

1. **Language config drives API params and display order** — change `RecitationLanguageConfig` for new locales.
2. **Preserve cache-first behavior** — don't block UI on network when cache exists.
3. **Save flows through controller** — auth gate + provider invalidation in one place.
4. Read existing refactor docs before large structural changes.

### Do

- Add content types in `ContentType` enum + language config matrix
- Invalidate list providers after save/unsave/reorder
- Use debounced search notifier pattern for new filters
- Match skeleton/error widgets for loading states

### Don't

- Don't bypass cache layer for list fetches without reason
- Don't allow save without auth check
- Don't hardcode language content order in widgets

### Common tasks

| Task | Where to start |
|------|----------------|
| New language | `RecitationLanguageConfig`, content params |
| List UI | tab widgets + `recitation_card.dart` |
| Cache policy | `recitations_repository.dart` + `CacheService` |
| Open in reader | router + `textId` from model |

### Testing

- Test offline list from cache
- Test save invalidates saved tab
- Test language config produces correct API params
