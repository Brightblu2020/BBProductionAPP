// ignore_for_file: constant_identifier_names

/// Maintains connection status of charger
enum ConnectionStatus {
  /// Charger is online and connected to Wifi
  ONLINE,

  /// Charger is offline and charger can communicate via BLE
  OFFLINE,
}

ConnectionStatus getConnectionStatus(dynamic value) {
  switch (value) {
    case true:
      return ConnectionStatus.ONLINE;
    case false:
      return ConnectionStatus.OFFLINE;
    case 1:
      return ConnectionStatus.ONLINE;
    case 0:
      return ConnectionStatus.OFFLINE;
    default:
      return ConnectionStatus.OFFLINE;
  }
}

extension ConnectionStatusToString on ConnectionStatus {
  int tomycode() {
    switch (this) {
      case ConnectionStatus.ONLINE:
        return 1;
      case ConnectionStatus.OFFLINE:
        return 0;
    }
  }

  String toName() {
    switch (this) {
      case ConnectionStatus.ONLINE:
        return "Online";
      case ConnectionStatus.OFFLINE:
        return "Offline";
    }
  }
}
