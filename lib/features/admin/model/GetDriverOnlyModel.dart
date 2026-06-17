// To parse this JSON data, do
//
//     final getDriverOnlyModel = getDriverOnlyModelFromJson(jsonString);

import 'dart:convert';

GetDriverOnlyModel getDriverOnlyModelFromJson(String str) => GetDriverOnlyModel.fromJson(json.decode(str));

String getDriverOnlyModelToJson(GetDriverOnlyModel data) => json.encode(data.toJson());

class GetDriverOnlyModel {
  List<Driver> drivers;
  Pagination pagination;

  GetDriverOnlyModel({
    required this.drivers,
    required this.pagination,
  });

  factory GetDriverOnlyModel.fromJson(Map<String, dynamic> json) => GetDriverOnlyModel(
    drivers: List<Driver>.from(json["drivers"].map((x) => Driver.fromJson(x))),
    pagination: Pagination.fromJson(json["pagination"]),
  );

  Map<String, dynamic> toJson() => {
    "drivers": List<dynamic>.from(drivers.map((x) => x.toJson())),
    "pagination": pagination.toJson(),
  };
}

class Driver {
  int id;
  String name;
  String phone;
  String role;
  String status;
  Driv driverImage;
  String vehicleType;
  String vehicleColor;
  String vehicleNumber;
  String location;
  CarImages carImages;
  Driv drivingLicenseFront;
  Driv drivingLicenseBack;
  String driverDebt;
  dynamic driverDebtLimitOverride;
  bool isDebtBlocked;
  dynamic blockReason;
  DateTime createdAt;
  DateTime updatedAt;

  Driver({
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

  factory Driver.fromJson(Map<String, dynamic> json) => Driver(
    id: json["id"],
    name: json["name"],
    phone: json["phone"],
    role: json["role"],
    status: json["status"],
    driverImage: Driv.fromJson(json["driverImage"]),
    vehicleType: json["vehicleType"],
    vehicleColor: json["vehicleColor"],
    vehicleNumber: json["vehicleNumber"],
    location: json["location"],
    carImages: CarImages.fromJson(json["carImages"]),
    drivingLicenseFront: Driv.fromJson(json["drivingLicenseFront"]),
    drivingLicenseBack: Driv.fromJson(json["drivingLicenseBack"]),
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
    "driverImage": driverImage.toJson(),
    "vehicleType": vehicleType,
    "vehicleColor": vehicleColor,
    "vehicleNumber": vehicleNumber,
    "location": location,
    "carImages": carImages.toJson(),
    "drivingLicenseFront": drivingLicenseFront.toJson(),
    "drivingLicenseBack": drivingLicenseBack.toJson(),
    "driverDebt": driverDebt,
    "driverDebtLimitOverride": driverDebtLimitOverride,
    "isDebtBlocked": isDebtBlocked,
    "blockReason": blockReason,
    "createdAt": createdAt.toIso8601String(),
    "updatedAt": updatedAt.toIso8601String(),
  };
}

class CarImages {
  String main;
  List<String> images;

  CarImages({
    required this.main,
    required this.images,
  });

  factory CarImages.fromJson(Map<String, dynamic> json) => CarImages(
    main: json["main"],
    images: List<String>.from(json["images"].map((x) => x)),
  );

  Map<String, dynamic> toJson() => {
    "main": main,
    "images": List<dynamic>.from(images.map((x) => x)),
  };
}

class Driv {
  String main;

  Driv({
    required this.main,
  });

  factory Driv.fromJson(Map<String, dynamic> json) => Driv(
    main: json["main"],
  );

  Map<String, dynamic> toJson() => {
    "main": main,
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
