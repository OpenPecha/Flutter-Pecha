// Generates the Tolgee bridge subclass of the gen-l10n `AppLocalizations`.
//
// Run after `flutter gen-l10n`:
//
//     dart run tool/generate_tolgee_bridge.dart
//
// Signatures are read from the generated abstract class rather than re-derived
// from the ARB metadata, so the emitted overrides always match exactly what
// gen-l10n produced. Any drift becomes an analyzer error instead of a silent
// mismatch.

import 'dart:io';

const String _sourcePath = 'lib/core/l10n/generated/app_localizations.dart';
const String _outputPath =
    'lib/core/l10n/tolgee/tolgee_app_localizations.g.dart';

void main(List<String> args) {
  final bool checkOnly = args.contains('--check');

  final File source = File(_sourcePath);
  if (!source.existsSync()) {
    stderr.writeln(
      'Could not find $_sourcePath. Run `flutter gen-l10n` first.',
    );
    exit(1);
  }

  final String body = _abstractClassBody(
    _stripComments(source.readAsStringSync()),
  );
  final List<_Member> members = _parseMembers(body);

  if (members.isEmpty) {
    stderr.writeln('Parsed no members from $_sourcePath. Aborting.');
    exit(1);
  }

  // Both modes format through the same pipeline, otherwise `--check` would
  // compare unformatted output against the formatted file on disk and always
  // report a mismatch.
  final String generated = _renderFormatted(members);
  final File output = File(_outputPath);

  if (checkOnly) {
    final String existing =
        output.existsSync() ? output.readAsStringSync() : '';
    if (_normalize(existing) != _normalize(generated)) {
      stderr.writeln(
        '$_outputPath is out of date. '
        'Run `dart run tool/generate_tolgee_bridge.dart`.',
      );
      exit(1);
    }
    stdout.writeln('$_outputPath is up to date (${members.length} members).');
    return;
  }

  output.parent.createSync(recursive: true);
  output.writeAsStringSync(generated);

  final int parameterized = members.where((_Member m) => m.isMethod).length;
  stdout.writeln(
    'Wrote $_outputPath: ${members.length} keys '
    '(${members.length - parameterized} plain, $parameterized parameterized).',
  );
}

/// Removes line comments so doc text cannot be mistaken for a declaration.
String _stripComments(String source) {
  return source
      .split('\n')
      .where((String line) => !line.trimLeft().startsWith('//'))
      .join('\n');
}

/// Extracts the body of `abstract class AppLocalizations { ... }` by matching
/// braces, so nested method bodies and collection literals are handled.
String _abstractClassBody(String source) {
  const String marker = 'abstract class AppLocalizations {';
  final int start = source.indexOf(marker);
  if (start == -1) {
    stderr.writeln('Could not locate `$marker` in $_sourcePath.');
    exit(1);
  }

  int depth = 0;
  final int openBrace = start + marker.length - 1;
  for (int i = openBrace; i < source.length; i++) {
    final String char = source[i];
    if (char == '{') {
      depth++;
    } else if (char == '}') {
      depth--;
      if (depth == 0) {
        return source.substring(openBrace + 1, i);
      }
    }
  }

  stderr.writeln('Unbalanced braces while parsing AppLocalizations.');
  exit(1);
}

final RegExp _getterPattern = RegExp(r'\bString\s+get\s+(\w+)\s*;');
final RegExp _methodPattern = RegExp(r'\bString\s+(\w+)\s*\(([^)]*)\)\s*;');

List<_Member> _parseMembers(String body) {
  final List<_Member> members = <_Member>[];
  final Set<String> seen = <String>{};

  for (final RegExpMatch match in _getterPattern.allMatches(body)) {
    final String name = match.group(1)!;
    if (seen.add(name)) {
      members.add(_Member(name: name, offset: match.start));
    }
  }

  for (final RegExpMatch match in _methodPattern.allMatches(body)) {
    final String name = match.group(1)!;
    if (name == 'get' || !seen.add(name)) {
      continue;
    }
    members.add(
      _Member(
        name: name,
        offset: match.start,
        parameters: _parseParameters(match.group(2)!),
      ),
    );
  }

  // Preserve source order so regenerating produces a stable diff.
  members.sort((_Member a, _Member b) => a.offset.compareTo(b.offset));
  return members;
}

List<_Parameter> _parseParameters(String raw) {
  final String trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return const <_Parameter>[];
  }
  // gen-l10n wraps long signatures and leaves a trailing comma; splitting on
  // ',' then yields an empty last segment that must be discarded.
  return trimmed
      .split(',')
      .map((String part) => part.trim())
      .where((String part) => part.isNotEmpty)
      .map((String part) {
        final List<String> tokens = part.split(RegExp(r'\s+'));
        return _Parameter(
          type: tokens.sublist(0, tokens.length - 1).join(' '),
          name: tokens.last,
        );
      })
      .toList();
}

String _render(List<_Member> members) {
  final StringBuffer buffer =
      StringBuffer()
        ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
        ..writeln('//')
        ..writeln('// Regenerate with:')
        ..writeln('//   dart run tool/generate_tolgee_bridge.dart')
        ..writeln()
        ..writeln("import '../generated/app_localizations.dart';")
        ..writeln("import 'tolgee_bridge.dart';")
        ..writeln()
        ..writeln('// ignore_for_file: type=lint')
        ..writeln()
        ..writeln(
          '/// Wraps the bundled gen-l10n translations so every key can be',
        )
        ..writeln(
          '/// overridden at runtime from Tolgee, falling back to [_fallback]',
        )
        ..writeln('/// whenever no remote value is available.')
        ..writeln('class TolgeeAppLocalizations extends AppLocalizations {')
        ..writeln('  TolgeeAppLocalizations(this._fallback)')
        ..writeln('    : super(_fallback.localeName);')
        ..writeln()
        ..writeln('  final AppLocalizations _fallback;')
        ..writeln();

  for (final _Member member in members) {
    buffer.writeln('  @override');
    if (member.isMethod) {
      final String signature = member.parameters
          .map((_Parameter p) => '${p.type} ${p.name}')
          .join(', ');
      final String argsMap = member.parameters
          .map((_Parameter p) => "'${p.name}': ${p.name}")
          .join(', ');
      final String forwarded = member.parameters
          .map((_Parameter p) => p.name)
          .join(', ');
      buffer
        ..writeln('  String ${member.name}($signature) => TolgeeBridge.format(')
        ..writeln('    localeName,')
        ..writeln("    '${member.name}',")
        ..writeln('    <String, Object>{$argsMap},')
        ..writeln('    () => _fallback.${member.name}($forwarded),')
        ..writeln('  );');
    } else {
      buffer
        ..writeln('  String get ${member.name} => TolgeeBridge.get(')
        ..writeln('    localeName,')
        ..writeln("    '${member.name}',")
        ..writeln('    () => _fallback.${member.name},')
        ..writeln('  );');
    }
    buffer.writeln();
  }

  final String text = buffer.toString();
  return '${text.trimRight()}\n}\n';
}

/// Renders the bridge and runs `dart format` over it.
///
/// Formatting happens in a scratch file under `.dart_tool` so it stays inside
/// the package and picks up the same language version as the real output.
String _renderFormatted(List<_Member> members) {
  final String rendered = _render(members);
  final File scratch = File('.dart_tool/tolgee_bridge.gen.dart');
  try {
    scratch.parent.createSync(recursive: true);
    scratch.writeAsStringSync(rendered);
    _format(scratch.path);
    return scratch.readAsStringSync();
  } catch (error) {
    stderr.writeln('Warning: could not format generated output: $error');
    return rendered;
  } finally {
    if (scratch.existsSync()) {
      scratch.deleteSync();
    }
  }
}

void _format(String path) {
  try {
    final ProcessResult result = Process.runSync(
      Platform.isWindows ? 'dart.bat' : 'dart',
      <String>['format', path],
      runInShell: true,
    );
    if (result.exitCode != 0) {
      stderr.writeln('Warning: `dart format` failed:\n${result.stderr}');
    }
  } catch (error) {
    stderr.writeln('Warning: could not run `dart format` on $path: $error');
  }
}

/// Compares ignoring formatting differences so `--check` does not fail purely
/// because the committed file has been through `dart format`.
String _normalize(String source) =>
    source.replaceAll(RegExp(r'\s+'), ' ').trim();

class _Member {
  _Member({
    required this.name,
    required this.offset,
    this.parameters = const <_Parameter>[],
  });

  final String name;
  final int offset;
  final List<_Parameter> parameters;

  bool get isMethod => parameters.isNotEmpty;
}

class _Parameter {
  _Parameter({required this.type, required this.name});

  final String type;
  final String name;
}
