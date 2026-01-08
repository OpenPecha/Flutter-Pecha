class AiConfig {
  AiConfig._(); // Private constructor to prevent instantiation

  /// Timeout for establishing connection to the AI server
  static const Duration connectionTimeout = Duration(seconds: 30);

  /// Maximum time to wait for the entire streaming response
  /// Set to 5 minutes to allow for long AI responses
  static const Duration streamTimeout = Duration(minutes: 5);

  /// Timeout between individual tokens in a streaming response
  /// If no token is received within this time, the stream is considered stalled
  static const Duration tokenTimeout = Duration(seconds: 60);

  /// Timeout for non-streaming API requests (thread list, thread detail, delete)
  static const Duration requestTimeout = Duration(seconds: 30);
}
