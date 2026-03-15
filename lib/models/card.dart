// ABOUTME: Card data model and BarcodeType enum for loyalty/membership cards.
// ABOUTME: Stored in encrypted Hive CE box with generated adapter.

import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

part 'card.g.dart';

@HiveType(typeId: 0)
enum BarcodeType {
  @HiveField(0)
  qrCode,

  @HiveField(1)
  code128,

  @HiveField(2)
  code39,

  @HiveField(3)
  ean13,

  @HiveField(4)
  ean8,

  @HiveField(5)
  dataMatrix,

  @HiveField(6)
  pdf417,

  @HiveField(7)
  aztec,

  @HiveField(8)
  displayOnly,
}

@HiveType(typeId: 1)
class LoyaltyCard extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? issuer;

  @HiveField(3)
  String cardNumber;

  @HiveField(4)
  BarcodeType barcodeType;

  @HiveField(5)
  int colourValue;

  @HiveField(6)
  String? logoPath;

  @HiveField(7)
  DateTime? expiryDate;

  @HiveField(8)
  int usageCount;

  @HiveField(9)
  DateTime? lastUsed;

  @HiveField(10)
  DateTime createdAt;

  @HiveField(11)
  String? notes;

  @HiveField(12)
  bool isFavourite;

  @HiveField(13)
  List<int>? notificationIds;

  LoyaltyCard({
    required this.id,
    required this.name,
    this.issuer,
    required this.cardNumber,
    required this.barcodeType,
    required this.colourValue,
    this.logoPath,
    this.expiryDate,
    this.usageCount = 0,
    this.lastUsed,
    required this.createdAt,
    this.notes,
    this.isFavourite = false,
    this.notificationIds,
  });

  Color get colour => Color.fromARGB(
    (colourValue >> 24) & 0xFF,
    (colourValue >> 16) & 0xFF,
    (colourValue >> 8) & 0xFF,
    colourValue & 0xFF,
  );
  set colour(Color c) => colourValue = c.toARGB32();

  LoyaltyCard copyWith({
    String? id,
    String? name,
    String? issuer,
    String? cardNumber,
    BarcodeType? barcodeType,
    int? colourValue,
    String? logoPath,
    DateTime? expiryDate,
    int? usageCount,
    DateTime? lastUsed,
    DateTime? createdAt,
    String? notes,
    bool? isFavourite,
    List<int>? notificationIds,
  }) {
    return LoyaltyCard(
      id: id ?? this.id,
      name: name ?? this.name,
      issuer: issuer ?? this.issuer,
      cardNumber: cardNumber ?? this.cardNumber,
      barcodeType: barcodeType ?? this.barcodeType,
      colourValue: colourValue ?? this.colourValue,
      logoPath: logoPath ?? this.logoPath,
      expiryDate: expiryDate ?? this.expiryDate,
      usageCount: usageCount ?? this.usageCount,
      lastUsed: lastUsed ?? this.lastUsed,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      isFavourite: isFavourite ?? this.isFavourite,
      notificationIds: notificationIds ?? this.notificationIds,
    );
  }
}
