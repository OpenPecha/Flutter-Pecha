// Widget for social login buttons
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/auth_provider.dart';

class SocialLoginButton extends ConsumerWidget {
  const SocialLoginButton({
    super.key,
    required this.connection,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.iconWidget,
    this.isBorder = false,
  });
  final String connection;
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Widget iconWidget;
  final bool isBorder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authNotifier = ref.read(authProvider.notifier);
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.7,
      child: ElevatedButton.icon(
        icon: iconWidget,
        style: OutlinedButton.styleFrom(
          side:
              isBorder
                  ? const BorderSide(color: Colors.grey, width: 0.5)
                  : BorderSide.none,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.centerLeft,
          shadowColor: Colors.black,
        ),

        onPressed: () async {
          if (connection == 'guest') {
            await authNotifier.continueAsGuest();
          } else {
            await authNotifier.login(connection: connection);
          }
        },
        label: Text(label, style: TextStyle(fontSize: 16)),
      ),
    );
  }
}
