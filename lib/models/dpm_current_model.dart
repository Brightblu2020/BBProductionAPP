class DpmCurrentModel {
  DpmCurrentModel({
    required this.il1,
    required this.il2,
    required this.il3,
    required this.ilMax,
    required this.iLAvl,
  });

  factory DpmCurrentModel.fromJson({required Map<String, dynamic> map}) {
    return DpmCurrentModel(
      il1: (map['iL1'] ?? "0") as String,
      il2: (map['iL2'] ?? "0") as String,
      il3: (map['iL3'] ?? "0") as String,
      ilMax: (map['iLmax'] ?? "0") as String,
      iLAvl: _avlCurrent(map: map),
    );
  }

  // DpmCurrentModel copyWith(
  //     {String? il1, String? il2, String? il3, String? ilMax}) {
  //   return DpmCurrentModel(
  //     il1: il1 ?? this.il1,
  //     il2: il2 ?? this.il2,
  //     il3: il3 ?? this.il3,
  //     ilMax: ilMax ?? this.ilMax,
  //     il
  //   );
  // }

  final String il1;
  final String il2;
  final String il3;
  final String ilMax;
  final String iLAvl;
}

String _avlCurrent({required Map<String, dynamic> map}) {
  final ilMax = int.parse((map['iLmax'] ?? "0") as String);
  if (ilMax == 0) {
    return "0";
  }
  final list = [
    int.parse((map['iL1'] ?? "0") as String),
    int.parse((map['iL2'] ?? "0") as String),
    int.parse((map['iL3'] ?? "0") as String),
  ];

  list.sort();
  return "${ilMax - list[2]}";
}
