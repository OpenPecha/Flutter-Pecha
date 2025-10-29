/// Route configuration constants and utilities for the application
class RouteConfig {
  RouteConfig._();

  // Route paths
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String creatorInfo = '/creator_info';
  static const String plans = '/plans';
  static const String texts = '/texts';

  // Protected routes that require authentication
  static const Set<String> protectedRoutes = {
    profile,
    home,
    plans,
    creatorInfo,
  };

  // Public routes that don't require authentication
  static const Set<String> publicRoutes = {onboarding, login};

  /// Check if a given path requires authentication
  static bool isProtectedRoute(String path) {
    // Check exact matches first
    if (protectedRoutes.contains(path)) return true;

    // Check path prefixes for nested routes
    return protectedRoutes.any((route) => path.startsWith('$route/')) ||
        path.startsWith('/home/') ||
        path.startsWith('/plans/');
  }

  /// Check if a given path is a public route
  static bool isPublicRoute(String path) {
    return publicRoutes.contains(path);
  }
}
