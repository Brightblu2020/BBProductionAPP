import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'rfid_hive_model.g.dart';

@HiveType(typeId: 3)
class RfidHiveModel {
  RfidHiveModel({
    required this.id,
    required this.name,
  });

  factory RfidHiveModel.fromJson({
    required String id,
  }) {
    try {
      return RfidHiveModel(
        id: id,
        name: "",
      );
    } catch (e) {
      debugPrint("---- hive model error ---- ${e.toString()}");
    }

    return RfidHiveModel(
      id: id,
      name: "",
    );
  }

  RfidHiveModel copyWith({
    String? id,
    String? name,
  }) {
    return RfidHiveModel(
      id: id ?? this.id,
      name: name ?? this.name,
      // startTime: startTime ?? this.startTime,
      // stopTime: stopTime ?? this.stopTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
    };
  }

  @HiveField(0)
  String id;

  @HiveField(1)
  String name;
}
