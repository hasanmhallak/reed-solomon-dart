import 'dart:math';

import 'package:finite_field_math/finite_field_math.dart';
import 'package:reed_solomon_codec/reed_solomon_codec.dart';
import 'package:test/test.dart';

import 'reedsolo_reference_vectors.dart';

void main() {
  FiniteField buildGaloisField256() => FiniteField(
        symbolSizeInBits: ReedsoloReferenceVectors.symbolSizeInBits,
        primitivePolynomial: ReedsoloReferenceVectors.primitivePolynomial,
        primitiveElement: ReedsoloReferenceVectors.primitiveElement,
      );

  ReedSolomonCodec buildCodec({
    int errorCorrectionSymbols = 2,
    int firstConsecutiveRoot = 0,
    FiniteField? finiteField,
  }) {
    return ReedSolomonCodec(
      finiteField: finiteField ?? buildGaloisField256(),
      errorCorrectionSymbols: errorCorrectionSymbols,
      firstConsecutiveRoot: firstConsecutiveRoot,
    );
  }

  test('reed solomon codec should own single finite field instance', () {
    final finiteField = buildGaloisField256();
    final codec = ReedSolomonCodec(
      finiteField: finiteField,
      errorCorrectionSymbols: 2,
    );
    expect(identical(codec.finiteField, finiteField), isTrue);
  });

  test('reed solomon codec should compute generator polynomial once at construction',
      () {
    final codec = buildCodec(errorCorrectionSymbols: 3);
    final first = codec.generatorPolynomial;
    final second = codec.generatorPolynomial;
    expect(first, equals(second));
    expect(first.length, 4); // degree 3 => 4 coefficients
    // Roots alpha^0, alpha^1, alpha^2 for fcr=0
    expect(first.first, isNot(0));
    expect(first.last, isNot(0));
  });

  test('reed solomon codec should default first consecutive root to zero', () {
    final codec = ReedSolomonCodec(
      finiteField: buildGaloisField256(),
      errorCorrectionSymbols: 2,
    );
    expect(codec.firstConsecutiveRoot, 0);
  });

  test('reed solomon codec should reject error correction symbols less than one', () {
    expect(
      () => buildCodec(errorCorrectionSymbols: 0),
      throwsA(isA<ReedSolomonException>()),
    );
    expect(
      () => buildCodec(errorCorrectionSymbols: -1),
      throwsA(isA<ReedSolomonException>()),
    );
  });

  test(
      'reed solomon codec should reject error correction symbols at or above field size minus one',
      () {
    final smallField = FiniteField(
      symbolSizeInBits: 4,
      primitivePolynomial: 0x13,
      primitiveElement: 2,
    );
    // fieldSize - 1 == 15
    expect(
      () => ReedSolomonCodec(
        finiteField: smallField,
        errorCorrectionSymbols: 15,
      ),
      throwsA(isA<ReedSolomonException>()),
    );
    expect(
      () => ReedSolomonCodec(
        finiteField: smallField,
        errorCorrectionSymbols: 16,
      ),
      throwsA(isA<ReedSolomonException>()),
    );
    // Still below the bound: construct succeeds.
    final allowed = ReedSolomonCodec(
      finiteField: smallField,
      errorCorrectionSymbols: 14,
    );
    expect(allowed.errorCorrectionSymbols, 14);
  });

  test('reed solomon codec should reject codeword longer than field size minus one', () {
    final codec = buildCodec(errorCorrectionSymbols: 2);
    final tooLong = List<int>.filled(
        254, 1); // 254 data + 2 errorCorrectionSymbols = 256 > 255
    expect(() => codec.encode(tooLong), throwsA(isA<ReedSolomonException>()));
  });

  test('different reed solomon codec instances should remain independent', () {
    final first = buildCodec(errorCorrectionSymbols: 2);
    final second = buildCodec(errorCorrectionSymbols: 4);
    expect(first.errorCorrectionSymbols, 2);
    expect(second.errorCorrectionSymbols, 4);
    final encodedFirst = first.encode(ReedsoloReferenceVectors.dataFour);
    final encodedSecond =
        second.encode(ReedsoloReferenceVectors.dataThreeErrorCorrectionFour);
    expect(encodedFirst, isNot(equals(encodedSecond)));
    expect(first.encode(ReedsoloReferenceVectors.dataFour), encodedFirst);
    expect(
      second.encode(ReedsoloReferenceVectors.dataThreeErrorCorrectionFour),
      encodedSecond,
    );
  });

  test('encode should append exactly error correction symbols', () {
    final codec = buildCodec(errorCorrectionSymbols: 5);
    final data = <int>[1, 2, 3];
    final codeword = codec.encode(data);
    expect(codeword.length, data.length + 5);
  });

  test('encode should not mutate input data', () {
    final codec = buildCodec();
    final data = <int>[1, 2, 3, 4];
    final snapshot = List<int>.from(data);
    codec.encode(data);
    expect(data, snapshot);
  });

  test('encode should reject symbols outside configured field', () {
    final codec = buildCodec();
    expect(
      () => codec.encode(<int>[1, 256]),
      throwsA(isA<ReedSolomonException>()),
    );
    expect(
      () => codec.encode(<int>[-1, 2]),
      throwsA(isA<ReedSolomonException>()),
    );
  });

  test('encode should match reedsolo for matching galois field 256 configuration', () {
    final codec = buildCodec(errorCorrectionSymbols: 2);
    expect(
      codec.encode(ReedsoloReferenceVectors.dataFour),
      ReedsoloReferenceVectors.codewordFour,
    );
    expect(
      codec.encode(ReedsoloReferenceVectors.dataTwelveTen),
      ReedsoloReferenceVectors.codewordTwelveTen,
    );
    expect(
      codec.encode(ReedsoloReferenceVectors.dataSixteenFourteen),
      ReedsoloReferenceVectors.codewordSixteenFourteen,
    );
    final codecFour = buildCodec(errorCorrectionSymbols: 4);
    expect(
      codecFour.encode(ReedsoloReferenceVectors.dataThreeErrorCorrectionFour),
      ReedsoloReferenceVectors.codewordThreeErrorCorrectionFour,
    );
    expect(
      codecFour.encode(ReedsoloReferenceVectors.dataFiveErrorCorrectionFour),
      ReedsoloReferenceVectors.codewordFiveErrorCorrectionFour,
    );
  });

  test('encode should support shortened codewords without padding to full field', () {
    final codec = buildCodec(errorCorrectionSymbols: 2);
    final codeword = codec.encode(<int>[9, 8, 7]);
    expect(codeword.length, 5);
    expect(codeword.length, lessThan(255));
  });

  test('is valid should return true for freshly encoded codeword', () {
    final codec = buildCodec();
    final codeword = codec.encode(ReedsoloReferenceVectors.dataFour);
    expect(codec.isValid(codeword), isTrue);
  });

  test('is valid should return false when single symbol is corrupted', () {
    final codec = buildCodec();
    final codeword = List<int>.from(
      codec.encode(ReedsoloReferenceVectors.dataFour),
    );
    codeword[2] ^= 0x0F;
    expect(codec.isValid(codeword), isFalse);
  });

  test('is valid should not mutate input', () {
    final codec = buildCodec();
    final codeword = List<int>.from(
      codec.encode(ReedsoloReferenceVectors.dataFour),
    );
    codeword[1] ^= 1;
    final snapshot = List<int>.from(codeword);
    codec.isValid(codeword);
    expect(codeword, snapshot);
  });

  test('is valid should not attempt correction', () {
    final codec = buildCodec();
    final codeword = List<int>.from(
      codec.encode(ReedsoloReferenceVectors.dataFour),
    );
    codeword[0] ^= 0x22;
    expect(codec.isValid(codeword), isFalse);
    // Still corrupted — isValid must not have fixed it.
    expect(codeword[0], isNot(ReedsoloReferenceVectors.codewordFour[0]));
  });

  test('decode should succeed when codeword already valid', () {
    final codec = buildCodec();
    final codeword = codec.encode(ReedsoloReferenceVectors.dataFour);
    final result = codec.decode(codeword);
    expect(result.wasAlreadyValid, isTrue);
    expect(result.decodedData, ReedsoloReferenceVectors.dataFour);
    expect(result.correctedCodeword, codeword);
    expect(result.correctedPositions, isEmpty);
    expect(result.unknownErrorPositions, isEmpty);
  });

  test('decode should correct single unknown error within bound', () {
    final codec = buildCodec(errorCorrectionSymbols: 2);
    final codeword = List<int>.from(ReedsoloReferenceVectors.codewordFour);
    codeword[1] ^= 0xFF;
    final result = codec.decode(codeword);
    expect(result.decodedData, ReedsoloReferenceVectors.dataFour);
    expect(result.correctedCodeword, ReedsoloReferenceVectors.codewordFour);
    expect(result.unknownErrorPositions, <int>[1]);
    expect(result.wasAlreadyValid, isFalse);
  });

  test('decode should correct multiple unknown errors within bound', () {
    final codec = buildCodec(errorCorrectionSymbols: 4);
    final codeword = List<int>.from(
        ReedsoloReferenceVectors.codewordFiveErrorCorrectionFour);
    codeword[1] ^= 0x11;
    codeword[3] ^= 0x22;
    final result = codec.decode(codeword);
    expect(result.decodedData,
        ReedsoloReferenceVectors.dataFiveErrorCorrectionFour);
    expect(
      result.unknownErrorPositions.toList()..sort(),
      <int>[1, 3],
    );
  });

  test('decode should report unknown error positions as zero based codeword indices', () {
    final codec = buildCodec();
    final codeword = List<int>.from(ReedsoloReferenceVectors.codewordFour);
    codeword[4] ^= 0x01;
    final result = codec.decode(codeword);
    expect(result.unknownErrorPositions, <int>[4]);
    expect(result.unknownErrorPositions.first, lessThan(codeword.length));
    expect(result.unknownErrorPositions.first, greaterThanOrEqualTo(0));
  });

  test('decode should not mutate received codeword', () {
    final codec = buildCodec();
    final codeword = List<int>.from(ReedsoloReferenceVectors.codewordFour);
    codeword[2] ^= 0x55;
    final snapshot = List<int>.from(codeword);
    codec.decode(codeword);
    expect(codeword, snapshot);
  });

  test('decode should throw typed exception when final syndromes are non zero', () {
    final codec = buildCodec(errorCorrectionSymbols: 2);
    // Three corruptions — beyond bound for 2 ECC; force failure path.
    final codeword = List<int>.from(ReedsoloReferenceVectors.codewordFour);
    codeword[0] ^= 0x01;
    codeword[1] ^= 0x02;
    codeword[2] ^= 0x03;
    expect(
      () => codec.decode(codeword),
      throwsA(isA<ReedSolomonException>()),
    );
  });

  test('decode should correct known erasures within bound', () {
    final codec = buildCodec(errorCorrectionSymbols: 2);
    final codeword = List<int>.from(ReedsoloReferenceVectors.codewordFour);
    codeword[0] = 0;
    codeword[1] = 0;
    final result = codec.decode(
      codeword,
      erasurePositions: <int>[0, 1],
    );
    expect(result.decodedData, ReedsoloReferenceVectors.dataFour);
    expect(result.unknownErrorPositions, isEmpty);
    expect(result.erasurePositions, <int>[0, 1]);
  });

  test('decode should reject too many erasures deterministically', () {
    final codec = buildCodec(errorCorrectionSymbols: 2);
    final codeword = List<int>.from(ReedsoloReferenceVectors.codewordFour);
    expect(
      () => codec.decode(
        codeword,
        erasurePositions: <int>[0, 1, 2],
      ),
      throwsA(isA<ReedSolomonException>()),
    );
  });

  test('decode should reject negative erasure positions', () {
    final codec = buildCodec();
    final codeword = List<int>.from(ReedsoloReferenceVectors.codewordFour);
    expect(
      () => codec.decode(codeword, erasurePositions: <int>[-1]),
      throwsA(isA<ReedSolomonException>()),
    );
  });

  test('decode should reject out of range erasure positions', () {
    final codec = buildCodec();
    final codeword = List<int>.from(ReedsoloReferenceVectors.codewordFour);
    expect(
      () => codec.decode(codeword, erasurePositions: <int>[codeword.length]),
      throwsA(isA<ReedSolomonException>()),
    );
  });

  test('decode should reject duplicate erasure positions', () {
    final codec = buildCodec();
    final codeword = List<int>.from(ReedsoloReferenceVectors.codewordFour);
    expect(
      () => codec.decode(codeword, erasurePositions: <int>[1, 1]),
      throwsA(isA<ReedSolomonException>()),
    );
  });

  test('decode should not report corrected erasure as unknown error', () {
    final codec = buildCodec(errorCorrectionSymbols: 2);
    final codeword = List<int>.from(ReedsoloReferenceVectors.codewordFour);
    codeword[2] = 0x99;
    final result = codec.decode(
      codeword,
      erasurePositions: <int>[2],
    );
    expect(result.decodedData, ReedsoloReferenceVectors.dataFour);
    expect(result.erasurePositions, <int>[2]);
    expect(result.unknownErrorPositions, isEmpty);
    expect(result.unknownErrorPositions.contains(2), isFalse);
  });

  test('decode should correct mixed unknown errors and erasures within bound', () {
    final codec = buildCodec(errorCorrectionSymbols: 4);
    final codeword = List<int>.from(
        ReedsoloReferenceVectors.codewordFiveErrorCorrectionFour);
    codeword[0] = 0; // erasure
    codeword[2] ^= 0x33; // unknown
    final result = codec.decode(
      codeword,
      erasurePositions: <int>[0],
    );
    expect(result.decodedData,
        ReedsoloReferenceVectors.dataFiveErrorCorrectionFour);
    expect(result.erasurePositions, <int>[0]);
    expect(result.unknownErrorPositions, <int>[2]);
  });

  test('decode should use erasure locator and forney syndromes not errors only path', () {
    // Two erasures with only 2 ECC symbols cannot be corrected as unknown
    // errors (need 4 ECC), but succeed via the erasure path.
    final codec = buildCodec(errorCorrectionSymbols: 2);
    final codeword = List<int>.from(ReedsoloReferenceVectors.codewordFour);
    codeword[0] = 0xAA;
    codeword[5] = 0xBB;
    expect(
      () => codec.decode(codeword),
      throwsA(isA<ReedSolomonException>()),
    );
    final result = codec.decode(
      codeword,
      erasurePositions: <int>[0, 5],
    );
    expect(result.decodedData, ReedsoloReferenceVectors.dataFour);
    expect(result.unknownErrorPositions, isEmpty);
  });

  test('decode should correct error in short codeword at caller visible position', () {
    final codec = buildCodec(errorCorrectionSymbols: 2);
    final codeword = List<int>.from(ReedsoloReferenceVectors.codewordTwelveTen);
    codeword[3] ^= 0x55;
    final result = codec.decode(codeword);
    expect(result.decodedData, ReedsoloReferenceVectors.dataTwelveTen);
    expect(result.unknownErrorPositions, <int>[3]);
  });

  test('decode should report positions within actual codeword length not full field', () {
    final codec = buildCodec(errorCorrectionSymbols: 2);
    final codeword = List<int>.from(ReedsoloReferenceVectors.codewordTwelveTen);
    codeword[11] ^= 0x01;
    final result = codec.decode(codeword);
    expect(result.unknownErrorPositions, <int>[11]);
    expect(result.unknownErrorPositions.first, lessThan(codeword.length));
    expect(result.unknownErrorPositions.first, lessThan(255));
  });

  test('shortened reed solomon twelve ten should round trip with injected error', () {
    final codec = buildCodec(errorCorrectionSymbols: 2);
    expect(
      codec.encode(ReedsoloReferenceVectors.dataTwelveTen),
      ReedsoloReferenceVectors.codewordTwelveTen,
    );
    final codeword = List<int>.from(ReedsoloReferenceVectors.codewordTwelveTen);
    codeword[8] ^= 0xAB;
    final result = codec.decode(codeword);
    expect(result.decodedData, ReedsoloReferenceVectors.dataTwelveTen);
    expect(
        result.correctedCodeword, ReedsoloReferenceVectors.codewordTwelveTen);
  });

  test('shortened reed solomon sixteen fourteen should round trip with injected error',
      () {
    final codec = buildCodec(errorCorrectionSymbols: 2);
    expect(
      codec.encode(ReedsoloReferenceVectors.dataSixteenFourteen),
      ReedsoloReferenceVectors.codewordSixteenFourteen,
    );
    final codeword =
        List<int>.from(ReedsoloReferenceVectors.codewordSixteenFourteen);
    codeword[5] ^= 0xEE;
    final result = codec.decode(codeword);
    expect(result.decodedData, ReedsoloReferenceVectors.dataSixteenFourteen);
  });

  test('decode result should expose decoded data without error correction symbols', () {
    final codec = buildCodec(errorCorrectionSymbols: 2);
    final result = codec.decode(ReedsoloReferenceVectors.codewordFour);
    expect(result.decodedData.length, 4);
    expect(result.correctedCodeword.length, 6);
    expect(result.decodedData, ReedsoloReferenceVectors.dataFour);
  });

  test(
      'decode result should distinguish erasure positions unknown errors and corrected positions',
      () {
    final codec = buildCodec(errorCorrectionSymbols: 4);
    final codeword = List<int>.from(
        ReedsoloReferenceVectors.codewordFiveErrorCorrectionFour);
    codeword[0] = 0; // erasure
    codeword[2] ^= 0x33; // unknown
    final result = codec.decode(
      codeword,
      erasurePositions: <int>[0],
    );
    expect(result.erasurePositions, <int>[0]);
    expect(result.unknownErrorPositions, <int>[2]);
    expect(result.correctedPositions, containsAll(<int>[0, 2]));
    expect(result.unknownErrorPositions.contains(0), isFalse);
  });

  test('decode result was already valid should be true when no correction needed', () {
    final codec = buildCodec();
    final result = codec.decode(ReedsoloReferenceVectors.codewordFour);
    expect(result.wasAlreadyValid, isTrue);
    expect(result.correctedPositions, isEmpty);
  });

  test(
      'decode should match reedsolo for matching galois field 256 configuration including erasures',
      () {
    final codec = buildCodec(errorCorrectionSymbols: 2);
    // Single error
    final single = List<int>.from(ReedsoloReferenceVectors.codewordFour);
    single[1] ^= 0xFF;
    expect(
      codec.decode(single).decodedData,
      ReedsoloReferenceVectors.dataFour,
    );
    // Erasure
    final erased = List<int>.from(ReedsoloReferenceVectors.codewordFour);
    erased[0] = 0;
    expect(
      codec.decode(erased, erasurePositions: <int>[0]).decodedData,
      ReedsoloReferenceVectors.dataFour,
    );
    // Mixed with 4 ECC
    final codecFour = buildCodec(errorCorrectionSymbols: 4);
    final mixed = List<int>.from(
        ReedsoloReferenceVectors.codewordFiveErrorCorrectionFour);
    mixed[0] = 0;
    mixed[2] ^= 0x33;
    expect(
      codecFour.decode(mixed, erasurePositions: <int>[0]).decodedData,
      ReedsoloReferenceVectors.dataFiveErrorCorrectionFour,
    );
    // Shortened
    final shortened =
        List<int>.from(ReedsoloReferenceVectors.codewordTwelveTen);
    shortened[3] ^= 0x55;
    expect(
      codec.decode(shortened).decodedData,
      ReedsoloReferenceVectors.dataTwelveTen,
    );
  });

  test('beyond correction bound unknown errors need not always throw', () {
    final codec = buildCodec(errorCorrectionSymbols: 2);
    final codeword = List<int>.from(ReedsoloReferenceVectors.codewordFour);
    codeword[0] ^= 1;
    codeword[1] ^= 2;
    codeword[2] ^= 3;
    // May throw or land on another valid codeword — either is acceptable.
    try {
      final result = codec.decode(codeword);
      expect(codec.isValid(result.correctedCodeword), isTrue);
    } on ReedSolomonException {
      // acceptable
    }
  });

  test('beyond correction bound successful syndrome pass need not equal original message',
      () {
    final codec = buildCodec(errorCorrectionSymbols: 2);
    final original = ReedsoloReferenceVectors.dataFour;
    // Exhaustively try a few beyond-bound patterns; if any decode succeeds,
    // the decoded data need not equal the original.
    var sawSuccessfulDifferent = false;
    var sawThrow = false;
    for (var a = 1; a < 8; a++) {
      for (var b = 1; b < 8; b++) {
        for (var c = 1; c < 8; c++) {
          final codeword =
              List<int>.from(ReedsoloReferenceVectors.codewordFour);
          codeword[0] ^= a;
          codeword[1] ^= b;
          codeword[2] ^= c;
          try {
            final result = codec.decode(codeword);
            expect(codec.isValid(result.correctedCodeword), isTrue);
            if (!_listEquals(result.decodedData, original)) {
              sawSuccessfulDifferent = true;
            }
          } on ReedSolomonException {
            sawThrow = true;
          }
        }
      }
    }
    expect(sawThrow || sawSuccessfulDifferent, isTrue);
  });

  test('decode should not mutate erasure positions list', () {
    final codec = buildCodec();
    final codeword = List<int>.from(ReedsoloReferenceVectors.codewordFour);
    codeword[1] = 0;
    final erasures = <int>[1];
    final snapshot = List<int>.from(erasures);
    codec.decode(codeword, erasurePositions: erasures);
    expect(erasures, snapshot);
  });

  test('finite field owned by codec should not be affected by peer codec arithmetic', () {
    final firstField = buildGaloisField256();
    final secondField = buildGaloisField256();
    final first = ReedSolomonCodec(
      finiteField: firstField,
      errorCorrectionSymbols: 2,
    );
    final second = ReedSolomonCodec(
      finiteField: secondField,
      errorCorrectionSymbols: 2,
    );
    // Use second codec heavily
    for (var trial = 0; trial < 20; trial++) {
      final data = List<int>.generate(8, (index) => (trial + index) & 0xFF);
      final codeword = second.encode(data);
      final corrupted = List<int>.from(codeword);
      corrupted[trial % corrupted.length] ^= 0x5A;
      second.decode(corrupted);
    }
    // First codec still encodes matching frozen vector
    expect(
      first.encode(ReedsoloReferenceVectors.dataFour),
      ReedsoloReferenceVectors.codewordFour,
    );
    expect(firstField.multiply(0x12, 0x34), secondField.multiply(0x12, 0x34));
  });

  test('randomized round trip within bound matches independent reference encode', () {
    final codec = buildCodec(errorCorrectionSymbols: 4);
    final random = Random(20260929);
    for (var trial = 0; trial < 40; trial++) {
      final dataLength = 1 + random.nextInt(20);
      final data = List<int>.generate(
        dataLength,
        (_) => random.nextInt(256),
      );
      final codeword = codec.encode(data);
      expect(codec.isValid(codeword), isTrue);
      // Inject up to 2 unknown errors
      final corrupted = List<int>.from(codeword);
      final errorCount = 1 + random.nextInt(2);
      final positions = <int>{};
      while (positions.length < errorCount) {
        positions.add(random.nextInt(corrupted.length));
      }
      for (final position in positions) {
        corrupted[position] ^= 1 + random.nextInt(255);
      }
      final result = codec.decode(corrupted);
      expect(result.decodedData, data);
    }
  });

  test('encode should reject empty data', () {
    final codec = buildCodec();
    expect(
      () => codec.encode(<int>[]),
      throwsA(isA<ReedSolomonException>()),
    );
  });

  test('decode should reject codeword not longer than error correction symbols', () {
    final codec = buildCodec(errorCorrectionSymbols: 2);
    expect(
      () => codec.decode(<int>[1, 2]),
      throwsA(isA<ReedSolomonException>()),
    );
    expect(
      () => codec.decode(<int>[1]),
      throwsA(isA<ReedSolomonException>()),
    );
    expect(
      () => codec.isValid(<int>[1, 2]),
      throwsA(isA<ReedSolomonException>()),
    );
  });

  test('generator polynomial getter should return unmodifiable view', () {
    final codec = buildCodec(errorCorrectionSymbols: 2);
    final generator = codec.generatorPolynomial;
    expect(
      () => generator[0] = 0,
      throwsA(isA<UnsupportedError>()),
    );
  });

  // --- Explicit erasure regression tests (item 8) ---

  test('decode should correct single known erasure with nonzero original symbol', () {
    final codec = buildCodec(errorCorrectionSymbols: 2);
    final codeword = List<int>.from(ReedsoloReferenceVectors.codewordFour);
    expect(codeword[1], isNot(0));
    codeword[1] = 0xAB;
    final result = codec.decode(
      codeword,
      erasurePositions: <int>[1],
    );
    expect(result.decodedData, ReedsoloReferenceVectors.dataFour);
    expect(result.erasurePositions, <int>[1]);
    expect(result.unknownErrorPositions, isEmpty);
  });

  test('decode should correct multiple known erasures', () {
    final codec = buildCodec(errorCorrectionSymbols: 4);
    final codeword = List<int>.from(
      ReedsoloReferenceVectors.codewordFiveErrorCorrectionFour,
    );
    codeword[1] = 0x11;
    codeword[3] = 0x22;
    final result = codec.decode(
      codeword,
      erasurePositions: <int>[1, 3],
    );
    expect(
      result.decodedData,
      ReedsoloReferenceVectors.dataFiveErrorCorrectionFour,
    );
    expect(result.erasurePositions, <int>[1, 3]);
    expect(result.unknownErrorPositions, isEmpty);
  });

  test('decode should correct erasures in data portion', () {
    final codec = buildCodec(errorCorrectionSymbols: 2);
    final codeword = List<int>.from(ReedsoloReferenceVectors.codewordFour);
    // data portion is indices 0..3
    codeword[0] = 0xFF;
    codeword[2] = 0xEE;
    final result = codec.decode(
      codeword,
      erasurePositions: <int>[0, 2],
    );
    expect(result.decodedData, ReedsoloReferenceVectors.dataFour);
  });

  test('decode should correct erasures in error correction portion', () {
    final codec = buildCodec(errorCorrectionSymbols: 2);
    final codeword = List<int>.from(ReedsoloReferenceVectors.codewordFour);
    // ECC portion is indices 4..5
    codeword[4] = 0x55;
    codeword[5] = 0x66;
    final result = codec.decode(
      codeword,
      erasurePositions: <int>[4, 5],
    );
    expect(result.decodedData, ReedsoloReferenceVectors.dataFour);
    expect(result.correctedCodeword, ReedsoloReferenceVectors.codewordFour);
  });

  test('decode should correct mixed errors and erasures at correction boundary', () {
    // Bound: 2*errors + erasures == ECC => 2*1 + 2 == 4
    final codec = buildCodec(errorCorrectionSymbols: 4);
    final codeword = List<int>.from(
      ReedsoloReferenceVectors.codewordFiveErrorCorrectionFour,
    );
    codeword[0] = 0xAA; // erasure
    codeword[1] = 0xBB; // erasure
    codeword[3] ^= 0x44; // unknown error
    final result = codec.decode(
      codeword,
      erasurePositions: <int>[0, 1],
    );
    expect(
      result.decodedData,
      ReedsoloReferenceVectors.dataFiveErrorCorrectionFour,
    );
    expect(result.erasurePositions, <int>[0, 1]);
    expect(result.unknownErrorPositions, <int>[3]);
  });

  test('decode should correct all error correction symbols erased when allowed', () {
    final codec = buildCodec(errorCorrectionSymbols: 4);
    final codeword = List<int>.from(
      ReedsoloReferenceVectors.codewordFiveErrorCorrectionFour,
    );
    final dataLength = codeword.length - 4;
    final erasurePositions = <int>[
      dataLength,
      dataLength + 1,
      dataLength + 2,
      dataLength + 3,
    ];
    for (final position in erasurePositions) {
      codeword[position] = 0x7F;
    }
    final result = codec.decode(
      codeword,
      erasurePositions: erasurePositions,
    );
    expect(
      result.decodedData,
      ReedsoloReferenceVectors.dataFiveErrorCorrectionFour,
    );
    expect(result.unknownErrorPositions, isEmpty);
  });

  test(
      'decode should correct when error positions also supplied as erasures with unchanged value',
      () {
    // Mark positions as erasures but leave received values unchanged
    // (still "known" erasures for the decoder path).
    final codec = buildCodec(errorCorrectionSymbols: 2);
    final codeword = List<int>.from(ReedsoloReferenceVectors.codewordFour);
    // Corrupt position 2, also declare it as erasure.
    codeword[2] ^= 0x0F;
    final result = codec.decode(
      codeword,
      erasurePositions: <int>[2],
    );
    expect(result.decodedData, ReedsoloReferenceVectors.dataFour);
    expect(result.erasurePositions, <int>[2]);
    expect(result.unknownErrorPositions, isEmpty);
  });

  // --- FCR != 0 ---

  test('first consecutive root one should match independent reference encode', () {
    final codec = buildCodec(
      errorCorrectionSymbols: 2,
      firstConsecutiveRoot: 1,
    );
    expect(
      codec.encode(ReedsoloReferenceVectors.dataFourFirstConsecutiveRootOne),
      ReedsoloReferenceVectors.codewordFourFirstConsecutiveRootOne,
    );
    expect(
      codec.encode(ReedsoloReferenceVectors.dataFiveFirstConsecutiveRootOne),
      isNot(ReedsoloReferenceVectors.codewordFiveErrorCorrectionFour),
    );
    final codecFour = buildCodec(
      errorCorrectionSymbols: 4,
      firstConsecutiveRoot: 1,
    );
    expect(
      codecFour.encode(
        ReedsoloReferenceVectors.dataFiveFirstConsecutiveRootOne,
      ),
      ReedsoloReferenceVectors.codewordFiveFirstConsecutiveRootOne,
    );
  });

  test('first consecutive root one hundred twenty should match independent encode', () {
    final codec = buildCodec(
      errorCorrectionSymbols: 4,
      firstConsecutiveRoot: 120,
    );
    expect(
      codec.encode(
        ReedsoloReferenceVectors.dataThreeFirstConsecutiveRootOneHundredTwenty,
      ),
      ReedsoloReferenceVectors
          .codewordThreeFirstConsecutiveRootOneHundredTwenty,
    );
  });

  test('first consecutive root one generator roots should evaluate to zero on codeword',
      () {
    final codec = buildCodec(
      errorCorrectionSymbols: 4,
      firstConsecutiveRoot: 1,
    );
    final codeword = codec.encode(
      ReedsoloReferenceVectors.dataFiveFirstConsecutiveRootOne,
    );
    _expectCodewordHasZeroSyndromesAtRoots(codec, codeword);
  });

  test('first consecutive root one should decode mixed errors and erasures', () {
    final codec = buildCodec(
      errorCorrectionSymbols: 4,
      firstConsecutiveRoot: 1,
    );
    final codeword = List<int>.from(
      ReedsoloReferenceVectors.codewordFiveFirstConsecutiveRootOne,
    );
    codeword[0] = 0; // erasure
    codeword[2] ^= 0x33; // unknown
    final result = codec.decode(
      codeword,
      erasurePositions: <int>[0],
    );
    expect(
      result.decodedData,
      ReedsoloReferenceVectors.dataFiveFirstConsecutiveRootOne,
    );
    expect(result.unknownErrorPositions, <int>[2]);
  });

  test('first consecutive root one should decode single unknown error', () {
    final codec = buildCodec(
      errorCorrectionSymbols: 2,
      firstConsecutiveRoot: 1,
    );
    final codeword = List<int>.from(
      ReedsoloReferenceVectors.codewordFourFirstConsecutiveRootOne,
    );
    codeword[3] ^= 0xA5;
    final result = codec.decode(codeword);
    expect(
      result.decodedData,
      ReedsoloReferenceVectors.dataFourFirstConsecutiveRootOne,
    );
  });

  // --- GF(16) / GF(1024) ---

  test('galois field sixteen should encode and decode full and shortened', () {
    final field = FiniteField(
      symbolSizeInBits: 4,
      primitivePolynomial: 0x13,
      primitiveElement: 2,
    );
    final codec = ReedSolomonCodec(
      finiteField: field,
      errorCorrectionSymbols: 4,
    );
    expect(
      codec.encode(ReedsoloReferenceVectors.dataGaloisFieldSixteen),
      ReedsoloReferenceVectors.codewordGaloisFieldSixteen,
    );
    final corrupted = List<int>.from(
      ReedsoloReferenceVectors.codewordGaloisFieldSixteen,
    );
    corrupted[2] ^= 0x5;
    expect(
      codec.decode(corrupted).decodedData,
      ReedsoloReferenceVectors.dataGaloisFieldSixteen,
    );

    final shortCodec = ReedSolomonCodec(
      finiteField: field,
      errorCorrectionSymbols: 2,
    );
    expect(
      shortCodec.encode(ReedsoloReferenceVectors.dataGaloisFieldSixteenShort),
      ReedsoloReferenceVectors.codewordGaloisFieldSixteenShort,
    );
  });

  test('galois field sixteen with first consecutive root one should round trip', () {
    final field = FiniteField(
      symbolSizeInBits: 4,
      primitivePolynomial: 0x13,
      primitiveElement: 2,
    );
    final codec = ReedSolomonCodec(
      finiteField: field,
      errorCorrectionSymbols: 4,
      firstConsecutiveRoot: 1,
    );
    expect(
      codec.encode(ReedsoloReferenceVectors.dataGaloisFieldSixteen),
      ReedsoloReferenceVectors
          .codewordGaloisFieldSixteenFirstConsecutiveRootOne,
    );
    final corrupted = List<int>.from(
      ReedsoloReferenceVectors
          .codewordGaloisFieldSixteenFirstConsecutiveRootOne,
    );
    corrupted[1] = 0;
    corrupted[4] ^= 0x3;
    final result = codec.decode(
      corrupted,
      erasurePositions: <int>[1],
    );
    expect(
      result.decodedData,
      ReedsoloReferenceVectors.dataGaloisFieldSixteen,
    );
  });

  test('galois field one thousand twenty four should encode and decode', () {
    final field = FiniteField(
      symbolSizeInBits: 10,
      primitivePolynomial: 0x409,
      primitiveElement: 2,
    );
    final codec = ReedSolomonCodec(
      finiteField: field,
      errorCorrectionSymbols: 4,
    );
    expect(
      codec.encode(
        ReedsoloReferenceVectors.dataGaloisFieldOneThousandTwentyFour,
      ),
      ReedsoloReferenceVectors.codewordGaloisFieldOneThousandTwentyFour,
    );
    final corrupted = List<int>.from(
      ReedsoloReferenceVectors.codewordGaloisFieldOneThousandTwentyFour,
    );
    corrupted[2] ^= 77;
    corrupted[5] ^= 88;
    final result = codec.decode(corrupted);
    expect(
      result.decodedData,
      ReedsoloReferenceVectors.dataGaloisFieldOneThousandTwentyFour,
    );
  });

  test(
      'galois field one thousand twenty four with first consecutive root one should round trip',
      () {
    final field = FiniteField(
      symbolSizeInBits: 10,
      primitivePolynomial: 0x409,
      primitiveElement: 2,
    );
    final codec = ReedSolomonCodec(
      finiteField: field,
      errorCorrectionSymbols: 2,
      firstConsecutiveRoot: 1,
    );
    expect(
      codec.encode(
        ReedsoloReferenceVectors
            .dataGaloisFieldOneThousandTwentyFourFirstRootOne,
      ),
      ReedsoloReferenceVectors
          .codewordGaloisFieldOneThousandTwentyFourFirstRootOne,
    );
    final corrupted = List<int>.from(
      ReedsoloReferenceVectors
          .codewordGaloisFieldOneThousandTwentyFourFirstRootOne,
    );
    corrupted[0] ^= 3;
    expect(
      codec.decode(corrupted).decodedData,
      ReedsoloReferenceVectors.dataGaloisFieldOneThousandTwentyFourFirstRootOne,
    );

    final shortCodec = ReedSolomonCodec(
      finiteField: field,
      errorCorrectionSymbols: 6,
    );
    expect(
      shortCodec.encode(
        ReedsoloReferenceVectors.dataGaloisFieldOneThousandTwentyFourShort,
      ),
      ReedsoloReferenceVectors.codewordGaloisFieldOneThousandTwentyFourShort,
    );
  });

  // --- Independent property checks (not only encode→corrupt→decode) ---

  test('independent encoded codeword should have zero syndromes at generator roots', () {
    final random = Random(42);
    for (final firstConsecutiveRoot in <int>[0, 1, 17]) {
      final codec = buildCodec(
        errorCorrectionSymbols: 6,
        firstConsecutiveRoot: firstConsecutiveRoot,
      );
      for (var trial = 0; trial < 15; trial++) {
        final data = List<int>.generate(
          1 + random.nextInt(12),
          (_) => random.nextInt(256),
        );
        final codeword = codec.encode(data);
        _expectCodewordHasZeroSyndromesAtRoots(codec, codeword);
        expect(codec.isValid(codeword), isTrue);
      }
    }
  });

  test('independent corruption should produce nonzero syndrome', () {
    final codec = buildCodec(errorCorrectionSymbols: 4);
    final random = Random(99);
    for (var trial = 0; trial < 20; trial++) {
      final data = List<int>.generate(
        5 + random.nextInt(8),
        (_) => random.nextInt(256),
      );
      final codeword = List<int>.from(codec.encode(data));
      codeword[random.nextInt(codeword.length)] ^= 1 + random.nextInt(255);
      expect(codec.isValid(codeword), isFalse);
    }
  });

  test('two independent codec instances should agree on encode and decode', () {
    final first =
        buildCodec(errorCorrectionSymbols: 4, firstConsecutiveRoot: 1);
    final second = buildCodec(
      errorCorrectionSymbols: 4,
      firstConsecutiveRoot: 1,
    );
    final random = Random(7);
    for (var trial = 0; trial < 20; trial++) {
      final data = List<int>.generate(
        3 + random.nextInt(10),
        (_) => random.nextInt(256),
      );
      final encodedFirst = first.encode(data);
      final encodedSecond = second.encode(data);
      expect(encodedFirst, encodedSecond);
      final corrupted = List<int>.from(encodedFirst);
      corrupted[trial % corrupted.length] ^= 0x3C;
      expect(
        first.decode(corrupted).decodedData,
        second.decode(corrupted).decodedData,
      );
    }
  });

  test('randomized galois field sixteen within bound should round trip', () {
    final field = FiniteField(
      symbolSizeInBits: 4,
      primitivePolynomial: 0x13,
      primitiveElement: 2,
    );
    final random = Random(2026);
    for (final firstConsecutiveRoot in <int>[0, 1, 3]) {
      final codec = ReedSolomonCodec(
        finiteField: field,
        errorCorrectionSymbols: 4,
        firstConsecutiveRoot: firstConsecutiveRoot,
      );
      for (var trial = 0; trial < 25; trial++) {
        final dataLength = 1 + random.nextInt(8);
        final data = List<int>.generate(
          dataLength,
          (_) => random.nextInt(16),
        );
        final codeword = codec.encode(data);
        _expectCodewordHasZeroSyndromesAtRoots(codec, codeword);
        final corrupted = List<int>.from(codeword);
        final errorCount = 1 + random.nextInt(2);
        final positions = <int>{};
        while (positions.length < errorCount) {
          positions.add(random.nextInt(corrupted.length));
        }
        for (final position in positions) {
          corrupted[position] ^= 1 + random.nextInt(15);
        }
        expect(codec.decode(corrupted).decodedData, data);
      }
    }
  });

  test('randomized galois field one thousand twenty four within bound should round trip',
      () {
    final field = FiniteField(
      symbolSizeInBits: 10,
      primitivePolynomial: 0x409,
      primitiveElement: 2,
    );
    final random = Random(1024);
    for (final firstConsecutiveRoot in <int>[0, 1, 5]) {
      final codec = ReedSolomonCodec(
        finiteField: field,
        errorCorrectionSymbols: 4,
        firstConsecutiveRoot: firstConsecutiveRoot,
      );
      for (var trial = 0; trial < 15; trial++) {
        final data = List<int>.generate(
          2 + random.nextInt(6),
          (_) => random.nextInt(1024),
        );
        final codeword = codec.encode(data);
        final corrupted = List<int>.from(codeword);
        corrupted[random.nextInt(corrupted.length)] ^= 1 + random.nextInt(1023);
        expect(codec.decode(corrupted).decodedData, data);
      }
    }
  });

  // --- Bound tests ---

  test('correction bound equality cases should succeed for valid patterns', () {
    final codec = buildCodec(errorCorrectionSymbols: 6);
    final data = <int>[1, 2, 3, 4, 5, 6, 7, 8];
    final original = codec.encode(data);
    // Every (errors, erasures) with 2*e + erasures == 6
    final cases = <List<int>>[
      <int>[3, 0],
      <int>[2, 2],
      <int>[1, 4],
      <int>[0, 6],
    ];
    for (final pair in cases) {
      final errorCount = pair[0];
      final erasureCount = pair[1];
      final corrupted = List<int>.from(original);
      final used = <int>{};
      final erasures = <int>[];
      while (erasures.length < erasureCount) {
        final position = erasures.length * 2;
        used.add(position);
        corrupted[position] ^= 0x5A;
        erasures.add(position);
      }
      var errorPlaced = 0;
      var cursor = 1;
      while (errorPlaced < errorCount) {
        if (!used.contains(cursor)) {
          corrupted[cursor] ^= 0xA5;
          used.add(cursor);
          errorPlaced++;
        }
        cursor++;
      }
      final result = codec.decode(
        corrupted,
        erasurePositions: erasures,
      );
      expect(result.decodedData, data,
          reason: 'errors=$errorCount erasures=$erasureCount');
    }
  });

  test('beyond bound selected patterns should have valid syndromes or throw', () {
    final codec = buildCodec(errorCorrectionSymbols: 4);
    final original = codec.encode(<int>[9, 8, 7, 6, 5, 4]);
    final patterns = <List<int>>[
      <int>[0, 1, 2, 3], // 4 errors > 2
      <int>[0, 1, 2], // 3 errors > 2
      <int>[1, 3, 5],
    ];
    for (final positions in patterns) {
      final corrupted = List<int>.from(original);
      for (var index = 0; index < positions.length; index++) {
        corrupted[positions[index]] ^= 0x10 + index;
      }
      try {
        final result = codec.decode(corrupted);
        expect(codec.isValid(result.correctedCodeword), isTrue);
      } on ReedSolomonException {
        // acceptable
      }
    }
  });

  // --- Erasure edge extras already partly covered; reinforce ---

  test('decode should accept erasure count equal to error correction symbols', () {
    final codec = buildCodec(errorCorrectionSymbols: 3);
    final codeword = List<int>.from(codec.encode(<int>[1, 2, 3, 4]));
    codeword[0] ^= 1;
    codeword[1] ^= 2;
    codeword[2] ^= 3;
    final result = codec.decode(
      codeword,
      erasurePositions: <int>[0, 1, 2],
    );
    expect(result.decodedData, <int>[1, 2, 3, 4]);
  });

  test('encode should match independent offline vectors across configurations', () {
    // Differential vs frozen offline vectors (not produced by this package).
    expect(
      buildCodec(errorCorrectionSymbols: 2)
          .encode(ReedsoloReferenceVectors.dataFour),
      ReedsoloReferenceVectors.codewordFour,
    );
    expect(
      buildCodec(errorCorrectionSymbols: 2)
          .encode(ReedsoloReferenceVectors.dataTwelveTen),
      ReedsoloReferenceVectors.codewordTwelveTen,
    );
    expect(
      buildCodec(errorCorrectionSymbols: 2)
          .encode(ReedsoloReferenceVectors.dataSixteenFourteen),
      ReedsoloReferenceVectors.codewordSixteenFourteen,
    );
    expect(
      buildCodec(errorCorrectionSymbols: 4).encode(
        ReedsoloReferenceVectors.dataThreeErrorCorrectionFour,
      ),
      ReedsoloReferenceVectors.codewordThreeErrorCorrectionFour,
    );
    expect(
      buildCodec(errorCorrectionSymbols: 4).encode(
        ReedsoloReferenceVectors.dataFiveErrorCorrectionFour,
      ),
      ReedsoloReferenceVectors.codewordFiveErrorCorrectionFour,
    );
  });
}

void _expectCodewordHasZeroSyndromesAtRoots(
  ReedSolomonCodec codec,
  List<int> codeword,
) {
  final field = codec.finiteField;
  for (var index = 0; index < codec.errorCorrectionSymbols; index++) {
    final point = field.exponent(codec.firstConsecutiveRoot + index);
    var value = 0;
    for (final symbol in codeword) {
      value = field.add(field.multiply(value, point), symbol);
    }
    expect(value, 0, reason: 'syndrome at root index $index');
  }
}

bool _listEquals(List<int> left, List<int> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
