// ignore_for_file: constant_identifier_names

enum JoltType {
  HOME,
  BUSINESS,
}

JoltType getJoltType({String? model}) {
  if (model == "JOLTHOME") return JoltType.HOME;
  return JoltType.BUSINESS;
}

extension TypeJolt on JoltType {
  bool isJoltHome() {
    switch (this) {
      case JoltType.HOME:
        return true;
      case JoltType.BUSINESS:
        return false;
    }
  }

  bool isJoltBusiness() {
    switch (this) {
      case JoltType.HOME:
        return false;
      case JoltType.BUSINESS:
        return true;
    }
  }

  String toName() {
    switch (this) {
      case JoltType.HOME:
        return "Jolt Home";
      case JoltType.BUSINESS:
        return "Jolt";
    }
  }
}
