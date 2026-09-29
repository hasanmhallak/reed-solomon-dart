# reed_solomon_codec

Pure Dart Reed-Solomon encoder/decoder over GF(2^m), with full errors-and-erasures decoding.

## Usage

```dart
import 'package:reed_solomon_codec/reed_solomon_codec.dart';

final codec = ReedSolomonCodec.fromFieldParameters(
  symbolSizeInBits: 8,
  primitivePolynomial: 0x11D,
  primitiveElement: 2,
  errorCorrectionSymbols: 2,
);

final codeword = codec.encode([1, 2, 3, 4]);
final result = codec.decode(codeword);
```

## License

MIT — Copyright (c) 2026 Hasan M. Hallak
