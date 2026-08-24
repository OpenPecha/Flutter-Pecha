# AI Feature

> **LLM context doc** — read this before changing anything under `lib/features/ai/`.

## Purpose

AI chat and content search against the Buddhist text library. Users can search texts (guests allowed) or chat with AI and manage thread history (authenticated users).

## User-facing functionality

- AI chat with **streaming** SSE responses
- Search mode vs chat mode on one screen (`AiModeScreen`)
- Chat thread history: list, load, delete
- Tabbed search results: All, Authors, Contents, Titles
- Source citations bottom sheet for answers
- Rate limiting (10 req/min) and retry on transient failures
- Guest users: search only; login required for chat persistence

## Architecture

```
ai/
├── config/ai_config.dart
├── data/          datasource, models, repositories
├── domain/        entities, repositories, usecases
├── presentation/  controllers, providers, screens, widgets
├── services/      rate_limiter, retry_service
└── validators/    message_validator.dart
```

**Layers:** clean architecture + dedicated **controllers** in `presentation/controllers/` (not only notifiers).

## Key files

| Area | Files |
|------|-------|
| Entry screen | `presentation/screens/ai_mode_screen.dart` |
| Chat state | `presentation/controllers/chat_controller.dart` |
| Search state | `presentation/controllers/search_state_controller.dart` |
| Threads | `presentation/controllers/thread_list_controller.dart` |
| Streaming repo | `data/repositories/ai_chat_repository.dart` |
| Domain repo | `data/repositories/ai_repository_impl.dart` |
| HTTP client | `core/network/ai_dio_client.dart` (`aiDioProvider`) |
| Barrel | `ai.dart` |

## State management

- `StateNotifierProvider`: `chatControllerProvider`, `threadListControllerProvider`, `searchStateProvider`
- `Provider`: repository/datasource DI, `rateLimiterProvider`, `segmentUrlResolverProvider`
- Controllers own UI state; repositories own I/O

## Data sources

- **Remote AI API** via dedicated Dio client (`aiDioProvider`) — separate base URL and auth interceptors
- `POST /chats` — SSE streaming
- Thread CRUD via `ThreadRemoteDatasource`
- **No local persistence** — threads live on AI backend

## Cross-feature dependencies

- **auth** — `authProvider`, `userProvider` for guest gating, user email in requests, login drawer
- **core** — `aiDioProvider`, error mapping, l10n, theme

## Public API

Import from `features/ai/ai.dart` when possible. Barrel uses `hide` for name collisions (`SearchResult`, `ChatMessage`).

---

## How to make changes (LLM playbook)

### Principles

1. **Minimal scope** — touch only AI-related files unless routing/auth gating requires it.
2. **Match existing split** — streaming goes through `AiChatRepository`; domain `AIRepository` uses `Either<Failure, T>`.
3. **Never bypass rate limiter** for user-initiated chat sends.
4. **Guest path** — preserve search-without-login; gate chat/thread persistence behind auth.
5. **Use `aiDioProvider`**, not main `dioProvider`, for AI endpoints.

### Do

- Add new chat/search UI in `presentation/widgets/` grouped by concern
- Wire new API calls through datasource → repository → controller
- Handle streaming errors in `ChatController` with user-visible retry
- Use existing skeleton widgets for loading states
- Export new public symbols from `ai.dart` if other features need them

### Don't

- Don't merge AI HTTP into main API client without explicit reason
- Don't store chat threads locally — backend is source of truth
- Don't duplicate domain/presentation `ChatMessage` types — respect barrel `hide` exports
- Don't block search for guests when adding auth checks

### Common tasks

| Task | Where to start |
|------|----------------|
| New search tab | `search_results_screen.dart`, tab widgets, `searchStateProvider` |
| Chat UI tweak | `message_bubble.dart`, `message_list.dart`, `chat_controller.dart` |
| New AI endpoint | `ai_chat_remote_datasource.dart` → `ai_chat_repository.dart` → controller |
| Citation/source links | `segment_url_resolver_*`, `source_bottom_sheet.dart` |
| Rate limit change | `services/rate_limiter.dart`, `ai_config.dart` |

### Testing

- Test controllers with mocked repositories
- Verify guest vs authenticated flows separately
- Streaming: test error mid-stream and reconnect behavior
