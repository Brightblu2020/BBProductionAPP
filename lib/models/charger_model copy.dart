import '../utils/constants_copy.dart';

class ChargerModel {
  final String firmwareVersion;
  final String model;
  final String phase;
  final int connectors;
  final String chargerType;

  ChargerModel({
    required this.firmwareVersion,
    required this.model,
    this.phase = 'Unknown',
    this.connectors = 0,
    required this.chargerType,
  });

  factory ChargerModel.fromBootResponse(Map<String, dynamic> data) {
    final String firmware = data['chargePointFirmwareVersion'] ?? 'Unknown';
    String chargerType = 'Unknown';

    if (firmware.startsWith(AppConstants.JOLT_BUSINESS_PREFIX_1) ||
        firmware.startsWith(AppConstants.JOLT_BUSINESS_PREFIX_2)) {
      chargerType = AppConstants.TYPE_BUSINESS;
    } else if (firmware.startsWith(AppConstants.JOLT_HOME_PLUS_PREFIX_1) ||
        firmware.startsWith(AppConstants.JOLT_HOME_PLUS_PREFIX_2)) {
      chargerType = AppConstants.TYPE_HOME_PLUS;
    } else if (firmware.startsWith(AppConstants.JOLT_HOME_PREFIX)) {
      chargerType = AppConstants.TYPE_HOME;
    }

    return ChargerModel(
      firmwareVersion: firmware,
      model: data['chargePointModel'] ?? 'Unknown',
      phase: data['phase'] ?? 'Unknown',
      connectors: data['connectors'] ?? 0,
      chargerType: chargerType,
    );
  }

  bool get isBusinessModel => chargerType == AppConstants.TYPE_BUSINESS;
  bool get isHomePlusModel => chargerType == AppConstants.TYPE_HOME_PLUS;
  bool get isHomeModel => chargerType == AppConstants.TYPE_HOME;

  bool get isSinglePhase => phase == AppConstants.SINGLE_PHASE;
  bool get isThreePhase => phase == AppConstants.THREE_PHASE;

  String get powerRating =>
      isSinglePhase ? AppConstants.POWER_7KW : AppConstants.POWER_22KW;
}
