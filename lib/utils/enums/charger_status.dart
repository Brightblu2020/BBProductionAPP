// ignore_for_file: constant_identifier_names

/// Maintain charge status for the user
enum ChargerStatus {
  /// Charger available for charging
  AVAILABLE,

  /// Charger not available for charging
  UNAVAILABLE,

  /// Preparing to charge
  PREPARING,

  /// Charging currently
  CHARGING,

  /// Car does not require any more power
  SUSPENDED_EV,

  /// Charger cannot provide any more power
  SUSPENDED_EVSE,

  /// Transaction between charger & car
  FINISHING,

  /// Charger goes into an error state
  ERROR,
}

extension ChargerStatusToString on ChargerStatus {
  String tomycode() {
    switch (this) {
      case ChargerStatus.AVAILABLE:
        return "Available";
      case ChargerStatus.PREPARING:
        return "Preparing";
      case ChargerStatus.CHARGING:
        return "Charging";
      case ChargerStatus.SUSPENDED_EV:
        return "SuspendedEV";
      case ChargerStatus.SUSPENDED_EVSE:
        return "SuspendedEVSE";
      case ChargerStatus.UNAVAILABLE:
        return "Unavailable";
      case ChargerStatus.FINISHING:
        return "Finishing";
      case ChargerStatus.ERROR:
        return "Error";
    }
  }
}

ChargerStatus chargerStatusFromString(String status) {
  switch (status) {
    case "Available":
      return ChargerStatus.AVAILABLE;
    case "Unavailable":
      return ChargerStatus.UNAVAILABLE;
    case "Preparing":
      return ChargerStatus.PREPARING;
    case "Charging":
      return ChargerStatus.CHARGING;
    case "Finishing":
      return ChargerStatus.FINISHING;
    case "SuspendedEV":
      return ChargerStatus.SUSPENDED_EV;
    case "SuspendedEVSE":
      return ChargerStatus.SUSPENDED_EVSE;
    case "Faulted":
      return ChargerStatus.ERROR;
    default:
      return ChargerStatus.UNAVAILABLE;
  }
}
