# Tolgee over-the-air UI translations (Flutter)

UI strings can be updated in [Tolgee](https://tolgee.io) and picked up by
installed apps without a store release. Content/reader languages are a separate
system — this doc is only about **app UI i18n**.

## Purpose

- Ship default copy in ARB / gen-l10n (offline, type-safe).
- Override those strings at runtime from Tolgee Content Delivery (CDN).
- Keep every call site as `context.l10n.some_key` — no `tr('key')` migration.

## How it works

```
context.l10n.sign_in
  → TolgeeAppLocalizations (generated override)
     → Tolgee CDN value if loaded and language matches
     → else bundled AppLocalizationsEn / Bo / …
```

Key files:

| File | Role |
| --- | --- |
| [`lib/core/l10n/tolgee/tolgee_service.dart`](../lib/core/l10n/tolgee/tolgee_service.dart) | `Tolgee.init` / language switch, readiness probe |
| [`lib/core/l10n/tolgee/tolgee_bridge.dart`](../lib/core/l10n/tolgee/tolgee_bridge.dart) | Lookup + ICU format + ARB fallback |
| [`lib/core/l10n/tolgee/tolgee_locale_map.dart`](../lib/core/l10n/tolgee/tolgee_locale_map.dart) | App locale ↔ CDN tag |
| [`lib/core/l10n/tolgee/tolgee_localizations_delegate.dart`](../lib/core/l10n/tolgee/tolgee_localizations_delegate.dart) | Replaces `AppLocalizations.delegate` |
| [`lib/core/l10n/tolgee/tolgee_app_localizations.g.dart`](../lib/core/l10n/tolgee/tolgee_app_localizations.g.dart) | Generated overrides for all ARB keys |
| [`lib/main.dart`](../lib/main.dart) | Bootstrap + `tolgeeRevisionProvider` rebuild |

On cold start, the first frame may still show ARB text. After the CDN fetch
succeeds, `tolgeeRevisionProvider` bumps and `Localizations` reloads remote
strings. Offline or failed CDN → ARB only (no crash).

## CDN / project

Public Content Delivery prefix (namespace included; **no** trailing file name):

```text
https://cdn.tolg.ee/a23495c159b886551292e856ecf7a332/webuddhist
```

The Flutter SDK requests `{TOLGEE_CDN_URL}/{language}.json`. Published files:

| CDN file | App UI `languageCode` |
| --- | --- |
| `en.json` | `en` |
| `bo-IN.json` | `bo` |
| `zh-Hant-TW.json` | `zh` |
| `hi.json` | `hi` |
| `mn.json` | `mn` |
| `ne.json` | `ne` |

Requirements in Tolgee Content Delivery:

- Format: **Flat JSON**
- Namespace: `webuddhist` (encoded in the URL prefix above)
- ICU placeholders enabled
- Publish after edits (or auto-publish)

Env (per flavor `.env.dev` / `.env.staging` / `.env.prod`):

```env
TOLGEE_API_URL=https://app.tolgee.io/v2
TOLGEE_API_KEY=tgpak_...          # read-only project key
TOLGEE_CDN_URL=https://cdn.tolg.ee/a23495c159b886551292e856ecf7a332/webuddhist
TOLGEE_ENABLED=true
```

A read-only API key is still required: init calls `GET /v2/projects/languages`
even in CDN mode. The key ships inside the bundled `.env` asset — never grant
write scopes.

## Languages and switching

UI locale stays Riverpod [`localeProvider`](../lib/core/config/locale/locale_notifier.dart)
with bare codes (`en`, `bo`, `zh`, …). `TolgeeLocaleMap` remaps only the Tolgee
fetch tag (`bo` → `bo-IN`, `zh` → `zh-Hant-TW`). ARB fallbacks and Material
locale remain `bo` / `zh`.

## Usage in widgets

```dart
Text(context.l10n.sign_in)
Text(context.l10n.ai_greeting(name))
```

Do not call `Tolgee.translate` or `TranslationWidget` from feature code.

Context-free paths (e.g. notification scheduling) use
`tolgeeAppLocalizationsFor(locale)` from
[`tolgee_localizations_delegate.dart`](../lib/core/l10n/tolgee/tolgee_localizations_delegate.dart).

## Adding a new UI string

1. Add the key to all ARB files under `lib/core/l10n/`.
2. Regenerate:

```sh
flutter gen-l10n
dart run tool/generate_tolgee_bridge.dart
```

3. Use `context.l10n.your_new_key` in the widget.
4. Create/update the same key in Tolgee (namespace `webuddhist`) for each language.
5. Publish Content Delivery.
6. Relaunch the app (or switch language) to pick up the remote value.

CI runs `dart run tool/generate_tolgee_bridge.dart --check` so the generated
bridge cannot drift from gen-l10n.

## Verify OTA

1. Browser: open  
   `https://cdn.tolg.ee/a23495c159b886551292e856ecf7a332/webuddhist/en.json`  
   — expect flat JSON (HTTP 200).
2. Run the app (`flutter run --flavor dev -t lib/main_dev.dart` preferred).
3. Logs should include:  
   `Tolgee: Tolgee ready for en (CDN tag en)`  
   not a “no usable strings” warning.
4. Change `sign_in` in Tolgee → Publish → fully restart the app → UI shows the new text.

## Known limits

- Updates apply on next launch or language switch (no live push).
- Empty/404 CDN responses are treated as “use ARB” after the readiness probe.
- Do not put the filename in `TOLGEE_CDN_URL` — only the prefix through `/webuddhist`.
