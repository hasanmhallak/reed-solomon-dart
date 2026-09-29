/// Result of a Reed-Solomon decode attempt.
class ReedSolomonDecodeResult {
  /// Creates a decode result with unmodifiable defensive copies of all lists.
  ReedSolomonDecodeResult({
    required List<int> decodedData,
    required List<int> correctedCodeword,
    required List<int> correctedPositions,
    required List<int> erasurePositions,
    required List<int> unknownErrorPositions,
    required this.wasAlreadyValid,
  })  : decodedData = List<int>.unmodifiable(List<int>.from(decodedData)),
        correctedCodeword =
            List<int>.unmodifiable(List<int>.from(correctedCodeword)),
        correctedPositions =
            List<int>.unmodifiable(List<int>.from(correctedPositions)),
        erasurePositions =
            List<int>.unmodifiable(List<int>.from(erasurePositions)),
        unknownErrorPositions =
            List<int>.unmodifiable(List<int>.from(unknownErrorPositions));

  /// Data symbols with error-correction symbols removed.
  final List<int> decodedData;

  /// Full corrected codeword including error-correction symbols.
  final List<int> correctedCodeword;

  /// Zero-based indices of symbols that actually changed during correction.
  final List<int> correctedPositions;

  /// Erasure positions supplied by the caller (validated copy).
  final List<int> erasurePositions;

  /// Zero-based indices of unknown errors that were found and corrected.
  ///
  /// Corrected erasures are not listed here.
  final List<int> unknownErrorPositions;

  /// Whether the received codeword already had all-zero syndromes.
  final bool wasAlreadyValid;
}
