import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  TransactionModel({
    required this.transactionId,
    this.idTag,
    required this.chargerId,
    required this.createdAt,
    this.meterStart,
    this.meterStop,
    this.sessionInUse,
    this.updatedAt,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      "transactionId": transactionId,
      "idTag": idTag,
      "chargerId": chargerId,
      "createdAt": createdAt,
      "meterStart": meterStart,
      "meterStop": meterStop,
      "sessionInUse": sessionInUse,
      "updatedAt": updatedAt,
      "userId": userId
    };
  }

  /// id for the particular transaction or charging session
  final String transactionId;

  /// id of the charger
  final String chargerId;

  /// id of the user
  final String userId;

  /// meter start reading (Power)
  int? meterStart;

  /// meter stop reading (Power)
  int? meterStop;

  /// [Timestamp] for managing session creation time
  final Timestamp createdAt;

  /// [Timestamp] for managing session end time
  Timestamp? updatedAt;

  /// ID tag notififying logged in using RFID or App.
  String? idTag;

  /// Mainatin the current session
  bool? sessionInUse;
}
