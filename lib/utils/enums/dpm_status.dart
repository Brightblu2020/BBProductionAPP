// ignore_for_file: constant_identifier_names

enum DpmStatus {
  ON,
  OFF,
}

extension DpmUtility on DpmStatus {
  String name() {
    switch (this) {
      case DpmStatus.ON:
        return "DPMON";
      case DpmStatus.OFF:
        return "DPMOFF";
    }
  }
}
