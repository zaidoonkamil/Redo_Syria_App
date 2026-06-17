import 'dart:convert';

DriverModel driverModelFromJson(String str) => DriverModel.fromJson(json.decode(str));

String driverModelToJson(DriverModel data) => json.encode(data.toJson());

class DriverModel {
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

  DriverModel({
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

  factory DriverModel.fromJson(Map<String, dynamic> json) => DriverModel(
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
