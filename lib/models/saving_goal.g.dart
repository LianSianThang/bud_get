// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saving_goal.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SavingGoalAdapter extends TypeAdapter<SavingGoal> {
  @override
  final int typeId = 2;

  @override
  SavingGoal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavingGoal(
      name: fields[0] as String,
      targetAmount: fields[1] as double,
      currentAmount: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, SavingGoal obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.targetAmount)
      ..writeByte(2)
      ..write(obj.currentAmount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavingGoalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
