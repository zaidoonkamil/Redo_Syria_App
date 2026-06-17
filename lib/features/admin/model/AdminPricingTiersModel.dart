import 'dart:convert';

AdminPricingTiersModel adminPricingTiersModelFromJson(String str) =>
    AdminPricingTiersModel.fromJson(json.decode(str));

String adminPricingTiersModelToJson(AdminPricingTiersModel data) =>
    json.encode(data.toJson());

class AdminPricingTiersModel {
  final List<PricingTierItem> tiers;

  AdminPricingTiersModel({this.tiers = const []});

  factory AdminPricingTiersModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return AdminPricingTiersModel();
    }

    final rawTiers = json['tiers'];
    if (rawTiers is! List) {
      return AdminPricingTiersModel();
    }

    return AdminPricingTiersModel(
      tiers: rawTiers
          .whereType<Map>()
          .map((item) => PricingTierItem.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'tiers': tiers.map((tier) => tier.toJson()).toList(),
      };
}

class PricingTierItem {
  final int? id;
  final String serviceType;
  final String fromKm;
  final String? toKm;
  final String pricePerKm;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PricingTierItem({
    this.id,
    this.serviceType = 'normal',
    this.fromKm = '0',
    this.toKm,
    this.pricePerKm = '0',
    this.createdAt,
    this.updatedAt,
  });

  bool get isOpenEnded => toKm == null || toKm!.trim().isEmpty;

  factory PricingTierItem.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const PricingTierItem();
    }

    return PricingTierItem(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      serviceType: (json['serviceType'] ?? 'normal').toString(),
      fromKm: (json['fromKm'] ?? '0').toString(),
      toKm: json['toKm']?.toString(),
      pricePerKm: (json['pricePerKm'] ?? '0').toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'serviceType': serviceType,
        'fromKm': fromKm,
        'toKm': toKm,
        'pricePerKm': pricePerKm,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}