# Changelog

## 2.0.1

- Add `toJson`, `fromJson`, `toString` to ReedSolomonDecodeResult.

## 2.0.0

### Breaking changes

- Removed `ReedSolomonDecodingException`. Decoding failures, validation errors, and internal algebraic consistency failures now throw `ReedSolomonException`.

## 1.0.0

- Initial release of Reed-Solomon encoder/decoder with errors-and-erasures support.
