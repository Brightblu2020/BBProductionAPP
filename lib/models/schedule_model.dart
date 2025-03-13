import 'package:flutter/material.dart';

class ScheduleModel {
  ScheduleModel({
    required this.startTime,
    required this.days,
    required this.hrs,
    required this.stopTime,
    this.start,
    this.end,
    required this.active,
    required this.id,
  });

  factory ScheduleModel.fromJson(
      {required Map<String, dynamic> json, required String id}) {
    return ScheduleModel(
      id: id,
      startTime: (json['timeStart'] ?? 0) as int,
      days: ((json['days'] ?? [1, 1, 1, 1, 1, 1, 1]) as List<dynamic>)
          .cast<int>(),
      hrs: (json['duration'] ?? 0) as int,
      stopTime: (json['timeStop'] ?? -1) as int,
      active: (json['active'] ?? false) as bool,
      start: const TimeOfDay(hour: 0, minute: 0),
      end: const TimeOfDay(hour: 0, minute: 0),
    );
  }

  ScheduleModel copyWith({
    String? id,
    int? startTime,
    List<int>? days,
    int? hrs,
    int? stopTime,
    bool? active,
    TimeOfDay? start,
    TimeOfDay? end,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      days: days ?? this.days,
      hrs: hrs ?? this.hrs,
      stopTime: stopTime ?? this.stopTime,
      start: start ?? this.start,
      end: end ?? this.end,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "timeStart": startTime,
      "days": days,
      "duration": hrs,
      "timeStop": stopTime,
      "active": active,
    };
  }

  final String? id;
  final int startTime;
  final int hrs;
  final bool active;
  final List<int> days;
  final int stopTime;
  final TimeOfDay? start;
  final TimeOfDay? end;
}
