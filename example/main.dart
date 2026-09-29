import 'package:reed_solomon_codec/reed_solomon_codec.dart';

void main() {
  final codec = ReedSolomonCodec.fromFieldParameters(
    symbolSizeInBits: 8,
    primitivePolynomial: 0x11D,
    primitiveElement: 2,
    errorCorrectionSymbols: 2,
  );

  const message = <int>[1, 2, 3, 4];
  final codeword = codec.encode(message);

  print('Message:  $message');
  print('Codeword: $codeword (${codeword.length} symbols)');

  final clean = codec.decode(codeword);
  print(
    'Decode (clean): ${clean.decodedData}, '
    'wasAlreadyValid=${clean.wasAlreadyValid}',
  );

  final corrupted = List<int>.from(codeword);
  corrupted[1] ^= 0xFF;
  print('After flipping bits at index 1: isValid=${codec.isValid(corrupted)}');

  final recovered = codec.decode(corrupted);
  print('Decode (1 unknown error): ${recovered.decodedData}');
  print('Corrected positions: ${recovered.unknownErrorPositions}');

  final erased = List<int>.from(codeword);
  erased[0] = 0;
  final fromErasure = codec.decode(
    erased,
    erasurePositions: <int>[0],
  );
  print('Decode (1 known erasure at 0): ${fromErasure.decodedData}');
}
