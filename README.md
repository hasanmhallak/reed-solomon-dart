# reed_solomon_codec

Pure Dart Reed-Solomon encoder/decoder over GF(2^m), with full errors-and-erasures decoding.

## Usage

```dart
import 'package:finite_field_math/finite_field_math.dart';
import 'package:reed_solomon_codec/reed_solomon_codec.dart';

final finiteField = FiniteField(
  symbolSizeInBits: 8,
  primitivePolynomial: 0x11D,
  primitiveElement: 2,
);

final reedSolomonCodec = ReedSolomonCodec(
  finiteField: finiteField,
  errorCorrectionSymbols: 2,
  // firstConsecutiveRoot defaults to 0 (reedsolo-compatible)
);

final codeword = reedSolomonCodec.encode([1, 2, 3, 4]);
final result = reedSolomonCodec.decode(codeword);
```

## License

MIT — Copyright (c) 2026 Hasan M. Hallak
