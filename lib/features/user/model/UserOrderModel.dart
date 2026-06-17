import 'dart:convert';

UserOrderModel userOrderModelFromJson(String str) => UserOrderModel.fromJson(json.decode(str));

String userOrderModelToJson(UserOrderModel data) => json.encode(data.toJson());

class UserOrderModel {
  bool success;
  int total;
  int page;
  int limit;
  List<Ride> rides;

  UserOrderModel({
    required this.success,
    required this.total,
    required this.page,
    required this.limit,
    required this.rides,
  });

  factory UserOrderModel.fromJson(Map<String, dynamic> json) => UserOrderModel(
    success: json["success"],
    total: json["total"],
    page: json["page"],
    limit: json["limit"],
    rides: List<Ride>.from(json["rides"].map((x) => Ride.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "total": total,
    "page": page,
    "limit": limit,
    "rides": List<dynamic>.from(rides.map((x) => x.toJson())),
  };
}

class Ride {
  int id;
  int riderId;
  int? driverId;
  String serviceType;
  Status status;
  String pickupLat;
  String pickupLng;
  String pickupAddress;
  String dropoffLat;
  String dropoffLng;
  String dropoffAddress;
  dynamic priceEstimate;
  String estimatedFare;
  String distanceKm;
  String durationMin;
  DateTime createdAt;
  DateTime updatedAt;

  Ride({
    required this.id,
    required this.riderId,
    required this.driverId,
    required this.serviceType,
    required this.status,
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupAddress,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.dropoffAddress,
    required this.priceEstimate,
    required this.estimatedFare,
    required this.distanceKm,
    required this.durationMin,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Ride.fromJson(Map<String, dynamic> json) => Ride(
    id: json["id"],
    riderId: json["rider_id"],
    driverId: json["driver_id"],
    serviceType: (json["serviceType"] ?? "normal").toString(),
    status: statusValues.map[json["status"]??'']!,
    pickupLat: json["pickupLat"],
    pickupLng: json["pickupLng"],
    pickupAddress: json["pickupAddress"],
    dropoffLat: json["dropoffLat"],
    dropoffLng: json["dropoffLng"],
    dropoffAddress: json["dropoffAddress"],
    priceEstimate: json["priceEstimate"],
    estimatedFare: json["estimatedFare"],
    distanceKm: json["distanceKm"],
    durationMin: json["durationMin"],
    createdAt: DateTime.parse(json["createdAt"]),
    updatedAt: DateTime.parse(json["updatedAt"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "rider_id": riderId,
    "driver_id": driverId,
    "serviceType": serviceType,
    "status": statusValues.reverse[status],
    "pickupLat": pickupLat,
    "pickupLng": pickupLng,
    "pickupAddress": pickupAddress,
    "dropoffLat": dropoffLat,
    "dropoffLng": dropoffLng,
    "dropoffAddress": dropoffAddress,
    "priceEstimate": priceEstimate,
    "estimatedFare": estimatedFare,
    "distanceKm": distanceKm,
    "durationMin": durationMin,
    "createdAt": createdAt.toIso8601String(),
    "updatedAt": updatedAt.toIso8601String(),
  };
}

enum Status {
  CANCELLED,
  COMPLETED
}

final statusValues = EnumValues({
  "cancelled": Status.CANCELLED,
  "completed": Status.COMPLETED
});

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
