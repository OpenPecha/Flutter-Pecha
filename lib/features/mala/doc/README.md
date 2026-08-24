# Mala Feature

> **LLM context doc** — read this before changing anything under `lib/features/mala/`.

## Purpose

Per-mantra prayer-bead counter. Taps increment a monotonic session total, persisted locally (Hive) and synced to backend as **absolute counts**. Supports personal and group accumulation.

## User-facing functionality

- Tap or right-to-left swipe on bead arc (+1)
- Mantra carousel with preset catalogue
- Round tracking (`108` beads per round — `kBeadsPerRound`)
- Personal vs group accumulation selection
- Group accumulations bar + bottom sheet
- Sound / vibration feedback
- Reset session, add offline rounds, bookmark preset
- Background sync on tap, round completion, lifecycle, reconnect

## Architecture

```
mala/
├── data/         datasources (remote + local Hive), models, repository impl
├── domain/       entities, repository, usecases
├── presentation/ providers, screen, services, widgets
└── README.md     # detailed technical reference (keep in sync)
```

## Key files

| Area | Files |
|------|-------|
| Screen | `presentation/screens/mala_screen.dart` |
| Counter | `presentation/providers/mala_counter_notifier.dart` |
| Sync | `presentation/providers/mala_sync_manager.dart` |
| Local store | `data/datasources/mala_local_datasource.dart` |
| Group counts | `group_accumulation_counts_provider.dart` |
| Selection | `mala_accumulation_selection_provider.dart` |
| Tests | `test/features/mala/` |

## State management

| Provider | Purpose |
|----------|---------|
| `malaCounterProvider` | Per-preset counter (family) |
| `malaSyncManagerProvider` | App-scoped background sync |
| `joinedAccumulatorGroupsProvider` | Joined groups for preset |
| `groupAccumulationCountsProvider` | Per-group session counts |
| `malaAccumulationSelectionProvider` | Personal vs group (SharedPreferences) |

## Critical invariants

1. **Monotonic absolutes** — client sends absolute session totals; server takes `max()`.
2. **Seed-before-send** — block taps until server count merged via `max()`.
3. **User ID from persisted storage first** — `_resolveUserId()` avoids auth race.
4. **Group session vs lifetime** — counter uses session; sheet shows lifetime (`user_total_count` vs `user.total_count`).
5. **Presigned bead URLs** — cache as base64 in Hive; widget uses bytes only.

## Cross-feature dependencies

- **auth** — user ID namespacing
- **group_profile** — group accumulator detail API
- **reader** — group chant mode entry

## Detailed reference

See also **`../README.md`** (same feature root) for API tables, sync flow, bead rendering, and test inventory. **Update both docs** when changing counting/sync semantics.

---

## How to make changes (LLM playbook)

### Principles

1. **Never decrease counts** — monotonic only.
2. **Never enable taps during seeding** (`isSeeding`).
3. **Sync manager and counter must share the same user ID resolution.**
4. **Group changes require coordinating session vs lifetime fields** — read the detailed README section.
5. Run **`test/features/mala/`** after any counter/sync change.

### Do

- Persist dirty state in Hive; let `MalaSyncManager` flush
- Use debounced sync on tap (5s) and immediate on round completion
- Download bead images during seed, store base64 in Hive
- Invalidate group providers after group reset

### Don't

- Don't send relative increments to API — absolutes only
- Don't load presigned S3 URLs directly in `MalaBeads` widget
- Don't use `userProvider` alone for storage keys — use persisted `currentUserId`
- Don't conflate group lifetime totals with session counter display

### Common tasks

| Task | Where to start |
|------|----------------|
| New preset field | model → entity → remote datasource → catalogue provider |
| Sync bug | `mala_sync_manager.dart`, `mala_local_datasource.dart`, tests |
| Group counting | `group_accumulation_counts_provider.dart` + mala README group section |
| Bead UI | `mala_beads.dart` — forward-only animation on +1 only |

### Testing

Mandatory: `mala_counter_notifier_test.dart`, `mala_sync_manager_test.dart`, `mala_beads_test.dart`
