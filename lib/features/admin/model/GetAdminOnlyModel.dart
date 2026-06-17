// To parse this JSON data, do
//
//     final getAdminOnlyModel = getAdminOnlyModelFromJson(jsonString);

import 'dart:convert';

GetAdminOnlyModel getAdminOnlyModelFromJson(String str) => GetAdminOnlyModel.fromJson(json.decode(str));

String getAdminOnlyModelToJson(GetAdminOnlyModel data) => json.encode(data.toJson());

class GetAdminOnlyModel {
  List<User> users;
  Pagination pagination;

  GetAdminOnlyModel({
    required this.users,
    required this.pagination,
  });

  factory GetAdminOnlyModel.fromJson(Map<String, dynamic> json) => GetAdminOnlyModel(
    users: List<User>.from(json["users"].map((x) => User.fromJson(x))),
    pagination: Pagination.fromJson(json["pagination"]),
  );

  Map<String, dynamic> toJson() => {
    "users": List<dynamic>.from(users.map((x) => x.toJson())),
    "pagination": pagination.toJson(),
  };
}

class Pagination {
  int totalDrivers;
  int currentPage;
  int totalPages;
  int limit;

  Pagination({
    required this.totalDrivers,
    required this.currentPage,
    required this.totalPages,
    required this.limit,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
    totalDrivers: json["totalDrivers"],
    currentPage: json["currentPage"],
    totalPages: json["totalPages"],
    limit: json["limit"],
  );

  Map<String, dynamic> toJson() => {
    "totalDrivers": totalDrivers,
    "currentPage": currentPage,
    "totalPages": totalPages,
    "limit": limit,
  };
}

class User {
  int id;
  String name;
  String phone;
  String role;
  String status;
  dynamic driverImage;
  dynamic vehicleType;
  dynamic vehicleColor;
  dynamic vehicleNumber;
  dynamic location;
  dynamic carImages;
  dynamic drivingLicenseFront;
  dynamic drivingLicenseBack;
  String driverDebt;
  dynamic driverDebtLimitOverride;
  bool isDebtBlocked;
  dynamic blockReason;
  DateTime createdAt;
  DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.status,
    required this.driverImage,
    required this.vehicleType,
    required this.vehicleColor,
    required this.vehicleNumber,
    required this.location,
    required this.carImages,
    required this.drivingLicenseFront,
    required this.drivingLicenseBack,
    required this.driverDebt,
    required this.driverDebtLimitOverride,
    required this.isDebtBlocked,
    required this.blockReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json["id"],
    name: json["name"],
    phone: json["phone"],
    role: json["role"],
    status: json["status"],
    driverImage: json["driverImage"],
    vehicleType: json["vehicleType"],
    vehicleColor: json["vehicleColor"],
    vehicleNumber: json["vehicleNumber"],
    location: json["location"],
    carImages: json["carImages"],
    drivingLicenseFront: json["drivingLicenseFront"],
    drivingLicenseBack: json["drivingLicenseBack"],
    driverDebt: json["driverDebt"],
    driverDebtLimitOverride: json["driverDebtLimitOverride"],
    isDebtBlocked: json["isDebtBlocked"],
    blockReason: json["blockReason"],
    createdAt: DateTime.parse(json["createdAt"]),
    updatedAt: DateTime.parse(json["updatedAt"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "phone": phone,
    "role": role,
    "status": status,
    "driverImage": driverImage,
    "vehicleType": vehicleType,
    "vehicleColor": vehicleColor,
    "vehicleNumber": vehicleNumber,
    "location": location,
    "carImages": carImages,
    "drivingLicenseFront": drivingLicenseFront,
    "drivingLicenseBack": drivingLicenseBack,
    "driverDebt": driverDebt,
    "driverDebtLimitOverride": driverDebtLimitOverride,
    "isDebtBlocked": isDebtBlocked,
    "blockReason": blockReason,
    "createdAt": createdAt.toIso8601String(),
    "updatedAt": updatedAt.toIso8601String(),
  };
}
