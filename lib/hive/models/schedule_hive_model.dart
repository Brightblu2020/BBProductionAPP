import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'schedule_hive_model.g.dart';

@HiveType(typeId: 2)
class ScheduleHiveModel {
  ScheduleHiveModel({
    required this.id,
    required this.timeStart,
    required this.timeStop,
    required this.duration,
    required this.days,
    required this.active,
    required this.type,
    // this.startTime,
    // this.stopTime,
  });

  factory ScheduleHiveModel.fromJson({
    required Map<String, dynamic> data,
    required String id,
    // required int type,
  }) {
    try {
      return ScheduleHiveModel(
        id: "${(data["timeStart"] ?? 0)}${data["timeStop"] ?? 0}${data["duration"] ?? 0}",
        timeStart: (data["timeStart"] ?? 0) as int,
        timeStop: (data["timeStart"] != null)
            ? (data['timeStart'] as int) + (data["duration"] as int)
            : 0,
        duration: (data["duration"] ?? 0) as int,
        days: ((data['days'] ?? [1, 1, 1, 1, 1, 1, 1]) as List<dynamic>)
            .cast<int>(),
        active: (data['active'] ?? false) as bool,
        type: (data['type'] ?? -1) as int,
      );
    } catch (e) {
      debugPrint("---- hive model error ---- ${e.toString()}");
    }

    return ScheduleHiveModel(
      id: id,
      timeStart: 0,
      timeStop: 0,
      duration: 0,
      days: [0, 0, 0, 0, 0, 0, 0],
      active: false,
      type: -1,
    );
  }

  ScheduleHiveModel remove() {
    return ScheduleHiveModel(
      id: "",
      timeStart: 0,
      timeStop: 0,
      duration: 0,
      days: [0, 0, 0, 0, 0, 0, 0],
      active: false,
      type: -1,
    );
  }

  ScheduleHiveModel copyWith({
    String? id,
    int? timeStart,
    int? timeStop,
    int? duration,
    List<int>? days,
    bool? active,
    int? type,
    // TimeOfDay? startTime,
    // TimeOfDay? stopTime,
  }) {
    return ScheduleHiveModel(
      id: id ?? this.id,
      timeStart: timeStart ?? this.timeStart,
      timeStop: timeStop ?? this.timeStop,
      duration: duration ?? this.duration,
      days: days ?? this.days,
      active: active ?? this.active,
      type: type ?? this.type,
      // startTime: startTime ?? this.startTime,
      // stopTime: stopTime ?? this.stopTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "timeStart": timeStart,
      "timeStop": timeStop,
      "duration": duration,
      "days": days,
      "active": active,
    };
  }

  @HiveField(0)
  String id;

  @HiveField(1)
  int timeStart;

  @HiveField(2)
  int duration;

  @HiveField(3)
  bool active;

  @HiveField(4)
  List<int> days;

  @HiveField(5)
  int timeStop;

  @HiveField(6)
  int type;

  // @HiveField(6)
  // TimeOfDay? startTime;

  // @HiveField(7)
  // TimeOfDay? stopTime;
}
