// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rfid_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RfidHiveModelAdapter extends TypeAdapter<RfidHiveModel> {
  @override
  final int typeId = 3;

  @override
  RfidHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RfidHiveModel(
      id: fields[0] as String,
      name: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, RfidHiveModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RfidHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
