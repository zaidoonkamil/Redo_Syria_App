import 'dart:convert';

GetNotifications getNotificationsFromJson(String str) => GetNotifications.fromJson(json.decode(str));

String getNotificationsToJson(GetNotifications data) => json.encode(data.toJson());

class GetNotifications {
  int total;
  int page;
  int totalPages;
  List<Log> logs;

  GetNotifications({
    required this.total,
    required this.page,
    required this.totalPages,
    required this.logs,
  });

  factory GetNotifications.fromJson(Map<String, dynamic> json) => GetNotifications(
    total: json["total"],
    page: json["page"],
    totalPages: json["totalPages"],
    logs: List<Log>.from(json["logs"].map((x) => Log.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "total": total,
    "page": page,
    "totalPages": totalPages,
    "logs": List<dynamic>.from(logs.map((x) => x.toJson())),
  };
}

class Log {
  int id;
  int? userId;
  String title;
  String message;
  String targetType;
  String targetValue;
  String status;
  DateTime createdAt;
  DateTime updatedAt;

  Log({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.targetType,
    required this.targetValue,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Log.fromJson(Map<String, dynamic> json) => Log(
    id: json["id"],
    userId: json["user_id"],
    title: json["title"],
    message: json["message"],
    targetType: json["target_type"],
    targetValue: json["target_value"],
    status: json["status"],
    createdAt: DateTime.parse(json["createdAt"]),
    updatedAt: DateTime.parse(json["updatedAt"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "user_id": userId,
    "title": title,
    "message": message,
    "target_type": targetType,
    "target_value": targetValue,
    "status": status,
    "createdAt": createdAt.toIso8601String(),
    "updatedAt": updatedAt.toIso8601String(),
  };
}
