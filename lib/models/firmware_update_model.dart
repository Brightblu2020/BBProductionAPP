class FirmwareUpdateModel {
  FirmwareUpdateModel({
    required this.percentageCompleted,
    required this.timeElapsed,
    required this.errorStatus,
    required this.errorReason,
  });

  // factory FirmwareUpdateModel.fromJson({required Map<String, dynamic> json}) {
  //   return FirmwareUpdateModel(
  //     percentageCompleted: int.parse(json['otaProgress'] ?? "0"),
  //     timeElapsed: int.parse(json['otaElapsedTime'] ?? "0"),
  //   );
  // }

  FirmwareUpdateModel copyWith({
    int? percentageCompleted,
    int? timeElapsed,
    bool? errorStatus,
    String? errorReason,
  }) {
    return FirmwareUpdateModel(
      percentageCompleted: percentageCompleted ?? this.percentageCompleted,
      timeElapsed: timeElapsed ?? this.timeElapsed,
      errorStatus: errorStatus ?? this.errorStatus,
      errorReason: errorReason ?? this.errorReason,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "percentageCompleted": percentageCompleted,
      "timeElapsed": timeElapsed,
    };
  }

  int percentageCompleted;
  int timeElapsed;
  bool errorStatus;
  String errorReason;
}
