// ignore_for_file: constant_identifier_names

enum ChargerType {
  Jolt,
  JoltHome,
}

extension ToChargerType on ChargerType {
  String toChargerType() {
    switch (this) {
      case ChargerType.Jolt:
        return "JOLT";
      case ChargerType.JoltHome:
        return "JOLTHOME";
    }
  }
}

ChargerType getChargerType({String? value}) {
  if (value != null && value == "JOLT") {
    return ChargerType.Jolt;
  }
  return ChargerType.JoltHome;
}
