// lib/core/network/http_client_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_pecha/features/auth/application/auth_provider.dart';
import 'authenticated_http_client.dart';

// Singleton HTTP client provider
final httpClientProvider = Provider<http.Client>((ref) {
  final authState = ref.watch(authProvider);

  // For unauthenticated users or guests, return simple HTTP client
  if (!authState.isLoggedIn || authState.isGuest) {
    return http.Client();
  }

  // For authenticated users, return singleton authenticated client and
  // provide a callback to handle refresh-token expiry → logout + redirect to login.
  final authNotifier = ref.read(authProvider.notifier);
  final authService = authNotifier.authService;

  return AuthenticatedHttpClient(http.Client(), authService);
});

// Alternative: Separate providers for different use cases
final publicHttpClientProvider = Provider<http.Client>((ref) => http.Client());

final authenticatedHttpClientProvider = Provider<http.Client>((ref) {
  final authNotifier = ref.read(authProvider.notifier);
  final authService = authNotifier.authService;
  return AuthenticatedHttpClient(http.Client(), authService);
});
