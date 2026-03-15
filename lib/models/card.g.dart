// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LoyaltyCardAdapter extends TypeAdapter<LoyaltyCard> {
  @override
  final typeId = 1;

  @override
  LoyaltyCard read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LoyaltyCard(
      id: fields[0] as String,
      name: fields[1] as String,
      issuer: fields[2] as String?,
      cardNumber: fields[3] as String,
      barcodeType: fields[4] as BarcodeType,
      colourValue: (fields[5] as num).toInt(),
      logoPath: fields[6] as String?,
      expiryDate: fields[7] as DateTime?,
      usageCount: fields[8] == null ? 0 : (fields[8] as num).toInt(),
      lastUsed: fields[9] as DateTime?,
      createdAt: fields[10] as DateTime,
      notes: fields[11] as String?,
      isFavourite: fields[12] == null ? false : fields[12] as bool,
      notificationIds: (fields[13] as List?)?.cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, LoyaltyCard obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.issuer)
      ..writeByte(3)
      ..write(obj.cardNumber)
      ..writeByte(4)
      ..write(obj.barcodeType)
      ..writeByte(5)
      ..write(obj.colourValue)
      ..writeByte(6)
      ..write(obj.logoPath)
      ..writeByte(7)
      ..write(obj.expiryDate)
      ..writeByte(8)
      ..write(obj.usageCount)
      ..writeByte(9)
      ..write(obj.lastUsed)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.notes)
      ..writeByte(12)
      ..write(obj.isFavourite)
      ..writeByte(13)
      ..write(obj.notificationIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoyaltyCardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BarcodeTypeAdapter extends TypeAdapter<BarcodeType> {
  @override
  final typeId = 0;

  @override
  BarcodeType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BarcodeType.qrCode;
      case 1:
        return BarcodeType.code128;
      case 2:
        return BarcodeType.code39;
      case 3:
        return BarcodeType.ean13;
      case 4:
        return BarcodeType.ean8;
      case 5:
        return BarcodeType.dataMatrix;
      case 6:
        return BarcodeType.pdf417;
      case 7:
        return BarcodeType.aztec;
      case 8:
        return BarcodeType.displayOnly;
      default:
        return BarcodeType.qrCode;
    }
  }

  @override
  void write(BinaryWriter writer, BarcodeType obj) {
    switch (obj) {
      case BarcodeType.qrCode:
        writer.writeByte(0);
      case BarcodeType.code128:
        writer.writeByte(1);
      case BarcodeType.code39:
        writer.writeByte(2);
      case BarcodeType.ean13:
        writer.writeByte(3);
      case BarcodeType.ean8:
        writer.writeByte(4);
      case BarcodeType.dataMatrix:
        writer.writeByte(5);
      case BarcodeType.pdf417:
        writer.writeByte(6);
      case BarcodeType.aztec:
        writer.writeByte(7);
      case BarcodeType.displayOnly:
        writer.writeByte(8);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarcodeTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
