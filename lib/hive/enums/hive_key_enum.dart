enum HiveKey {
  transaction,
  schedule,
  energyConsumed,
  lastTransaction,
  rfid,
  chargerNicknames,
  chargerList,
}

extension GetHiveKey on HiveKey {
  String getHiveKeys() {
    switch (this) {
      case HiveKey.transaction:
        return 'transactionBoxList';
      case HiveKey.schedule:
        return 'schedules';
      case HiveKey.energyConsumed:
        return 'energyConsumed';
      case HiveKey.lastTransaction:
        return 'lastTransaction';
      case HiveKey.rfid:
        return 'rfid';
      case HiveKey.chargerNicknames:
        return 'chargerNicknames';
      case HiveKey.chargerList:
        return 'chargerList';
    }
  }
}
