/// Capped exponential backoff for the chat socket: 1s, 2s, 4s, 8s, 16s, then
/// 30s forever. [attempt] is 1 for the first retry after a drop.
Duration chatReconnectDelay(int attempt) {
  if (attempt <= 1) return const Duration(seconds: 1);
  const cap = Duration(seconds: 30);
  // Shifting past 2^5 already exceeds the cap, so clamp before the shift to
  // keep the arithmetic away from overflow on a long-lived socket.
  final exponent = attempt - 1 > 5 ? 5 : attempt - 1;
  final seconds = 1 << exponent;
  final delay = Duration(seconds: seconds);
  return delay > cap ? cap : delay;
}
