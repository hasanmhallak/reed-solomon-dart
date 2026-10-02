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

  ReedSolomonDecodeResult copyWith({
    List<int>? decodedData,
    List<int>? correctedCodeword,
    List<int>? correctedPositions,
    List<int>? erasurePositions,
    List<int>? unknownErrorPositions,
    bool? wasAlreadyValid,
  }) {
    return ReedSolomonDecodeResult(
      decodedData: decodedData ?? this.decodedData,
      correctedCodeword: correctedCodeword ?? this.correctedCodeword,
      correctedPositions: correctedPositions ?? this.correctedPositions,
      erasurePositions: erasurePositions ?? this.erasurePositions,
      unknownErrorPositions:
          unknownErrorPositions ?? this.unknownErrorPositions,
      wasAlreadyValid: wasAlreadyValid ?? this.wasAlreadyValid,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'decodedData': decodedData,
      'correctedCodeword': correctedCodeword,
      'correctedPositions': correctedPositions,
      'erasurePositions': erasurePositions,
      'unknownErrorPositions': unknownErrorPositions,
      'wasAlreadyValid': wasAlreadyValid,
    };
  }

  factory ReedSolomonDecodeResult.fromJson(Map<String, dynamic> map) {
    return ReedSolomonDecodeResult(
      decodedData: List<int>.from(map['decodedData'] as List<int>),
      correctedCodeword: List<int>.from(map['correctedCodeword'] as List<int>),
      correctedPositions:
          List<int>.from(map['correctedPositions'] as List<int>),
      erasurePositions: List<int>.from(map['erasurePositions'] as List<int>),
      unknownErrorPositions:
          List<int>.from(map['unknownErrorPositions'] as List<int>),
      wasAlreadyValid: (map['wasAlreadyValid'] as bool?) ?? false,
    );
  }

  @override
  String toString() {
    return 'ReedSolomonDecodeResult(decodedData: $decodedData, correctedCodeword: $correctedCodeword, correctedPositions: $correctedPositions, erasurePositions: $erasurePositions, unknownErrorPositions: $unknownErrorPositions, wasAlreadyValid: $wasAlreadyValid)';
  }
}
