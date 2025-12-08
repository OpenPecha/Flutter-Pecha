/// Base exception class for all plan-related errors
abstract class PlanException implements Exception {
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const PlanException(
    this.message, {
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    if (originalError != null) {
      return '$runtimeType: $message\nOriginal error: $originalError';
    }
    return '$runtimeType: $message';
  }
}

/// Exception thrown when API requests fail
class PlanApiException extends PlanException {
  final int? statusCode;
  final String? responseBody;

  const PlanApiException(
    super.message, {
    this.statusCode,
    this.responseBody,
    super.originalError,
    super.stackTrace,
  });

  /// Check if the error is due to network connectivity issues
  bool get isNetworkError =>
      originalError != null &&
      (originalError.toString().contains('SocketException') ||
          originalError.toString().contains('Failed host lookup'));

  /// Check if the error is a client error (4xx)
  bool get isClientError => statusCode != null && statusCode! >= 400 && statusCode! < 500;

  /// Check if the error is a server error (5xx)
  bool get isServerError => statusCode != null && statusCode! >= 500;

  @override
  String toString() {
    final buffer = StringBuffer('$runtimeType: $message');
    if (statusCode != null) {
      buffer.write(' (Status: $statusCode)');
    }
    if (responseBody != null && responseBody!.isNotEmpty) {
      buffer.write('\nResponse: $responseBody');
    }
    if (originalError != null) {
      buffer.write('\nOriginal error: $originalError');
    }
    return buffer.toString();
  }
}

/// Exception thrown when data validation fails
class PlanValidationException extends PlanException {
  final String? fieldName;

  const PlanValidationException(
    super.message, {
    this.fieldName,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() {
    if (fieldName != null) {
      return '$runtimeType ($fieldName): $message';
    }
    return super.toString();
  }
}

/// Exception thrown when data parsing/deserialization fails
class PlanDataException extends PlanException {
  final String? jsonField;

  const PlanDataException(
    super.message, {
    this.jsonField,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() {
    if (jsonField != null) {
      return '$runtimeType (field: $jsonField): $message';
    }
    return super.toString();
  }
}

/// Exception thrown when a plan operation fails (subscribe, unsubscribe, etc.)
class PlanOperationException extends PlanException {
  final String operation;

  const PlanOperationException(
    this.operation,
    super.message, {
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() {
    return '$runtimeType ($operation): $message';
  }
}

/// Exception thrown when plan not found
class PlanNotFoundException extends PlanException {
  final String planId;

  const PlanNotFoundException(
    this.planId, {
    super.originalError,
    super.stackTrace,
  }) : super('Plan not found: $planId');
}

/// Exception thrown when user is not enrolled in a plan
class PlanNotEnrolledException extends PlanException {
  final String planId;

  const PlanNotEnrolledException(
    this.planId, {
    super.originalError,
    super.stackTrace,
  }) : super('User is not enrolled in plan: $planId');
}
