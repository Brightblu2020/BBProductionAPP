import 'package:bb_factory_test_app/utils/enums/charger_errors.dart';
import 'package:bb_factory_test_app/utils/enums/charger_status.dart';
import 'package:bb_factory_test_app/utils/enums/jolt_type.dart';
import 'package:bb_factory_test_app/utils/enums/network_type.dart';

class ChargerModel {
  ChargerModel({
    required this.chargerId,
    this.connector,
    this.phase,
    this.firmware,
    required this.serverUrl,
    this.status,
    this.voltage,
    this.current,
    this.chargeBoxFimrware,
    this.maxCurrentLimit,
    this.newChargerId,
    this.energy,
    this.power,
    this.error,
    this.sdCardStatus,
    required this.networkType,
    required this.simType,
    this.joltType,
    required this.freemode,
    this.totp
    // required this.remoteId,
  });

  /// get data from Bluetooth
  factory ChargerModel.fromBLE({
    required String chargerId,
    String? phase,
    double? connector,
    String? firmware,
    String? joltType,
  }) {
    return ChargerModel(
      serverUrl: "",
      chargerId: chargerId,
      connector: connector ?? 0.0,
      phase: phase ?? "Single",
      firmware: firmware ?? "",
      networkType: NetworkType.WiFi,
      simType: SimType.NONE,
      joltType: getJoltType(model: joltType),
      freemode: false,
    );
  }

  final String? chargeBoxFimrware;
  final String chargerId;
  final double? connector;
  final String? current;
  final String? energy;
  final ChargerError? error;
  final String? firmware;
  final String? maxCurrentLimit;
  final NetworkType networkType;
  final String? newChargerId;
  final String? phase;
  final String? power;
  final bool? sdCardStatus;
  final String serverUrl;
  final SimType simType;
  final ChargerStatus? status;
  final String? voltage;
  final JoltType? joltType;
  final bool freemode;
  final String? totp;

  ChargerModel copyWith({
    String? serverUrl,
    String? newChargerId,
    String? status,
    String? v1,
    String? v2,
    String? v3,
    String? i1,
    String? i2,
    String? i3,
    String? maxCurrentLimit,
    String? chargeboxFirmware,
    String? energy,
    String? power,
    String? error,
    bool? sdCardStatus,
    NetworkType? networkType,
    SimType? simType,
    String? joltType,
    bool? freemode,
    String? totp
  }) {
    return ChargerModel(
      chargerId: chargerId,
      serverUrl: serverUrl ?? this.serverUrl,
      connector: connector,
      phase: phase,
      status: (status != null) ? chargerStatusFromString(status) : this.status,
      firmware: firmware,
      voltage: "$v1:$v2:$v3",
      current: "$i1:$i2:$i3",
      maxCurrentLimit: maxCurrentLimit ?? this.maxCurrentLimit,
      newChargerId: newChargerId ?? this.newChargerId,
      chargeBoxFimrware: chargeboxFirmware ?? chargeBoxFimrware,
      energy: energy ?? this.energy,
      power: power ?? this.power,
      error: (error != null) ? getChargerError(code: error) : this.error,
      sdCardStatus: sdCardStatus ?? this.sdCardStatus,
      networkType: networkType ?? this.networkType,
      simType: simType ?? this.simType,
      joltType:
          (joltType != null) ? getJoltType(model: joltType) : this.joltType,
      freemode: freemode ?? this.freemode,
      totp: totp
      // remoteId: remoteId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "chargerId": chargerId,
      "phase": phase,
      "connector": connector,
      "firmware": firmware,
    };
  }
}
