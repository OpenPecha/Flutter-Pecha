import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';

class LogoLabel extends StatelessWidget {
  const LogoLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Logo or splash animation can go here
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Image.asset('assets/images/favicon-pecha.png', height: 150),
        ),
        Text(
          localizations.pechaHeading,
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
