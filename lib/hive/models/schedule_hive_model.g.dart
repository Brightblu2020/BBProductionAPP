// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScheduleHiveModelAdapter extends TypeAdapter<ScheduleHiveModel> {
  @override
  final int typeId = 2;

  @override
  ScheduleHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScheduleHiveModel(
      id: fields[0] as String,
      timeStart: fields[1] as int,
      timeStop: fields[5] as int,
      duration: fields[2] as int,
      days: (fields[4] as List).cast<int>(),
      active: fields[3] as bool,
      type: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ScheduleHiveModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timeStart)
      ..writeByte(2)
      ..write(obj.duration)
      ..writeByte(3)
      ..write(obj.active)
      ..writeByte(4)
      ..write(obj.days)
      ..writeByte(5)
      ..write(obj.timeStop)
      ..writeByte(6)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
