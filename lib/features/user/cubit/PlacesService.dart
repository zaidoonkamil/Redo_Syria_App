import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/widgets/constant.dart';

class PlacesService {
  final Dio dio;

  PlacesService({required this.dio});

  Future<List<PlaceSuggestion>> autocomplete({
    required String input,
    String language = "ar",
    String? sessionToken,
  }) async {
    final q = input.trim();
    if (q.isEmpty) return [];

    const syriaCenterLat = 35.0;
    const syriaCenterLng = 38.5;
    const radiusMeters = 450000;

    final url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json"
        "?input=${Uri.encodeComponent(q)}"
        "&key=$googleMapKey"
        "&language=$language"
        "&components=country:sy"
        "&location=$syriaCenterLat,$syriaCenterLng"
        "&radius=$radiusMeters"
        "&strictbounds=true"
        "${sessionToken != null ? "&sessiontoken=$sessionToken" : ""}";

    final res = await dio.get(url);
    final data = res.data;

    final status = (data["status"] ?? "").toString();
    final err = (data["error_message"] ?? "").toString();
    debugPrint("🧭 AUTOCOMPLETE status=$status err=$err input=$q");

    if (status != "OK") {
      if (status == "ZERO_RESULTS") return [];
      return [];
    }

    final preds = (data["predictions"] as List?) ?? [];
    return preds
        .whereType<Map>()
        .map(
          (p) => PlaceSuggestion(
            placeId: (p["place_id"] ?? "").toString(),
            description: (p["description"] ?? "").toString(),
            mainText:
                (p["structured_formatting"]?["main_text"] ?? "").toString(),
            secondaryText:
                (p["structured_formatting"]?["secondary_text"] ?? "")
                    .toString(),
          ),
        )
        .where((s) => s.placeId.isNotEmpty && s.description.isNotEmpty)
        .toList();
  }

  Future<PlaceDetails?> details({
    required String placeId,
    String language = "ar",
    String? sessionToken,
  }) async {
    final url =
        "https://maps.googleapis.com/maps/api/place/details/json"
        "?place_id=$placeId"
        "&fields=geometry,name,formatted_address"
        "&key=$googleMapKey"
        "&language=$language"
        "${sessionToken != null ? "&sessiontoken=$sessionToken" : ""}";

    final res = await dio.get(url);
    final data = res.data;

    final status = (data["status"] ?? "").toString();
    final err = (data["error_message"] ?? "").toString();
    debugPrint("🧭 DETAILS status=$status err=$err placeId=$placeId");

    if (status != "OK") return null;

    final result = data["result"];
    if (result is! Map) return null;

    final loc = result["geometry"]?["location"];
    if (loc is! Map) return null;

    final lat = (loc["lat"] as num?)?.toDouble();
    final lng = (loc["lng"] as num?)?.toDouble();
    if (lat == null || lng == null) return null;

    final name = (result["name"] ?? "").toString();
    final addr = (result["formatted_address"] ?? "").toString();

    return PlaceDetails(
      latLng: LatLng(lat, lng),
      name: name.isNotEmpty ? name : addr,
      address: addr,
    );
  }
}

class PlaceSuggestion {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });
}

class PlaceDetails {
  final LatLng latLng;
  final String name;
  final String address;

  PlaceDetails({
    required this.latLng,
    required this.name,
    required this.address,
  });
}
