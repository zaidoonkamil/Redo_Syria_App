// To parse this JSON data, do
//
//     final adminPricingModel = adminPricingModelFromJson(jsonString);

import 'dart:convert';

AdminPricingModel adminPricingModelFromJson(String str) =>
    AdminPricingModel.fromJson(json.decode(str));

String adminPricingModelToJson(AdminPricingModel data) =>
    json.encode(data.toJson());

class AdminPricingModel {
  Pricing? pricing;

  AdminPricingModel({this.pricing});

  factory AdminPricingModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return AdminPricingModel();
    return AdminPricingModel(
      pricing:
          json["pricing"] != null ? Pricing.fromJson(json["pricing"]) : null,
    );
  }

  Map<String, dynamic> toJson() => {"pricing": pricing?.toJson()};
}

class Pricing {
  int? id;
  String? serviceType;
  String? baseFare;
  String? pricePerKm;
  dynamic pricePerMinute;
  dynamic minimumFare;
  dynamic roundingTo;
  bool? surgeEnabled;
  String? surgeMultiplier;
  int? updatedByAdminId;
  DateTime? createdAt;
  DateTime? updatedAt;

  Pricing({
    this.id,
    this.serviceType,
    this.baseFare,
    this.pricePerKm,
    this.pricePerMinute,
    this.minimumFare,
    this.roundingTo,
    this.surgeEnabled,
    this.surgeMultiplier,
    this.updatedByAdminId,
    this.createdAt,
    this.updatedAt,
  });

  factory Pricing.fromJson(Map<String, dynamic>? json) {
    if (json == null) return Pricing();
    return Pricing(
      id: json["id"] != null ? int.tryParse(json["id"].toString()) : null,
      serviceType: json["serviceType"]?.toString(),
      baseFare: json["baseFare"]?.toString(),
      pricePerKm: json["pricePerKm"]?.toString(),
      pricePerMinute: json["pricePerMinute"],
      minimumFare: json["minimumFare"],
      roundingTo: json["roundingTo"],
      surgeEnabled:
          json["surgeEnabled"] == true || json["surgeEnabled"] == 'true',
      surgeMultiplier: json["surgeMultiplier"]?.toString(),
      updatedByAdminId:
          json["updatedByAdminId"] != null
              ? int.tryParse(json["updatedByAdminId"].toString())
              : null,
      createdAt:
          json["createdAt"] != null
              ? DateTime.tryParse(json["createdAt"].toString())
              : null,
      updatedAt:
          json["updatedAt"] != null
              ? DateTime.tryParse(json["updatedAt"].toString())
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "serviceType": serviceType,
    "baseFare": baseFare,
    "pricePerKm": pricePerKm,
    "pricePerMinute": pricePerMinute,
    "minimumFare": minimumFare,
    "roundingTo": roundingTo,
    "surgeEnabled": surgeEnabled,
    "surgeMultiplier": surgeMultiplier,
    "updatedByAdminId": updatedByAdminId,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
  };
}
