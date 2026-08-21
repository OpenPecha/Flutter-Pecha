import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_dual_settings_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_settings_providers.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/reader_secondary_version.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A/文 switch in the reader app bar.
///
/// Off (A) shows the chant / on-screen language only. On (文) keeps that text
/// on top and adds the Settings language as the inline second line.
class ReaderTranslateButton extends ConsumerStatefulWidget {
  const ReaderTranslateButton({super.key, required this.params});

  final ReaderParams params;

  @override
  ConsumerState<ReaderTranslateButton> createState() =>
      _ReaderTranslateButtonState();
}

class _ReaderTranslateButtonState extends ConsumerState<ReaderTranslateButton> {
  bool _filling = false;
  bool _didAutoFill = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeAutoFill();
    });
  }

  String? _sourceLanguage() {
    final fromNav = widget.params.navigationContext?.language?.trim();
    if (fromNav != null && fromNav.isNotEmpty) return fromNav;
    return ref.read(readerNotifierProvider(widget.params)).textDetail?.language;
  }

  Future<void> _maybeAutoFill() async {
    if (_didAutoFill || !mounted) return;
    final textId = widget.params.textId;
    final dual = ref.read(readerDualSettingsProvider(textId));
    if (!dual.secondaryEnabled || dual.secondary.versionId != null) return;
    final source = _sourceLanguage();
    if (source == null || source.isEmpty) return;
    _didAutoFill = true;
    await _fill(source);
  }

  Future<void> _fill(String sourceLanguage) async {
    if (_filling || !mounted) return;
    setState(() => _filling = true);
    try {
      final textDetail =
          ref.read(readerNotifierProvider(widget.params)).textDetail;
      await fillSettingsLanguageSecondary(
        ref: ref,
        context: context,
        textId: widget.params.textId,
        sourceLanguage: sourceLanguage,
        sourceVersionId: textDetail?.id,
      );
    } finally {
      if (mounted) setState(() => _filling = false);
    }
  }

  Future<void> _onPressed({
    required bool isOn,
    required bool available,
    required String? sourceLanguage,
  }) async {
    if (!available || _filling) return;
    HapticFeedback.lightImpact();
    final notifier = ref.read(
      readerDualSettingsProvider(widget.params.textId).notifier,
    );
    if (isOn) {
      notifier.setSecondaryEnabled(false);
      return;
    }
    if (sourceLanguage == null || sourceLanguage.isEmpty) return;
    await _fill(sourceLanguage);
  }

  @override
  Widget build(BuildContext context) {
    final textId = widget.params.textId;
    final dual = ref.watch(readerDualSettingsProvider(textId));
    final settingsLang = ref.watch(contentLanguageProvider);
    final readerState = ref.watch(readerNotifierProvider(widget.params));
    final languagesAsync = ref.watch(readerLanguagesProvider(textId));

    final sourceLanguage = () {
      final fromNav = widget.params.navigationContext?.language?.trim();
      if (fromNav != null && fromNav.isNotEmpty) return fromNav;
      return readerState.textDetail?.language;
    }();

    final languages = languagesAsync.asData?.value;
    final languagesFailed = languagesAsync.hasError;
    final available =
        !languagesFailed &&
        isReaderTranslateAvailable(
          settingsLanguage: settingsLang,
          sourceLanguage: sourceLanguage,
          languages: languages,
        );

    ref.listen(readerLanguagesProvider(textId), (_, next) {
      if (next.hasValue) {
        Future.microtask(_maybeAutoFill);
      }
    });
    ref.listen(readerNotifierProvider(widget.params), (_, next) {
      if (next.textDetail != null) {
        Future.microtask(_maybeAutoFill);
      }
    });

    final isOn = dual.secondaryEnabled && dual.secondary.versionId != null;
    final l10n = context.l10n;
    final tooltip =
        available
            ? l10n.reader_translate_tooltip
            : l10n.reader_translate_unavailable;

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap:
            available
                ? () => _onPressed(
                  isOn: isOn,
                  available: available,
                  sourceLanguage: sourceLanguage,
                )
                : null,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 56,
          height: 48,
          child: Center(
            child: Opacity(
              opacity: available ? 1 : 0.38,
              child: _TranslatePillSwitch(isOn: isOn),
            ),
          ),
        ),
      ),
    );
  }
}

/// Grey (off) / blue (on) pill with a blank white thumb and the combined
/// A/文 icon on the empty side of the track.
class _TranslatePillSwitch extends StatelessWidget {
  const _TranslatePillSwitch({required this.isOn});

  final bool isOn;

  static const Color _trackOnColor = Color(0xFF196BF1);
  static const Color _trackOffColor = Color(0xFFADADAD);
  static const Duration _duration = Duration(milliseconds: 200);
  static const double _width = 52;
  static const double _height = 28;
  static const double _thumb = 24;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: _duration,
      curve: Curves.easeInOut,
      width: _width,
      height: _height,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isOn ? _trackOnColor : _trackOffColor,
        borderRadius: BorderRadius.circular(_height / 2),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: _duration,
            curve: Curves.easeInOut,
            alignment: isOn ? Alignment.centerLeft : Alignment.centerRight,
            child: SizedBox(
              width: _thumb,
              height: _thumb,
              child: Center(
                child: Icon(
                  AppAssets.language,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
            ),
          ),
          AnimatedAlign(
            duration: _duration,
            curve: Curves.easeInOut,
            alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: _thumb,
              height: _thumb,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
