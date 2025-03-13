// ignore_for_file: constant_identifier_names

enum ESPFUNCTIONS {
  /// To manage boot notification message
  BOOT_NOTIFICATION,

BLE_LOGS,

  /// To manage status notification
  STATUS_NOTIFICATION,

  /// To manage change configration message
  CHANGE_CONFIGRATION,

  /// To manage get confirgration message
  GET_CONFIGRATION,

  /// To get trigger messages
  TRIGGER_MESSAGE,

  /// firmware update trigger
  FIRMWARE_UPDATE,

  /// Firmware update status Notification
  FIRMWARE_NOTIFICATION,

  /// Charger timer notification just for [BLE]
  CHARGER_TIMER,

  /// To fetch transactions from charger
  TRANSACTIONS_MESSAGE,

  DPMNOTIFICATION,
}

ESPFUNCTIONS getESPNotifications(String notification) {
  switch (notification) {
    case "BootNotification":
      return ESPFUNCTIONS.BOOT_NOTIFICATION;
    case "StatusNotification":
      return ESPFUNCTIONS.STATUS_NOTIFICATION;
    case "Logs":
      return ESPFUNCTIONS.BLE_LOGS;
    case "ChangeConfiguration":
      return ESPFUNCTIONS.CHANGE_CONFIGRATION;
    case "GetConfiguration":
      return ESPFUNCTIONS.GET_CONFIGRATION;
    case "TriggerMessage":
      return ESPFUNCTIONS.TRIGGER_MESSAGE;
    case "FirmwareUpdate":
      return ESPFUNCTIONS.FIRMWARE_UPDATE;
    case "FirmwareStatusNotification":
      return ESPFUNCTIONS.FIRMWARE_NOTIFICATION;
    case "chargerTimer":
      return ESPFUNCTIONS.CHARGER_TIMER;
    case "TransactionMessage":
      return ESPFUNCTIONS.TRANSACTIONS_MESSAGE;
    case "Notification":
      return ESPFUNCTIONS.STATUS_NOTIFICATION;
    case "dpmNotification":
      return ESPFUNCTIONS.DPMNOTIFICATION;
    default:
      return ESPFUNCTIONS.BOOT_NOTIFICATION;
  }
}

extension GetESPFunctions on ESPFUNCTIONS {
  String getConfigName() {
    switch (this) {
      case ESPFUNCTIONS.BOOT_NOTIFICATION:
        return "BootNotification";
      case ESPFUNCTIONS.CHANGE_CONFIGRATION:
        return "ChangeConfiguration";
      case ESPFUNCTIONS.GET_CONFIGRATION:
        return "GetConfiguration";
      case ESPFUNCTIONS.STATUS_NOTIFICATION:
        return "StatusNotification";
      case ESPFUNCTIONS.TRIGGER_MESSAGE:
        return "TriggerMessage";
      case ESPFUNCTIONS.FIRMWARE_UPDATE:
        return "FirmwareUpdate";
      case ESPFUNCTIONS.FIRMWARE_NOTIFICATION:
        return "FirmwareStatusNotification";
      case ESPFUNCTIONS.CHARGER_TIMER:
        return "chargerTimer";
      case ESPFUNCTIONS.TRANSACTIONS_MESSAGE:
        return "TransactionMessage";
      case ESPFUNCTIONS.DPMNOTIFICATION:
        return "dpmNotification";
      case ESPFUNCTIONS.BLE_LOGS:
        return 'Logs';
    }
  }
}
