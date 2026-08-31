abstract class AppException implements Exception {
  final String message;
  final String? requestId;
  final String? timestamp;

  const AppException(this.message, {this.requestId, this.timestamp});

  @override
  String toString() {
    return message;
  }
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.requestId, super.timestamp});

  @override
  String toString() {
    return message;
  }
}

class ServerException extends AppException {
  const ServerException(super.message, {super.requestId, super.timestamp});

  @override
  String toString() {
    return message;
  }
}

class CacheException extends AppException {
  const CacheException(super.message, {super.requestId, super.timestamp});

  @override
  String toString() {
    return message;
  }
}

class ValidationException extends AppException {
  final String? code;

  const ValidationException(
    super.message, {
    this.code,
    super.requestId,
    super.timestamp,
  });

  @override
  String toString() {
    return message;
  }
}

class AuthenticationException extends AppException {
  const AuthenticationException(
    super.message, {
    super.requestId,
    super.timestamp,
  });

  @override
  String toString() {
    return message;
  }
}

class AuthorizationException extends AppException {
  const AuthorizationException(
    super.message, {
    super.requestId,
    super.timestamp,
  });

  @override
  String toString() {
    return message;
  }
}

class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.requestId, super.timestamp});

  @override
  String toString() {
    return message;
  }
}

class PairingException extends AppException {
  const PairingException(super.message, {super.requestId, super.timestamp});

  @override
  String toString() {
    return message;
  }
}

class RateLimitException extends AppException {
  const RateLimitException(super.message, {super.requestId, super.timestamp});

  @override
  String toString() {
    return message;
  }
}
