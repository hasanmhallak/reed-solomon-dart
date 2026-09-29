/// Frozen independent reference vectors for Reed-Solomon encode/decode tests.
///
/// GF(256) / poly 0x11D / primitive 2 / firstConsecutiveRoot 0 vectors match
/// reedsolo defaults and were cross-checked offline. Additional field and
/// firstConsecutiveRoot vectors were computed by an independent offline
/// encoder that uses only finite_field_math (not reed_solomon_codec).
class ReedsoloReferenceVectors {
  ReedsoloReferenceVectors._();

  static const int symbolSizeInBits = 8;
  static const int primitivePolynomial = 0x11D;
  static const int primitiveElement = 2;
  static const int firstConsecutiveRoot = 0;

  /// data [1,2,3,4], errorCorrectionSymbols = 2
  static const List<int> dataFour = <int>[1, 2, 3, 4];
  static const List<int> codewordFour = <int>[1, 2, 3, 4, 4, 0];

  /// shortened Reed-Solomon (12,10)
  static const List<int> dataTwelveTen = <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
  static const List<int> codewordTwelveTen = <int>[
    0,
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    115,
    114
  ];

  /// shortened Reed-Solomon (16,14)
  static const List<int> dataSixteenFourteen = <int>[
    0,
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13
  ];
  static const List<int> codewordSixteenFourteen = <int>[
    0,
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    240,
    241
  ];

  /// data [64,65,66], errorCorrectionSymbols = 4
  static const List<int> dataThreeErrorCorrectionFour = <int>[64, 65, 66];
  static const List<int> codewordThreeErrorCorrectionFour = <int>[
    64,
    65,
    66,
    225,
    131,
    11,
    42
  ];

  /// data [10,20,30,40,50], errorCorrectionSymbols = 4
  static const List<int> dataFiveErrorCorrectionFour = <int>[
    10,
    20,
    30,
    40,
    50
  ];
  static const List<int> codewordFiveErrorCorrectionFour = <int>[
    10,
    20,
    30,
    40,
    50,
    16,
    68,
    42,
    100
  ];

  // --- Independent offline vectors (finite_field_math only) ---

  /// GF(256), firstConsecutiveRoot = 1, errorCorrectionSymbols = 2
  static const List<int> dataFourFirstConsecutiveRootOne = <int>[1, 2, 3, 4];
  static const List<int> codewordFourFirstConsecutiveRootOne = <int>[
    1,
    2,
    3,
    4,
    33,
    74
  ];

  /// GF(256), firstConsecutiveRoot = 1, errorCorrectionSymbols = 4
  static const List<int> dataFiveFirstConsecutiveRootOne = <int>[
    10,
    20,
    30,
    40,
    50
  ];
  static const List<int> codewordFiveFirstConsecutiveRootOne = <int>[
    10,
    20,
    30,
    40,
    50,
    26,
    40,
    135,
    222
  ];

  /// GF(256), firstConsecutiveRoot = 120, errorCorrectionSymbols = 4
  static const List<int> dataThreeFirstConsecutiveRootOneHundredTwenty = <int>[
    7,
    8,
    9
  ];
  static const List<int> codewordThreeFirstConsecutiveRootOneHundredTwenty =
      <int>[7, 8, 9, 130, 11, 83, 61];

  /// GF(16) / poly 0x13 / primitive 2, firstConsecutiveRoot = 0, ecc = 4
  static const List<int> dataGaloisFieldSixteen = <int>[1, 2, 3, 4, 5];
  static const List<int> codewordGaloisFieldSixteen = <int>[
    1,
    2,
    3,
    4,
    5,
    6,
    11,
    0,
    12
  ];

  /// GF(16), firstConsecutiveRoot = 1, ecc = 4
  static const List<int> codewordGaloisFieldSixteenFirstConsecutiveRootOne =
      <int>[1, 2, 3, 4, 5, 4, 4, 9, 7];

  /// GF(16) shortened, ecc = 2
  static const List<int> dataGaloisFieldSixteenShort = <int>[9, 10];
  static const List<int> codewordGaloisFieldSixteenShort = <int>[9, 10, 7, 4];

  /// GF(1024) / poly 0x409 / primitive 2, firstConsecutiveRoot = 0, ecc = 4
  static const List<int> dataGaloisFieldOneThousandTwentyFour = <int>[
    1,
    2,
    3,
    4,
    5,
    6
  ];
  static const List<int> codewordGaloisFieldOneThousandTwentyFour = <int>[
    1,
    2,
    3,
    4,
    5,
    6,
    502,
    340,
    522,
    687
  ];

  /// GF(1024), firstConsecutiveRoot = 1, ecc = 2
  static const List<int> dataGaloisFieldOneThousandTwentyFourFirstRootOne =
      <int>[100, 200, 300];
  static const List<int> codewordGaloisFieldOneThousandTwentyFourFirstRootOne =
      <int>[100, 200, 300, 983, 798];

  /// GF(1024) shortened-ish, ecc = 6
  static const List<int> dataGaloisFieldOneThousandTwentyFourShort = <int>[
    11,
    22,
    33,
    44
  ];
  static const List<int> codewordGaloisFieldOneThousandTwentyFourShort = <int>[
    11,
    22,
    33,
    44,
    539,
    1008,
    325,
    38,
    249,
    97
  ];
}
