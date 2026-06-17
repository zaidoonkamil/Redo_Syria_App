// To parse this JSON data, do
//
//     final adminDebtSettingsModel = adminDebtSettingsModelFromJson(jsonString);

import 'dart:convert';

AdminDebtSettingsModel adminDebtSettingsModelFromJson(String str) => AdminDebtSettingsModel.fromJson(json.decode(str));

String adminDebtSettingsModelToJson(AdminDebtSettingsModel data) => json.encode(data.toJson());

class AdminDebtSettingsModel {
  int? limit;
  String? commissionType;
  int? commissionValue;

  AdminDebtSettingsModel({
    this.limit,
    this.commissionType,
    this.commissionValue,
  });

  factory AdminDebtSettingsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return AdminDebtSettingsModel();
    return AdminDebtSettingsModel(
      limit: json["limit"] != null ? int.tryParse(json["limit"].toString()) : null,
      commissionType: json["commissionType"]?.toString(),
      commissionValue: json["commissionValue"] != null ? int.tryParse(json["commissionValue"].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "limit": limit,
    "commissionType": commissionType,
    "commissionValue": commissionValue,
  };
}
