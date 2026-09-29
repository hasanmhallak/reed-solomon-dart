/// Base exception for Reed-Solomon codec configuration and input errors.
class ReedSolomonException implements Exception {
  /// Creates an exception with a human-readable [message].
  ReedSolomonException(this.message);

  /// Description of the failure.
  final String message;

  @override
  String toString() => 'ReedSolomonException: $message';
}

/// Thrown when decoding fails final syndrome verification or is otherwise
/// impossible within the configured correction capacity.
class ReedSolomonDecodingException extends ReedSolomonException {
  /// Creates a decoding exception with a human-readable [message].
  ReedSolomonDecodingException(String message) : super(message);

  @override
  String toString() => 'ReedSolomonDecodingException: $message';
}
