import 'package:flutter_pecha/features/texts/models/version.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VersionState {
  final Version? version;
  final String skip;

  const VersionState({this.version, this.skip = '0'});

  VersionState copyWith({Version? version, String? skip}) {
    return VersionState(
      version: version ?? this.version,
      skip: skip ?? this.skip,
    );
  }
}

class VersionNotifier extends StateNotifier<VersionState> {
  VersionNotifier() : super(const VersionState());

  void setVersion(Version version, {String skip = '0'}) {
    state = state.copyWith(version: version, skip: skip);
  }

  void clearVersion() {
    state = const VersionState();
  }
}

final versionProvider = StateNotifierProvider<VersionNotifier, VersionState>((
  ref,
) {
  return VersionNotifier();
});
