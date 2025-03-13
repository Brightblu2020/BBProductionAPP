// import 'package:bb_factory_test_app/charger_module/enums/charger_status.dart';
// import 'package:bb_factory_test_app/charger_module/enums/connection_status.dart';
// import 'package:bb_factory_test_app/charger_module/utils/error_codes_enum.dart';
import 'package:bb_factory_test_app/utils/enums/charger_status.dart';
import 'package:bb_factory_test_app/utils/enums/connection_status.dart';
import 'package:bb_factory_test_app/utils/enums/error_codes_enum.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChargerRealTimeModel {
  ChargerRealTimeModel({
    this.currentL1,
    this.currentL2,
    this.currentL3,
    this.voltageL1,
    this.voltageL2,
    this.voltageL3,
    this.freemode,
    this.power,
    this.energy,
    this.chargerStatus,
    this.connectionStatus,
    required this.chargerId,
    this.start,
    this.maxCurrentLimit,
    this.initiateCharge,
    this.error,
    this.temperature,
    // this.chargeTime,
    this.energyStart,
  });

  factory ChargerRealTimeModel.fromBLE({
    required List<dynamic> json,
    required String chargerId,
  }) {
    final result = <String, dynamic>{};
    for (final map in json) {
      result.addIf(true, map['key'] as String, map['value']);
    }
    debugPrint("--- ble result ---- $result");
    return ChargerRealTimeModel.fromJson(
      data: result,
      chargerId: chargerId,
    );
  }

  factory ChargerRealTimeModel.fromJson({
    required Map<dynamic, dynamic> data,
    required String chargerId,
  }) {
    // if (isSinglePhase) {
    return ChargerRealTimeModel(
      chargerId: chargerId,
      voltageL1:
          (data['vL1'] != null) ? double.parse(data['vL1'] as String) : null,
      voltageL2:
          (data['vL2'] != null) ? double.parse(data['vL2'] as String) : null,
      voltageL3:
          (data['vL2'] != null) ? double.parse(data['vL2'] as String) : null,
      currentL1:
          (data['iL1'] != null) ? double.parse(data['iL1'] as String) : null,
      currentL2:
          (data['iL2'] != null) ? double.parse(data['iL2'] as String) : null,
      currentL3:
          (data['iL2'] != null) ? double.parse(data['iL2'] as String) : null,
      power: double.parse(
          (data['totalSystemOutputPower'] ?? data["Power"] ?? "0.0") as String),
      energy: double.parse((data['totalSystemOutputEnergy'] ??
          data["Energy"] ??
          "0.0") as String),
      energyStart: double.parse((data['totalSystemOutputEnergy'] ??
          data["Energy"] ??
          "0.0") as String),
      chargerStatus: chargerStatusFromString(
          (data['chargerStatus'] ?? data['Status'] ?? "") as String),
      connectionStatus: getConnectionStatus(data['connectionStatus']),
      initiateCharge: ((data['initiateCharge'] ?? 0) as int) == 1,
      freemode: ((data['freemode'].runtimeType == int)
          ? (data['freemode'] == 1 ? true : false)
          : (data['freemode'] ?? false) as bool),
      // chargeTime: ((data['chargingTimer'] ?? 0) as int),
      error: fromErrorCodes(code: (data["errorCode"] ?? "") as String),
      maxCurrentLimit: ((data['maxCurrentLimit'] ?? 0) as int),
      temperature: double.parse((data['temp'] ?? "0.0") as String),
    );
  }

  ChargerRealTimeModel copyWith({
    String? chargerId,
    ChargerStatus? chargerStatus,
    ConnectionStatus? connectionStatus,
    double? voltageL1,
    double? voltageL2,
    double? voltageL3,
    double? currentL1,
    double? currentL2,
    double? currentL3,
    double? power,
    double? energy,
    bool? initiateCharge,
    bool? freemode,
    int? maxCurrentLimit,
    int? chargeTime,
    ErrorCodes? error,
    double? temperature,
  }) {
    return ChargerRealTimeModel(
      chargerId: chargerId ?? this.chargerId,
      voltageL1: voltageL1 ?? this.voltageL1,
      voltageL2: voltageL2 ?? this.voltageL2,
      voltageL3: voltageL3 ?? this.voltageL3,
      currentL1: currentL1 ?? this.currentL1,
      currentL2: currentL2 ?? this.currentL2,
      currentL3: currentL3 ?? this.currentL3,
      power: power ?? this.power,
      energy: energy ?? this.energy,
      energyStart: energyStart,
      chargerStatus: chargerStatus ?? this.chargerStatus,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      initiateCharge: initiateCharge ?? this.initiateCharge,
      freemode: freemode ?? this.freemode,
      maxCurrentLimit: maxCurrentLimit ?? this.maxCurrentLimit,
      // chargeTime: chargeTime ?? this.chargeTime,
      error: error ?? this.error,
      // start: false,
      // maxCurrentLimit: int.parse(data['maxCurrentLimit'] as String),
    );
  }

  ChargerRealTimeModel updateWith({
    required Map<String, dynamic> data,
    bool? updateEnergyStart,
    bool? updateEnergyPower,
  }) {
    return ChargerRealTimeModel(
      chargerId: chargerId,
      voltageL1: (data['vL1'] != null)
          ? double.parse(data['vL1'] as String)
          : voltageL1,
      voltageL2: (data['vL2'] != null)
          ? double.parse(data['vL2'] as String)
          : voltageL2,
      voltageL3: (data['vL2'] != null)
          ? double.parse(data['vL3'] as String)
          : voltageL3,
      currentL1: (data['iL1'] != null)
          ? double.parse(data['iL1'] as String)
          : currentL1,
      currentL2: (data['iL2'] != null)
          ? double.parse(data['iL2'] as String)
          : currentL2,
      currentL3: (data['iL2'] != null)
          ? double.parse(data['iL3'] as String)
          : currentL3,
      power: (data['totalSystemOutputPower'] != null ||
              (updateEnergyPower != null && !updateEnergyPower))
          ? double.parse(
              (data['totalSystemOutputPower'] ?? data["Power"]) as String)
          : power,
      energy: (data['totalSystemOutputEnergy'] != null ||
              (updateEnergyPower != null && !updateEnergyPower))
          ? double.parse(
              (data['totalSystemOutputEnergy']) ?? data["Energy"] as String)
          : energy,
      energyStart:
          (data['totalSystemOutputEnergy'] != null && updateEnergyStart != null)
              ? double.parse(
                  (data['totalSystemOutputEnergy'] ?? data["Energy"]) as String)
              : energyStart,
      chargerStatus: chargerStatusFromString(
          (data['chargerStatus'] ?? data['Status'] ?? "") as String),
      connectionStatus: getConnectionStatus(data['connectionStatus']),
      initiateCharge: ((data['initiateCharge'] ?? 0) as int) == 1,
      freemode: ((data['freemode'].runtimeType == int)
          ? (data['freemode'] == 1 ? true : false)
          : (data['freemode'] ?? false) as bool),

      // chargeTime: ((data['chargingTimer'] ?? 0) as int),
      error: fromErrorCodes(code: (data["errorCode"] ?? "") as String),
      maxCurrentLimit: ((data['maxCurrentLimit'] ?? 0) as int),
      temperature:
          temperature ?? double.parse((data['temp'] ?? "0.0") as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "iL1": currentL1,
      "iL2": currentL2,
      "iL3": currentL3,
      "start": start,
      "vL1": voltageL1,
      "vL2": voltageL2,
      "vL3": voltageL3,
      "power": power,
      "energy": energy,
      "chargerStatus": (chargerStatus as ChargerStatus).tomycode(),
      "connectionStatus": (connectionStatus as ConnectionStatus).tomycode(),
      "freemode": freemode,
      "maxCurrentLimit": maxCurrentLimit,
      "initiateCharge": initiateCharge,
      "errorCode": error,
      // "chargingTimer": chargeTime,
      // "chargerId": chargerId,
    };
  }

  /// Id of the charger
  final String chargerId;

  /// start/stop to start or stop charger
  bool? start;

  /// Current in Line 1 of a operating charger
  double? currentL1;

  /// Current in Line 2 of a operating charger
  double? currentL2;

  /// Current in Line 3 of a operating charger
  double? currentL3;

  /// Voltage in Line 1 of a operating charger
  double? voltageL1;

  /// Voltage in Line 2 of a operating charger
  double? voltageL2;

  /// Voltage in Line 3 of a operating charger
  double? voltageL3;

  /// Power of a operating charger
  double? power;

  /// Energy delivered by charger
  double? energy;

  /// Energy start value
  double? energyStart;

  /// Temperature of charger
  double? temperature;

  /// Charger status of the charger
  ChargerStatus? chargerStatus;

  /// Current Connection status of charger
  ConnectionStatus? connectionStatus;

  /// [true] = Plug-in-play enabled, [false] = Plug-in-play disabled
  bool? freemode;

  /// Current limit set by user for charger.
  int? maxCurrentLimit;

  /// Initaing the charger
  bool? initiateCharge;

  /// To store the error state of the charger and provide customer the error code with string
  ErrorCodes? error;

  // /// To update the charger timer
  // int? chargeTime;
}
