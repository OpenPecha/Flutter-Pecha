// Shown right after login when the account has no first/last name yet (e.g.
// a brand-new phone/OTP signup). Collects a name and saves it via the same
// POST /users/info path as the "Edit profile" screen, then unblocks the
// route guard so navigation proceeds to onboarding/home.

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/error/error_message_mapper.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/network/connectivity_service.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/logo_label.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/shared/domain/validators/person_name_validator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState
    extends ConsumerState<CompleteProfileScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();

  String? _firstNameError;
  String? _lastNameError;
  String? _saveError;
  bool _isSaving = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  static String? _validatePersonName(String name, AppLocalizations l10n) {
    return switch (PersonNameValidator.validate(name)) {
      PersonNameValidationError.tooShort => l10n.person_name_min_length,
      PersonNameValidationError.tooLong => l10n.person_name_max_length,
      PersonNameValidationError.invalidCharacters =>
        l10n.person_name_invalid_chars,
      null => null,
    };
  }

  Future<void> _onContinue() async {
    final l10n = AppLocalizations.of(context)!;
    final firstNameError = _validatePersonName(_firstNameCtrl.text, l10n);
    final lastNameError = _validatePersonName(_lastNameCtrl.text, l10n);
    final firstName = PersonNameValidator.sanitize(_firstNameCtrl.text);
    final lastName = PersonNameValidator.sanitize(_lastNameCtrl.text);

    if (firstNameError != null ||
        lastNameError != null ||
        firstName == null ||
        lastName == null) {
      setState(() {
        _firstNameError = firstNameError ?? (firstName == null ? l10n.person_name_min_length : null);
        _lastNameError = lastNameError ?? (lastName == null ? l10n.person_name_min_length : null);
      });
      return;
    }

    final isOnline =
        await ref.read(connectivityServiceProvider).checkConnectivity();
    if (!mounted) return;
    if (!isOnline) {
      setState(() => _saveError = l10n.edit_profile_offline);
      return;
    }

    setState(() {
      _saveError = null;
      _isSaving = true;
    });

    final error = await ref
        .read(userProvider.notifier)
        .saveProfile(firstName: firstName, lastName: lastName);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error != null) {
      final friendly =
          ErrorMessageMapper.isNetworkError(error)
              ? l10n.edit_profile_offline
              : l10n.edit_profile_save_failed;
      setState(() => _saveError = friendly);
      return;
    }

    ref.read(authProvider.notifier).markProfileComplete();
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const LogoLabel(),
                  const SizedBox(height: 32),
                  Text(
                    "What's your name?",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tell us a little about yourself to finish setting up your account.',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.grey500),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _firstNameCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.edit_profile_first_name,
                      errorText: _firstNameError,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      if (_firstNameError != null) {
                        setState(
                          () => _firstNameError = _validatePersonName(v, l10n),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _lastNameCtrl,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: l10n.edit_profile_last_name,
                      errorText: _lastNameError,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      if (_lastNameError != null) {
                        setState(
                          () => _lastNameError = _validatePersonName(v, l10n),
                        );
                      }
                    },
                  ),
                  if (_saveError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _saveError!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isSaving ? null : _onContinue,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: isDark ? AppColors.primaryDark : null,
                    ),
                    child:
                        _isSaving
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : Text(l10n.onboarding_continue),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
