class AppConstants {
  // UUIDs for BRIGHTBLU chargers
  static const String SERVICE_UUID_1 = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
  static const String CHARACTERISTIC_UUID_RX_1 =
      "6E400002-B5A3-F393-E0A9-E50E24DCCA9E";
  static const String CHARACTERISTIC_UUID_TX_1 =
      "6E400003-B5A3-F393-E0A9-E50E24DCCA9E";

  static const String SERVICE_UUID_2 = "fb1e4001-54ae-4a28-9f74-dfccb248601d";
  static const String CHARACTERISTIC_UUID_RX_2 =
      "fb1e4002-54ae-4a28-9f74-dfccb248601d";
  static const String CHARACTERISTIC_UUID_TX_2 =
      "fb1e4003-54ae-4a28-9f74-dfccb248601d";

  // Charger model identifiers
  static const String JOLT_BUSINESS_PREFIX_1 = "4.0.";
  static const String JOLT_BUSINESS_PREFIX_2 = "5.0.";
  static const String JOLT_HOME_PLUS_PREFIX_1 = "4.1.";
  static const String JOLT_HOME_PLUS_PREFIX_2 = "5.1.";
  static const String JOLT_HOME_PREFIX = "BBJLv1.0.";

  // App version for boot notification
  static const String APP_VERSION = "JOLTINSTALLPARTNER";

  // Charger types
  static const String TYPE_BUSINESS = "JOLT Business";
  static const String TYPE_HOME_PLUS = "JOLT Home Plus";
  static const String TYPE_HOME = "JOLT Home";

  // Phase types
  static const String SINGLE_PHASE = "Single.Phase";
  static const String THREE_PHASE = "Three.Phase";

  // Power ratings
  static const String POWER_7KW = "7kW";
  static const String POWER_22KW = "22kW";
}
