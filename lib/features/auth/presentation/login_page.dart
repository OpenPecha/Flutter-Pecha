// This file contains the UI for the login page, following the provided design.
// It offers social login options and a guest login button.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/widgets/auth_buttons.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0, top: 32.0),
                    child: Image.asset(
                      'assets/images/favicon-pecha.png',
                      height: 150,
                    ),
                  ),
                  const Text(
                    'Pecha',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32),
                  ),
                  const SizedBox(height: 36),
                  // Auth Buttons (Riverpod aware)
                  const AuthButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
