import 'package:finite_field_math/finite_field_math.dart';

import 'polynomial_arithmetic.dart';
import 'reed_solomon_decode_result.dart';
import 'reed_solomon_exception.dart';

/// Reed-Solomon encoder/decoder over a single owned [FiniteField].
///
/// Builds the generator polynomial once at construction. Public symbol and
/// codeword APIs use [List<int>] (not typed lists).
class ReedSolomonCodec {
  /// Creates a codec that owns [finiteField].
  ///
  /// [firstConsecutiveRoot] defaults to `0` (reedsolo-compatible).
  /// [errorCorrectionSymbols] must be at least 1 and less than
  /// `fieldSize - 1`.
  ///
  /// Throws [ReedSolomonException] when:
  /// * [errorCorrectionSymbols] is less than 1;
  /// * [errorCorrectionSymbols] is not less than `finiteField.fieldSize - 1`;
  /// * [firstConsecutiveRoot] is outside `0..finiteField.fieldSize - 2`.
  factory ReedSolomonCodec({
    required FiniteField finiteField,
    required int errorCorrectionSymbols,
    int firstConsecutiveRoot = 0,
  }) {
    if (errorCorrectionSymbols < 1) {
      throw ReedSolomonException(
        'errorCorrectionSymbols must be >= 1, got $errorCorrectionSymbols',
      );
    }
    if (errorCorrectionSymbols >= finiteField.fieldSize - 1) {
      throw ReedSolomonException(
        'errorCorrectionSymbols must be < fieldSize - 1 '
        '(${finiteField.fieldSize - 1}), got $errorCorrectionSymbols',
      );
    }
    if (firstConsecutiveRoot < 0 ||
        firstConsecutiveRoot >= finiteField.fieldSize - 1) {
      throw ReedSolomonException(
        'firstConsecutiveRoot must be in 0..${finiteField.fieldSize - 2}, '
        'got $firstConsecutiveRoot',
      );
    }
    return ReedSolomonCodec._(
      finiteField: finiteField,
      errorCorrectionSymbols: errorCorrectionSymbols,
      firstConsecutiveRoot: firstConsecutiveRoot,
      generatorPolynomial: _buildGeneratorPolynomial(
        finiteField: finiteField,
        errorCorrectionSymbols: errorCorrectionSymbols,
        firstConsecutiveRoot: firstConsecutiveRoot,
      ),
    );
  }

  ReedSolomonCodec._({
    required this.finiteField,
    required this.errorCorrectionSymbols,
    required this.firstConsecutiveRoot,
    required List<int> generatorPolynomial,
  }) : _generatorPolynomial = generatorPolynomial;

  /// Convenience constructor that creates and owns a new [FiniteField].
  ///
  /// Throws [ReedSolomonException] for the same codec configuration rules as
  /// [ReedSolomonCodec.new]. Invalid [symbolSizeInBits], [primitivePolynomial],
  /// or [primitiveElement] values may also cause the underlying [FiniteField]
  /// constructor to throw before those checks run.
  factory ReedSolomonCodec.fromFieldParameters({
    required int symbolSizeInBits,
    required int primitivePolynomial,
    required int primitiveElement,
    required int errorCorrectionSymbols,
    int firstConsecutiveRoot = 0,
  }) {
    return ReedSolomonCodec(
      finiteField: FiniteField(
        symbolSizeInBits: symbolSizeInBits,
        primitivePolynomial: primitivePolynomial,
        primitiveElement: primitiveElement,
      ),
      errorCorrectionSymbols: errorCorrectionSymbols,
      firstConsecutiveRoot: firstConsecutiveRoot,
    );
  }

  /// The single finite field owned by this codec.
  final FiniteField finiteField;

  /// Number of ECC symbols appended by [encode].
  final int errorCorrectionSymbols;

  /// First consecutive root index for the generator polynomial (default 0).
  final int firstConsecutiveRoot;

  final List<int> _generatorPolynomial;

  /// Generator polynomial built once at construction (highest-degree first).
  ///
  /// Returned as an unmodifiable view of the private owned list.
  List<int> get generatorPolynomial =>
      List<int>.unmodifiable(_generatorPolynomial);

  static List<int> _buildGeneratorPolynomial({
    required FiniteField finiteField,
    required int errorCorrectionSymbols,
    required int firstConsecutiveRoot,
  }) {
    var generator = <int>[1];
    for (var rootIndex = 0; rootIndex < errorCorrectionSymbols; rootIndex++) {
      final root = finiteField.exponent(firstConsecutiveRoot + rootIndex);
      generator = PolynomialArithmetic.multiply(
        finiteField,
        generator,
        <int>[1, root],
      );
    }
    return generator;
  }

  void _validateSymbols(List<int> symbols, String parameterName) {
    final fieldSize = finiteField.fieldSize;
    for (var index = 0; index < symbols.length; index++) {
      final symbol = symbols[index];
      if (symbol < 0 || symbol >= fieldSize) {
        throw ReedSolomonException(
          '$parameterName[$index] must be in 0..${fieldSize - 1}, got $symbol',
        );
      }
    }
  }

  void _validateCodewordLength(int codewordLength) {
    final maximumLength = finiteField.fieldSize - 1;
    if (codewordLength > maximumLength) {
      throw ReedSolomonException(
        'codeword length $codewordLength exceeds fieldSize - 1 ($maximumLength)',
      );
    }
  }

  /// Encodes [data] by appending exactly [errorCorrectionSymbols] ECC symbols.
  ///
  /// Does not mutate [data].
  ///
  /// Throws [ReedSolomonException] when:
  /// * [data] is empty;
  /// * any element of [data] is outside `0..fieldSize - 1`;
  /// * `data.length + errorCorrectionSymbols` exceeds `fieldSize - 1`.
  List<int> encode(List<int> data) {
    if (data.isEmpty) {
      throw ReedSolomonException('data must not be empty');
    }
    _validateSymbols(data, 'data');
    final codewordLength = data.length + errorCorrectionSymbols;
    _validateCodewordLength(codewordLength);

    final workspace = List<int>.from(data)
      ..addAll(List<int>.filled(errorCorrectionSymbols, 0));

    for (var dataIndex = 0; dataIndex < data.length; dataIndex++) {
      final coefficient = workspace[dataIndex];
      if (coefficient != 0) {
        for (var generatorIndex = 1;
            generatorIndex < _generatorPolynomial.length;
            generatorIndex++) {
          workspace[dataIndex + generatorIndex] = finiteField.add(
            workspace[dataIndex + generatorIndex],
            finiteField.multiply(
              _generatorPolynomial[generatorIndex],
              coefficient,
            ),
          );
        }
      }
    }

    final codeword = List<int>.from(data);
    codeword.addAll(
      workspace.sublist(workspace.length - errorCorrectionSymbols),
    );
    return codeword;
  }

  /// Returns true if all syndromes of [codeword] are zero.
  ///
  /// Does not attempt correction and does not mutate [codeword].
  ///
  /// Throws [ReedSolomonException] when:
  /// * any element of [codeword] is outside `0..fieldSize - 1`;
  /// * [codeword] length is not greater than [errorCorrectionSymbols];
  /// * [codeword] length exceeds `fieldSize - 1`.
  bool isValid(List<int> codeword) {
    _validateSymbols(codeword, 'codeword');
    if (codeword.length <= errorCorrectionSymbols) {
      throw ReedSolomonException(
        'codeword length must be greater than errorCorrectionSymbols',
      );
    }
    _validateCodewordLength(codeword.length);
    final syndromeValues = _computeSyndromes(codeword);
    for (final value in syndromeValues) {
      if (value != 0) {
        return false;
      }
    }
    return true;
  }

  List<int> _computeSyndromes(List<int> codeword) {
    final syndromeValues = List<int>.filled(errorCorrectionSymbols, 0);
    for (var syndromeIndex = 0;
        syndromeIndex < errorCorrectionSymbols;
        syndromeIndex++) {
      final evaluationPoint =
          finiteField.exponent(firstConsecutiveRoot + syndromeIndex);
      syndromeValues[syndromeIndex] = PolynomialArithmetic.evaluate(
        finiteField,
        codeword,
        evaluationPoint,
      );
    }
    return syndromeValues;
  }

  List<int> _validateErasurePositions(
    List<int> erasurePositions,
    int codewordLength,
  ) {
    if (erasurePositions.length > errorCorrectionSymbols) {
      throw ReedSolomonException(
        'erasure count ${erasurePositions.length} exceeds '
        'errorCorrectionSymbols $errorCorrectionSymbols',
      );
    }
    final validated = <int>[];
    final seen = <int>{};
    for (final position in erasurePositions) {
      if (position < 0) {
        throw ReedSolomonException(
          'erasure position must be non-negative, got $position',
        );
      }
      if (position >= codewordLength) {
        throw ReedSolomonException(
          'erasure position $position is out of range for codeword length '
          '$codewordLength',
        );
      }
      if (!seen.add(position)) {
        throw ReedSolomonException(
          'duplicate erasure position $position',
        );
      }
      validated.add(position);
    }
    return validated;
  }

  /// Decodes [receivedCodeword], optionally using known [erasurePositions].
  ///
  /// Does not mutate inputs.
  ///
  /// Throws [ReedSolomonException] when:
  /// * any element of [receivedCodeword] is outside `0..fieldSize - 1`;
  /// * [receivedCodeword] length is not greater than [errorCorrectionSymbols];
  /// * [receivedCodeword] length exceeds `fieldSize - 1`;
  /// * [erasurePositions] contains more than [errorCorrectionSymbols] entries;
  /// * any erasure position is negative, out of range for the codeword, or
  ///   duplicated;
  /// * the combined error-and-erasure count exceeds the correction capacity
  ///   (`2 * unknownErrors + erasures > errorCorrectionSymbols`);
  /// * an internal consistency check fails (Berlekamp–Massey degree, Chien
  ///   search root count, Chien root overlapping a known erasure, or zero
  ///   Forney formal derivative at an errata position);
  /// * after correction, one or more syndromes are still non-zero.
  ///
  /// Zero syndromes after a successful return mean the corrected word is a valid
  /// codeword for this codec. That is not proof it equals the original
  /// transmitted message when the number of corruptions exceeds the
  /// unique-decoding bound
  /// `2 * errors + erasures <= errorCorrectionSymbols`; the decoder may fail
  /// or miscorrect onto another codeword. Use an external checksum when that
  /// distinction matters.
  ReedSolomonDecodeResult decode(
    List<int> receivedCodeword, {
    List<int> erasurePositions = const <int>[],
  }) {
    _validateSymbols(receivedCodeword, 'receivedCodeword');
    if (receivedCodeword.length <= errorCorrectionSymbols) {
      throw ReedSolomonException(
        'codeword length must be greater than errorCorrectionSymbols',
      );
    }
    _validateCodewordLength(receivedCodeword.length);

    final validatedErasures = _validateErasurePositions(
      erasurePositions,
      receivedCodeword.length,
    );

    final originalSyndromes = _computeSyndromes(receivedCodeword);
    final alreadyValid = _allZero(originalSyndromes);
    if (alreadyValid) {
      return ReedSolomonDecodeResult(
        decodedData: receivedCodeword.sublist(
          0,
          receivedCodeword.length - errorCorrectionSymbols,
        ),
        correctedCodeword: List<int>.from(receivedCodeword),
        correctedPositions: const <int>[],
        erasurePositions: validatedErasures,
        unknownErrorPositions: const <int>[],
        wasAlreadyValid: true,
      );
    }

    // Work copy: zero known erasures for the errors-and-erasures path.
    final workingCodeword = List<int>.from(receivedCodeword);
    for (final position in validatedErasures) {
      workingCodeword[position] = 0;
    }

    final syndromeValues = _computeSyndromes(workingCodeword);
    if (_allZero(syndromeValues)) {
      // Erasures were the only corruptions and were already zero.
      return _buildResult(
        correctedCodeword: workingCodeword,
        receivedCodeword: receivedCodeword,
        erasurePositions: validatedErasures,
        unknownErrorPositions: const <int>[],
        wasAlreadyValid: false,
      );
    }

    final forneySyndromeValues = _computeForneySyndromes(
      syndromeValues,
      validatedErasures,
      workingCodeword.length,
    );

    final unknownErrorLocator = _berlekampMassey(
      forneySyndromeValues,
      erasureCount: validatedErasures.length,
    );

    final unknownDegree = unknownErrorLocator.length - 1;
    if (unknownDegree * 2 + validatedErasures.length > errorCorrectionSymbols) {
      throw ReedSolomonException(
        'too many errors and erasures to correct '
        '(unknownDegree=$unknownDegree, '
        'erasures=${validatedErasures.length}, '
        'errorCorrectionSymbols=$errorCorrectionSymbols)',
      );
    }

    final unknownErrorPositions = unknownDegree == 0
        ? <int>[]
        : _chienSearch(unknownErrorLocator, workingCodeword.length);

    final erasureSet = validatedErasures.toSet();
    for (final position in unknownErrorPositions) {
      if (erasureSet.contains(position)) {
        throw ReedSolomonException(
          'Chien search returned erasure position $position',
        );
      }
    }

    final allErrataPositions = <int>[
      ...validatedErasures,
      ...unknownErrorPositions,
    ];

    final magnitudes = _forneyMagnitudes(
      allErrataPositions,
      syndromeValues,
      workingCodeword.length,
    );

    final correctedCodeword = List<int>.from(workingCodeword);
    for (final entry in magnitudes.entries) {
      correctedCodeword[entry.key] = finiteField.add(
        correctedCodeword[entry.key],
        entry.value,
      );
    }

    final verifiedSyndromes = _computeSyndromes(correctedCodeword);
    if (!_allZero(verifiedSyndromes)) {
      throw ReedSolomonException(
        'correction failed final syndrome verification',
      );
    }

    return _buildResult(
      correctedCodeword: correctedCodeword,
      receivedCodeword: receivedCodeword,
      erasurePositions: validatedErasures,
      unknownErrorPositions: unknownErrorPositions,
      wasAlreadyValid: false,
    );
  }

  ReedSolomonDecodeResult _buildResult({
    required List<int> correctedCodeword,
    required List<int> receivedCodeword,
    required List<int> erasurePositions,
    required List<int> unknownErrorPositions,
    required bool wasAlreadyValid,
  }) {
    final correctedPositions = <int>[];
    for (var index = 0; index < correctedCodeword.length; index++) {
      if (correctedCodeword[index] != receivedCodeword[index]) {
        correctedPositions.add(index);
      }
    }
    return ReedSolomonDecodeResult(
      decodedData: correctedCodeword.sublist(
        0,
        correctedCodeword.length - errorCorrectionSymbols,
      ),
      correctedCodeword: correctedCodeword,
      correctedPositions: correctedPositions,
      erasurePositions: List<int>.from(erasurePositions),
      unknownErrorPositions: List<int>.from(unknownErrorPositions),
      wasAlreadyValid: wasAlreadyValid,
    );
  }

  bool _allZero(List<int> values) {
    for (final value in values) {
      if (value != 0) {
        return false;
      }
    }
    return true;
  }

  List<int> _computeForneySyndromes(
    List<int> syndromeValues,
    List<int> erasurePositions,
    int codewordLength,
  ) {
    final forneySyndromeValues = List<int>.from(syndromeValues);
    for (final position in erasurePositions) {
      final evaluationPoint =
          finiteField.exponent(codewordLength - 1 - position);
      for (var index = 0; index < forneySyndromeValues.length - 1; index++) {
        forneySyndromeValues[index] = finiteField.add(
          finiteField.multiply(
            forneySyndromeValues[index],
            evaluationPoint,
          ),
          forneySyndromeValues[index + 1],
        );
      }
    }
    return forneySyndromeValues;
  }

  /// Berlekamp-Massey on Forney syndromes. Returns highest-degree-first locator.
  List<int> _berlekampMassey(
    List<int> syndromeValues, {
    required int erasureCount,
  }) {
    var connection = <int>[1]; // lowest-degree first
    var previous = <int>[1];
    var locatorDegree = 0;
    var shiftSinceUpdate = 1;
    var lastDiscrepancy = 1;

    final iterations = errorCorrectionSymbols - erasureCount;
    for (var iteration = 0; iteration < iterations; iteration++) {
      var discrepancy = syndromeValues[iteration];
      for (var term = 1; term <= locatorDegree; term++) {
        discrepancy = finiteField.add(
          discrepancy,
          finiteField.multiply(
            connection[term],
            syndromeValues[iteration - term],
          ),
        );
      }

      if (discrepancy == 0) {
        shiftSinceUpdate++;
      } else {
        final scale = finiteField.divide(discrepancy, lastDiscrepancy);
        final term = <int>[
          ...List<int>.filled(shiftSinceUpdate, 0),
          ...PolynomialArithmetic.scaleLowestFirst(
            finiteField,
            previous,
            scale,
          ),
        ];
        final updatedConnection = PolynomialArithmetic.addLowestFirst(
          finiteField,
          connection,
          term,
        );
        if (2 * locatorDegree <= iteration) {
          previous = List<int>.from(connection);
          locatorDegree = iteration + 1 - locatorDegree;
          lastDiscrepancy = discrepancy;
          shiftSinceUpdate = 1;
        } else {
          shiftSinceUpdate++;
        }
        connection = updatedConnection;
      }
    }

    while (connection.length > 1 && connection.last == 0) {
      connection = connection.sublist(0, connection.length - 1);
    }
    if (connection.length - 1 < locatorDegree) {
      throw ReedSolomonException(
        'Berlekamp-Massey locator degree inconsistency '
        '(trimmedDegree=${connection.length - 1}, '
        'locatorDegree=$locatorDegree)',
      );
    }
    return connection.reversed.toList();
  }

  List<int> _chienSearch(
      List<int> errorLocatorHighestFirst, int codewordLength) {
    final expectedDegree = errorLocatorHighestFirst.length - 1;
    final positions = <int>[];
    for (var power = 0; power < codewordLength; power++) {
      final point = finiteField.exponent(-power);
      if (PolynomialArithmetic.evaluate(
            finiteField,
            errorLocatorHighestFirst,
            point,
          ) ==
          0) {
        positions.add(codewordLength - 1 - power);
      }
    }
    if (positions.length != expectedDegree) {
      throw ReedSolomonException(
        'Chien search found ${positions.length} roots, '
        'expected $expectedDegree',
      );
    }
    return positions;
  }

  Map<int, int> _forneyMagnitudes(
    List<int> errataPositions,
    List<int> syndromeValues,
    int codewordLength,
  ) {
    // Errata locator (lowest-degree first): product (1 + X_i x)
    var locatorLowestFirst = <int>[1];
    for (final position in errataPositions) {
      final xValue = finiteField.exponent(codewordLength - 1 - position);
      locatorLowestFirst = PolynomialArithmetic.multiplyLowestFirst(
        finiteField,
        locatorLowestFirst,
        <int>[1, xValue],
      );
    }

    final omega = List<int>.filled(errorCorrectionSymbols, 0);
    for (var degree = 0; degree < errorCorrectionSymbols; degree++) {
      for (var term = 0; term <= degree; term++) {
        if (term < locatorLowestFirst.length) {
          omega[degree] = finiteField.add(
            omega[degree],
            finiteField.multiply(
              locatorLowestFirst[term],
              syndromeValues[degree - term],
            ),
          );
        }
      }
    }

    final magnitudes = <int, int>{};
    for (final position in errataPositions) {
      final xValue = finiteField.exponent(codewordLength - 1 - position);
      final xInverse = finiteField.inverse(xValue);

      var evaluator = 0;
      var power = 1;
      for (final coefficient in omega) {
        evaluator = finiteField.add(
          evaluator,
          finiteField.multiply(coefficient, power),
        );
        power = finiteField.multiply(power, xInverse);
      }

      // Formal derivative of locator at xInverse (characteristic 2).
      var derivative = 0;
      for (var degree = 1; degree < locatorLowestFirst.length; degree++) {
        if ((degree & 1) != 0 && locatorLowestFirst[degree] != 0) {
          final term = degree == 1
              ? locatorLowestFirst[degree]
              : finiteField.multiply(
                  locatorLowestFirst[degree],
                  finiteField.power(xInverse, degree - 1),
                );
          derivative = finiteField.add(derivative, term);
        }
      }
      if (derivative == 0) {
        throw ReedSolomonException(
          'Forney derivative is zero at position $position',
        );
      }

      final xFactor = finiteField.power(xValue, 1 - firstConsecutiveRoot);
      magnitudes[position] = finiteField.divide(
        finiteField.multiply(evaluator, xFactor),
        derivative,
      );
    }
    return magnitudes;
  }
}
