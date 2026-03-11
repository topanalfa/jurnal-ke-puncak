// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hike_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HikeModelAdapter extends TypeAdapter<HikeModel> {
  @override
  final int typeId = 0;

  @override
  HikeModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HikeModel(
      id: fields[0] as String,
      title: fields[1] as String,
      date: fields[2] as DateTime,
      duration: fields[3] as int,
      distance: fields[4] as double,
      moodBefore: fields[5] as String,
      moodAfter: fields[6] as String,
      notes: fields[7] as String,
      photos: (fields[8] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, HikeModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.duration)
      ..writeByte(4)
      ..write(obj.distance)
      ..writeByte(5)
      ..write(obj.moodBefore)
      ..writeByte(6)
      ..write(obj.moodAfter)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.photos);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HikeModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
