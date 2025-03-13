enum SetupState {
  CHARGER,
  WIFI,
  RFID,
}

extension Name on SetupState {
  String toName() {
    switch (this) {
      case SetupState.CHARGER:
        return "Chargers";
      case SetupState.WIFI:
        return "Wifi networks";
      case SetupState.RFID:
        return "RFID's";
    }
  }
}
