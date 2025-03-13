import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'transaction_hive_model.g.dart';

@HiveType(typeId: 1)
class TransactionHiveModel {
  TransactionHiveModel({
    required this.id,
    required this.timeStart,
    required this.timeStop,
    required this.meterValues,
    required this.idTag,
  });

  factory TransactionHiveModel.fromJson({required Map<String, dynamic> data}) {
    try {
      return TransactionHiveModel(
        id: (data['transactionId'] ?? 0) as int,
        timeStart: (data["timeStart"] ?? 0) as num,
        timeStop: (data["timeStop"] ?? 0) as num,
        meterValues: (data["meterValue"] ?? 0) as num,
        idTag: (data['idTag'] ?? "") as String,
      );
    } catch (e) {
      debugPrint("---- hive model error ---- ${e.toString()}");
    }
    return TransactionHiveModel(
      id: 0,
      timeStart: 0,
      timeStop: 0,
      meterValues: 0,
      idTag: "idTag",
    );
  }

  factory TransactionHiveModel.fromFirebase({
    required Map<String, dynamic> data,
    required String id,
  }) {
    try {
      return TransactionHiveModel(
        id: int.parse(id),
        timeStart: ((data["timeStart"] ?? 0) as num),
        timeStop: ((data["timeStop"] ?? 0) as num),
        meterValues: ((data["meterValue"] ?? 0) as num),
        idTag: (data['idTag'] ?? "") as String,
      );
    } catch (e) {
      debugPrint("---- hive firebase model error ---- ${e.toString()}");
    }
    return TransactionHiveModel(
      id: 0,
      timeStart: 0,
      timeStop: 0,
      meterValues: 0,
      idTag: "idTag",
    );
  }

  TransactionHiveModel copyWith({String? idTag}) {
    return TransactionHiveModel(
      id: id,
      timeStart: timeStart,
      timeStop: timeStop,
      meterValues: meterValues,
      idTag: idTag ?? this.idTag,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "transactionId": id,
      "timeStart": timeStart,
      "timeStop": timeStop,
      "meterValue": meterValues,
      "idTag": idTag,
    };
  }

  @HiveField(0)
  int id;

  @HiveField(1)
  num timeStart;

  @HiveField(2)
  num timeStop;

  @HiveField(3)
  num meterValues;

  @HiveField(4)
  String idTag;
}
