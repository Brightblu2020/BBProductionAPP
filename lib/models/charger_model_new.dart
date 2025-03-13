import 'package:bb_factory_test_app/utils/enums/charger_type.dart';
import 'package:bb_factory_test_app/models/charger_realitime_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// extension UpdateChargerModel on ChargerModel{
//   ChargerModel updateModel(String name){
//     return ChargerModel(chargerId: chargerId, userId: userId,chargerName: name,connector: co)
//   }
// }
class ChargerModel {
  ChargerModel({
    required this.chargerId,
    this.chargerName,
    required this.userId,
    this.connector,
    this.phase,
    this.firmware,
    this.lastUsed,
    this.chargerType,
    this.chargerRealTimeModel,
    // required this.remoteId,
  });

  /// get data from Bluetooth
  factory ChargerModel.fromBLE({
    required String chargerId,
    required String remoteId,
    required String userId,
    String? phase,
    var connector,
    String? chargerName,
    String? firmware,
    String? chargerType,
  }) {
    debugPrint(" ----- getting Charger data");
    return ChargerModel(
      chargerId: chargerId,
      userId: userId,
      chargerName: chargerName ?? "",
      connector: connector,
      phase: phase ?? "Single",
      firmware: firmware ?? "",
      chargerType: getChargerType(value: chargerType),
      // remoteId: remoteId,
    );
  }

  /// Get data from [FirebaseFirestore] database
  factory ChargerModel.fromFirebase({required QueryDocumentSnapshot snapshot}) {
    final data = snapshot.data() as Map<String, dynamic>;
    debugPrint("---- data ---- $data");
    final value = ChargerModel(
      chargerId: data['chargerId'] as String,
      // remoteId: (Platform.isAndroid)
      //     ? ((data['remoteIdAndroid']) as String)
      //     : ((data['remoteIdIos']) as String),
      userId: data['userId'],
      connector: data['connector'],
      phase: data['phase'],
      chargerName: data['chargerName'],
      firmware: data['firmware'],
      lastUsed: data['lastUsed'],
      chargerType: getChargerType(value: data['chargerType']),
    );
    debugPrint("---- charger model --- ${value.userId}");
    return value;
  }

  ChargerModel copyWith({
    ChargerRealTimeModel? chargerRealTimeModel,
    bool? lastUsed,
    String? chargerName,
  }) {
    return ChargerModel(
      chargerId: chargerId,
      userId: userId,
      chargerName: chargerName ?? this.chargerName,
      chargerRealTimeModel: chargerRealTimeModel ?? this.chargerRealTimeModel,
      connector: connector,
      phase: phase,
      lastUsed: lastUsed ?? this.lastUsed,
      firmware: firmware,
      chargerType: chargerType,
      // remoteId: remoteId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "chargerId": chargerId,
      "chargerName": chargerName,
      "userId": userId,
      "phase": phase,
      "connector": connector,
      "firmware": firmware,
      // "remoteIdAndroid": (Platform.isAndroid) ? remoteId : "",
      // "remoteIdIos": (Platform.isIOS) ? remoteId : "",
      "lastUsed": lastUsed,
      "chargerType": (chargerType != null) ? chargerType!.toChargerType() : "",
    };
  }

  /// charger id [Primary Key]
  final String chargerId;

  /// User Id of registered user [Foreign Key]
  final String userId;

  /// Charger name/Nickname given by user
  String? chargerName;

  /// Phase at which charger operates
  String? phase;

  /// Number of connectors to charger
  var connector;

  /// firmware id of the the current charger
  String? firmware;

  /// Latest usage of charger
  bool? lastUsed;

  ChargerType? chargerType;

  // String remoteId;

  /// [ChargerRealTimeModel] to keep a track of all real time [FirebaseDatabase] changes
  ChargerRealTimeModel? chargerRealTimeModel;
}
