// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionHiveModelAdapter extends TypeAdapter<TransactionHiveModel> {
  @override
  final int typeId = 1;

  @override
  TransactionHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransactionHiveModel(
      id: fields[0] as int,
      timeStart: fields[1] as num,
      timeStop: fields[2] as num,
      meterValues: fields[3] as num,
      idTag: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TransactionHiveModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timeStart)
      ..writeByte(2)
      ..write(obj.timeStop)
      ..writeByte(3)
      ..write(obj.meterValues)
      ..writeByte(4)
      ..write(obj.idTag);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
