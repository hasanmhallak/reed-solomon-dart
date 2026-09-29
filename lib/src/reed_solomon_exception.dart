/// Exception type for this library.
///
/// Thrown by [ReedSolomonCodec] constructors and methods when configuration,
/// caller input, or the decoding algorithm cannot proceed or cannot verify a
/// corrected codeword.
class ReedSolomonException implements Exception {
  /// Creates an exception with a human-readable [message].
  ReedSolomonException(this.message);

  /// Description of the failure.
  final String message;

  @override
  String toString() => 'ReedSolomonException: $message';
}
