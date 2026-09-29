import 'package:finite_field_math/finite_field_math.dart';

/// Internal polynomial helpers (highest-degree coefficient first unless noted).
class PolynomialArithmetic {
  PolynomialArithmetic._();

  /// Evaluates [polynomial] (highest-degree first) at [point].
  static int evaluate(
    FiniteField finiteField,
    List<int> polynomial,
    int point,
  ) {
    var result = 0;
    for (final coefficient in polynomial) {
      result = finiteField.add(
        finiteField.multiply(result, point),
        coefficient,
      );
    }
    return result;
  }

  /// Multiplies two highest-degree-first polynomials.
  static List<int> multiply(
    FiniteField finiteField,
    List<int> left,
    List<int> right,
  ) {
    if (left.isEmpty || right.isEmpty) {
      return <int>[0];
    }
    final product = List<int>.filled(left.length + right.length - 1, 0);
    for (var leftIndex = 0; leftIndex < left.length; leftIndex++) {
      for (var rightIndex = 0; rightIndex < right.length; rightIndex++) {
        product[leftIndex + rightIndex] = finiteField.add(
          product[leftIndex + rightIndex],
          finiteField.multiply(left[leftIndex], right[rightIndex]),
        );
      }
    }
    return product;
  }

  /// Multiplies two lowest-degree-first polynomials.
  static List<int> multiplyLowestFirst(
    FiniteField finiteField,
    List<int> left,
    List<int> right,
  ) {
    return multiply(finiteField, left, right);
  }

  /// Adds two lowest-degree-first polynomials.
  static List<int> addLowestFirst(
    FiniteField finiteField,
    List<int> left,
    List<int> right,
  ) {
    final length = left.length > right.length ? left.length : right.length;
    final sum = List<int>.filled(length, 0);
    for (var index = 0; index < left.length; index++) {
      sum[index] = left[index];
    }
    for (var index = 0; index < right.length; index++) {
      sum[index] = finiteField.add(sum[index], right[index]);
    }
    return sum;
  }

  /// Scales a lowest-degree-first polynomial by [scalar].
  static List<int> scaleLowestFirst(
    FiniteField finiteField,
    List<int> polynomial,
    int scalar,
  ) {
    return polynomial
        .map((coefficient) => finiteField.multiply(coefficient, scalar))
        .toList();
  }

  /// Drops leading zeros from a highest-degree-first polynomial.
  static List<int> trimLeadingZeros(List<int> polynomial) {
    if (polynomial.isEmpty) {
      return <int>[0];
    }
    var start = 0;
    while (start < polynomial.length - 1 && polynomial[start] == 0) {
      start++;
    }
    return polynomial.sublist(start);
  }
}
