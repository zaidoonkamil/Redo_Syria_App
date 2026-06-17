import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rido_syria_app/core/styles/themes.dart';
import 'package:rido_syria_app/core/widgets/show_toast.dart';
import 'package:rido_syria_app/features/user/cubit/states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rido_syria_app/features/user/model/DriverModel.dart';
import 'package:rido_syria_app/features/user/model/GetNotifications.dart';
import 'package:rido_syria_app/features/user/model/ProfileModel.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'dart:ui' as ui;
import 'package:flutter/services.dart';

import '../../../core/ navigation/navigation.dart';
import '../../../core/network/remote/dio_helper.dart';
import '../../../core/widgets/constant.dart';
import 'package:geocoding/geocoding.dart';

import '../../auth/view/login.dart';
import '../model/UserOrderModel.dart';
import 'PlacesService.dart';

enum RideServiceType { normal, vip }

extension RideServiceTypeX on RideServiceType {
  String get value => this == RideServiceType.vip ? "vip" : "normal";
  String get label => this == RideServiceType.vip ? "VIP" : "عادي";
}

enum SelectingPoint { pickup, dropoff }

class UserCubit extends Cubit<UserStates> {
  UserCubit() : super(UserInitialState());

  static UserCubit get(context) => BlocProvider.of(context);

  RideServiceType? selectedServiceType;

  void changeServiceType(RideServiceType type) {
    selectedServiceType = type;
    emit(UserMapMoveState());
  }

  ProfileModel? profileModel;
  DriverModel? driverModel;

  void deleteAccount({required BuildContext context,}) {
    emit(DeleteProfileLoadingState());
    DioHelper.deleteData(
      url: '/users/$id',
    ).then((value) {
      token='';
      emit(DeleteProfileSuccessState());
      navigateAndFinish(context, Login());
    }).catchError((error) {
      if (error is DioError) {
        showSnackBarError(text: error.toString(), context: context,);
        print(error.toString());
        emit(DeleteProfileErrorState());
      }else {
        print("Unknown Error: $error");
      }
    });
  }

  void getProfile({required BuildContext context,}) {
    emit(GetProfileLoadingState());
    DioHelper.getData(
        url: '/profile',
        token: token
    ).then((value) {
      profileModel = ProfileModel.fromJson(value.data);
      emit(GetProfileSuccessState());
    }).catchError((error) {
      if (error is DioError) {
        showSnackBarError(text: error.toString(), context: context,);
        print(error.toString());
        emit(GetProfileErrorState());
      }else {
        print("Unknown Error: $error");
      }
    });
  }

  UserOrderModel? userOrderModel;
  void getUserOrder({required BuildContext context,required String userId}) {
    emit(UserOrderLoadingState());
    DioHelper.getData(
        url: '/ride-requests/user/$userId',
    ).then((value) {
      userOrderModel = UserOrderModel.fromJson(value.data);
      emit(UserOrderSuccessState());
    }).catchError((error) {
      if (error is DioError) {
        showSnackBarError(text: error.toString(), context: context,);
        print(error.toString());
        emit(UserOrderErrorState());
      }else {
        print("Unknown Error: $error");
      }
    });
  }

  Future<void> getDriverById({required String userId}) async {
    try {
      final value = await DioHelper.getData(url: '/user/$userId');
      driverModel = DriverModel.fromJson(value.data);
      emit(UserMapMoveState());
    } catch (e) {
      debugPrint("getDriverById error: $e");
    }
  }

  bool _looksBad(String s) {
    final t = s.trim();
    if (t.isEmpty) return true;
    final letters = RegExp(r'[A-Za-z\u0600-\u06FF]').allMatches(t).length;
    final digitsOrSymbols = RegExp(r'[^A-Za-z\u0600-\u06FF\s]').allMatches(t).length;
    if (letters == 0) return true;
    if (digitsOrSymbols > letters) return true;
    if (t.length <= 2) return true;
    return false;
  }

  Future<String> _reverseGeocodeReadable(LatLng p) async {
    final placemarks = await placemarkFromCoordinates(p.latitude, p.longitude);
    if (placemarks.isEmpty) return "موقع غير معروف";

    final pm = placemarks.first;

    String pick(String? v) => (v ?? "").trim();
    String? clean(String? v) {
      final t = pick(v);
      if (t.isEmpty) return null;
      if (_looksBad(t)) return null;
      return t;
    }

    // تفاصيل أكثر (من الأصغر للأكبر)
    final name       = clean(pm.name);          // أحياناً يطلع رقم دار/اسم مكان
    final street     = clean(pm.street);
    final subLocal   = clean(pm.subLocality);   // حي/محلة
    final locality   = clean(pm.locality);      // مدينة
    final adminSub   = clean(pm.subAdministrativeArea); // قضاء/ناحية (إذا متوفر)
    final admin      = clean(pm.administrativeArea);    // محافظة

    // شكّل عنوان مرتب: (محلة/شارع) + (مدينة) + (قضاء/محافظة)
    final parts = <String>[
      if (subLocal != null) subLocal,
      if (street != null) street,
      if (name != null && name != street && name != subLocal) name,
      if (locality != null) locality,
      if (adminSub != null && adminSub != locality) adminSub,
      if (admin != null && admin != locality && admin != adminSub) admin,
    ];

    // شيل التكرارات
    final unique = <String>[];
    for (final x in parts) {
      if (!unique.contains(x)) unique.add(x);
    }

    if (unique.isNotEmpty) {
      // خذ 2-3 أجزاء حتى يصير مفيد بدون ما يطول
      return unique.take(3).join("، ");
    }

    return "موقع قريب من (${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)})";
  }

  Future<String> _nearestPlaceName(LatLng p) async {
    try {
      final dio = Dio();
      final url =
          "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
          "?location=${p.latitude},${p.longitude}"
          "&radius=600"
          "&key=$googleApiKey"
          "&language=ar";

      final res = await dio.get(url);
      final data = res.data;

      final results = (data["results"] as List?) ?? [];
      if (results.isEmpty) return await _reverseGeocodeReadable(p);

      Map? best;
      for (final r in results) {
        if (r is! Map) continue;
        final name = (r["name"] ?? "").toString().trim();
        if (name.isEmpty) continue;
        if (_looksBad(name)) continue;

        best = r;
        break;
      }

      if (best == null) return await _reverseGeocodeReadable(p);

      final name = (best["name"] ?? "").toString().trim();
      final vicinity = (best["vicinity"] ?? "").toString().trim();

      if (vicinity.isNotEmpty && !_looksBad(vicinity)) {
        return "$name، $vicinity";
      }

      // إذا ماكو vicinity، رجّع اسم + تفاصيل من reverse geocode
      final addr = await _reverseGeocodeReadable(p);
      return "$name، $addr";
    } catch (_) {
      return await _reverseGeocodeReadable(p);
    }
  }

  GetNotifications? getNotificationsModel;
  void getNotifications({required BuildContext context,}) {
    emit(GetNotificationsLoadingState());
    DioHelper.getData(
      url: '/notifications-log?user_id=$id',
    ).then((value) {
      getNotificationsModel = GetNotifications.fromJson(value.data);
      emit(GetNotificationsSuccessState());
    }).catchError((error) {
      if (error is DioError) {
        showSnackBarError(text: error.toString(), context: context,);
        print(error.toString());
        emit(GetNotificationsErrorState());
      }else {
        print("Unknown Error: $error");
      }
    });
  }

  double walletBalance = 0.0;
  List<Map<String, dynamic>> walletTransactions = [];

  void getWallet({required BuildContext context}) {
    emit(GetWalletLoadingState());
    DioHelper.getData(
      url: '/wallet',
      token: token,
    ).then((value) {
      final wallet = value.data is Map<String, dynamic>
          ? (value.data['wallet'] as Map<String, dynamic>?)
          : null;
      final balance = wallet?['balance'];

      walletBalance = (balance is num)
          ? balance.toDouble()
          : double.tryParse(balance?.toString() ?? '0') ?? 0.0;

      emit(GetWalletSuccessState());
    }).catchError((error) {
      if (error is DioError) {
        showSnackBarError(text: error.toString(), context: context);
        emit(GetWalletErrorState());
      } else {
        debugPrint('Unknown Error: $error');
        emit(GetWalletErrorState());
      }
    });
  }

  void getWalletTransactions({required BuildContext context}) {
    emit(GetWalletTransactionsLoadingState());
    DioHelper.getData(
      url: '/wallet/transactions?page=1&limit=50',
      token: token,
    ).then((value) {
      final data = value.data;
      final rows = (data is Map<String, dynamic>) ? data['transactions'] : null;

      if (rows is List) {
        walletTransactions = rows
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } else {
        walletTransactions = [];
      }

      emit(GetWalletTransactionsSuccessState());
    }).catchError((error) {
      if (error is DioError) {
        showSnackBarError(text: error.toString(), context: context);
        emit(GetWalletTransactionsErrorState());
      } else {
        debugPrint('Unknown Error: $error');
        emit(GetWalletTransactionsErrorState());
      }
    });
  }

  final DraggableScrollableController sheetController = DraggableScrollableController();

  void _animateSheet(double size) {
    void tryAnimate([int tries = 0]) {
      if (sheetController.isAttached) {
        sheetController.animateTo(
          size,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
        return;
      }
      if (tries >= 10) return;
      Future.delayed(const Duration(milliseconds: 50), () => tryAnimate(tries + 1));
    }

    tryAnimate();
  }

  void openPendingSheet() => _animateSheet(0.46);
  void lockActiveTripSheet() => _animateSheet(0.62);
  void collapseSheet() => _animateSheet(0.32);


  SelectingPoint selectingPoint = SelectingPoint.pickup;

  GoogleMapController? mapController;

  BitmapDescriptor? driverIcon;

  LatLng? currentLatLng;

  LatLng? cameraCenter;
  bool isCameraMoving = false;
  String? driverId;

  LatLng? pickupLatLng;
  LatLng? dropoffLatLng;

  final Set<Marker> markers = {};
  final Set<Polyline> polylines = {};

  IO.Socket? _socket;
  bool socketConnected = false;

  LatLng? driverLatLng;

  double? distanceKm;
  int? durationMin;

  String? estimatedFare;

  String? activeRequestId;
  String rideStatus = "idle";

  String? pickupName;
  String? dropoffName;

  BitmapDescriptor? pickupIcon;
  BitmapDescriptor? dropoffIcon;

  Future<void> _loadCustomIcons() async {
    pickupIcon = await loadResizedMarker('assets/images/pick2.png', 50);
    dropoffIcon = await loadResizedMarker('assets/images/drop2.png', 50);
  }

  Future<void> _loadDriverIcon() async {
    driverIcon = await loadResizedMarker(
      'assets/images/gps.png',
      68,
    );
  }

  Future<BitmapDescriptor> loadResizedMarker(
      String assetPath,
      int width,
      ) async {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    final frame = await codec.getNextFrame();
    final bytes = await frame.image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  Future<String> _reverseGeocode(LatLng p) async {
    final placemarks = await placemarkFromCoordinates(p.latitude, p.longitude);
    if (placemarks.isEmpty) return "موقع غير معروف";
    final pm = placemarks.first;

    final parts = [
      pm.name,
      pm.street,
      pm.subLocality,
      pm.locality,
    ].where((e) => e != null && e!.trim().isNotEmpty).map((e) => e!.trim()).toList();

    return parts.isEmpty ? "موقع غير معروف" : parts.take(2).join("، ");
  }


  void onCameraMove(CameraPosition pos) {
    cameraCenter = pos.target;
    isCameraMoving = true;
    emit(UserMapMoveState());
  }

  void onCameraIdle() {
    isCameraMoving = false;
    emit(UserMapMoveState());
  }

  // ====== INIT ======
  Future<void> init() async {
    await _setupAudio();
    await _loadDriverIcon();
    await _loadCustomIcons();
    await _getCurrentLocation();
    await checkActiveRide();
    _connectSocket();
  }

  // ====== MAP ======
  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (currentLatLng != null) {
      mapController!.animateCamera(CameraUpdate.newLatLngZoom(currentLatLng!, 15));
    }
  }


  // ===== SEARCH UI STATE =====
  bool isSearching = false;
  SelectingPoint searchingFor = SelectingPoint.pickup;

  final TextEditingController searchController = TextEditingController();
  List<PlaceSuggestion> placeSuggestions = [];

  late final PlacesService placesService = PlacesService(dio: Dio());

  void startSearch(SelectingPoint p) {
    searchingFor = p;
    isSearching = true;
    placeSuggestions = [];
    searchController.clear();

    openPendingSheet();
    emit(UserMapMoveState());
  }

  void stopSearch() {
    isSearching = false;
    placeSuggestions = [];
    searchController.clear();

    collapseSheet(); // ✅ يرجع الشيت
    emit(UserMapMoveState());
  }

  Future<void> searchPlaces(String q) async {
    if (!isSearching) return;

    if (q.trim().isEmpty) {
      placeSuggestions = [];
      emit(UserMapMoveState());
      return;
    }

    try {
      placeSuggestions = await placesService.autocomplete(input: q);
      emit(UserMapMoveState());
    } catch (_) {
      // تجاهل
    }
  }

  Future<void> selectPlaceSuggestion(PlaceSuggestion s) async {
    try {
      final details = await placesService.details(placeId: s.placeId);
      if (details == null) return;

      if (searchingFor == SelectingPoint.pickup) {
        pickupLatLng = details.latLng;
        pickupName = details.name;
        selectingPoint = SelectingPoint.dropoff;
      } else {
        dropoffLatLng = details.latLng;
        dropoffName = details.name;
      }

      _refreshMarkers();
      emit(UserMapMoveState());

      // حرّك الكاميرا
      if (mapController != null) {
        await mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(details.latLng, 15),
        );
      }

      // اذا عندك نقطتين ارسم المسار و fit
      if (pickupLatLng != null && dropoffLatLng != null) {
        await drawRouteOnRoads();
        await _fitBothPoints();
      }

      stopSearch();
    } catch (_) {
      // تجاهل
    }
  }

  Future<void> setPickupFromSearch(LatLng p, String name) async {
    pickupLatLng = p;
    pickupName = name;
    selectingPoint = SelectingPoint.dropoff;

    _refreshMarkers();
    emit(UserMapMoveState());

    if (mapController != null) {
      await mapController!.animateCamera(CameraUpdate.newLatLngZoom(p, 15));
    }
  }

  Future<void> setDropoffFromSearch(LatLng p, String name) async {
    dropoffLatLng = p;
    dropoffName = name;

    _refreshMarkers();
    await drawRouteOnRoads();
    emit(UserMapMoveState());

    if (mapController != null) {
      await mapController!.animateCamera(CameraUpdate.newLatLngZoom(p, 15));
    }

    if (pickupLatLng != null && dropoffLatLng != null) {
      await _fitBothPoints();
    }
  }

  Future<void> _getCurrentLocation() async {
    emit(UserLoadingLocationState());

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        emit(UserLocationErrorState("فعّل GPS حتى نكدر نحدد موقعك"));
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        emit(UserLocationErrorState("صلاحية الموقع مرفوضة نهائياً. افتحها من الإعدادات"));
        return;
      }
      if (perm == LocationPermission.denied) {
        emit(UserLocationErrorState("صلاحية الموقع مرفوضة"));
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      currentLatLng = LatLng(pos.latitude, pos.longitude);


      emit(UserLocationReadyState());
    } catch (e) {
      emit(UserLocationErrorState("خطأ بالموقع: $e"));
    }
  }

  void updatePickupByTap(LatLng latLng) {
    pickupLatLng = latLng;
    _refreshMarkers();
    emit(UserMapMoveState());
  }

  void updateDropoffByTap(LatLng latLng) {
    dropoffLatLng = latLng;
    _refreshMarkers();
    emit(UserMapMoveState());
  }

  void _refreshMarkers() {
    markers.clear();

    if (pickupLatLng != null) {
      markers.add(Marker(
        markerId: const MarkerId("pickup"),
        position: pickupLatLng!,
        infoWindow: const InfoWindow(title: "نقطة الانطلاق"),
        icon: pickupIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }

    if (dropoffLatLng != null) {
      markers.add(Marker(
        markerId: const MarkerId("dropoff"),
        position: dropoffLatLng!,
        infoWindow: const InfoWindow(title: "نقطة الوصول"),
        icon: dropoffIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }

    if (driverLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId("driver"),
          position: driverLatLng!,
          infoWindow: const InfoWindow(title: "السائق"),
          icon: driverIcon ?? BitmapDescriptor.defaultMarker,
          anchor: const Offset(0.5, 0.8),
        ),
      );
    }

  }

  String get mainButtonText {
    if (pickupLatLng == null) return "ثبّت نقطة الانطلاق";
    if (dropoffLatLng == null) return "ثبّت نقطة الوصول";
    if (selectedServiceType == null) return "اختر نوع الرحلة";
    return selectedServiceType == RideServiceType.vip ? "اطلب VIP" : "اطلب تكسي";
  }

  Future<void> _fitBothPoints() async {
    if (mapController == null || pickupLatLng == null || dropoffLatLng == null) return;

    final swLat = pickupLatLng!.latitude < dropoffLatLng!.latitude
        ? pickupLatLng!.latitude
        : dropoffLatLng!.latitude;

    final swLng = pickupLatLng!.longitude < dropoffLatLng!.longitude
        ? pickupLatLng!.longitude
        : dropoffLatLng!.longitude;

    final neLat = pickupLatLng!.latitude > dropoffLatLng!.latitude
        ? pickupLatLng!.latitude
        : dropoffLatLng!.latitude;

    final neLng = pickupLatLng!.longitude > dropoffLatLng!.longitude
        ? pickupLatLng!.longitude
        : dropoffLatLng!.longitude;

    final bounds = LatLngBounds(
      southwest: LatLng(swLat, swLng),
      northeast: LatLng(neLat, neLng),
    );

    await mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  Future<void> drawRouteBetween(LatLng origin, LatLng destination) async {
    try {
      final polylinePoints = PolylinePoints();

      final result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: googleApiKey,
        request: PolylineRequest(
          origin: PointLatLng(origin.latitude, origin.longitude),
          destination: PointLatLng(destination.latitude, destination.longitude),
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isEmpty) {
        polylines
          ..clear()
          ..add(Polyline(
            polylineId: const PolylineId("route"),
            points: [origin, destination],
            width: 5,
            color: secondPrimaryColor,
          ));
        emit(UserMapMoveState());
        return;
      }

      final routePoints = result.points.map((p) => LatLng(p.latitude, p.longitude)).toList();

      polylines
        ..clear()
        ..add(Polyline(
          polylineId: const PolylineId("route"),
          points: routePoints,
          width: 5,
          color: secondPrimaryColor,
        ));

      emit(UserMapMoveState());
    } catch (e) {
      polylines
        ..clear()
        ..add(Polyline(
          polylineId: const PolylineId("route"),
          points: [origin, destination],
          width: 5,
          color: secondPrimaryColor,
        ));
      emit(UserMapMoveState());
    }
  }

  double _calcDistanceKm(LatLng a, LatLng b) {
    final meters = Geolocator.distanceBetween(
      a.latitude, a.longitude,
      b.latitude, b.longitude,
    );
    return meters / 1000.0;
  }

  void onMainActionPressed() async {
    if (cameraCenter == null) {
      emit(UserCreateRequestErrorState("حرّك الخريطة حتى تحدد موقع"));
      return;
    }
    if (pickupLatLng == null) {
      pickupLatLng = cameraCenter;
      pickupName = "جاري تحديد الاسم...";
      selectingPoint = SelectingPoint.dropoff;

      _refreshMarkers();
      emit(UserMapMoveState());
      await _updateCameraAfterSelection();

      try {
        pickupName = await _nearestPlaceName(pickupLatLng!);
      } catch (_) {
        pickupName = "موقع غير معروف";
      }
      emit(UserMapMoveState());
      return;
    }

    if (dropoffLatLng == null) {
      dropoffLatLng = cameraCenter;
      dropoffName = "جاري تحديد الاسم...";
      _refreshMarkers();
      await drawRouteOnRoads();
      emit(UserMapMoveState());
      await _updateCameraAfterSelection();
      try {
        dropoffName = await _nearestPlaceName(dropoffLatLng!);
      } catch (_) {
        dropoffName = "موقع غير معروف";
      }
      emit(UserMapMoveState());
      return;
    }

    if (pickupLatLng != null && dropoffLatLng != null) {
      distanceKm = _calcDistanceKm(pickupLatLng!, dropoffLatLng!);
      emit(UserMapMoveState());
    }

    await _fitBothPoints();

    if (selectedServiceType == null) {
      emit(UserCreateRequestErrorState("حدد نوع الرحلة أولاً"));
      return;
    }

    final km = distanceKm ?? _calcDistanceKm(pickupLatLng!, dropoffLatLng!);

    await createRideRequest(
      distanceKm: km,
      durationMin: durationMin ?? 0,
    );
  }

  Future<void> _updateCameraAfterSelection() async {
    if (mapController == null) return;

    if (pickupLatLng != null && dropoffLatLng != null) {
      final swLat = (pickupLatLng!.latitude < dropoffLatLng!.latitude)
          ? pickupLatLng!.latitude
          : dropoffLatLng!.latitude;

      final swLng = (pickupLatLng!.longitude < dropoffLatLng!.longitude)
          ? pickupLatLng!.longitude
          : dropoffLatLng!.longitude;

      final neLat = (pickupLatLng!.latitude > dropoffLatLng!.latitude)
          ? pickupLatLng!.latitude
          : dropoffLatLng!.latitude;

      final neLng = (pickupLatLng!.longitude > dropoffLatLng!.longitude)
          ? pickupLatLng!.longitude
          : dropoffLatLng!.longitude;

      final bounds = LatLngBounds(
        southwest: LatLng(swLat, swLng),
        northeast: LatLng(neLat, neLng),
      );

      await mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    } else if (pickupLatLng != null) {
      await mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(pickupLatLng!, 14),
      );
    }
  }

  Future<void> checkActiveRide() async {
    emit(CheckActiveRideLoadingState());

    try {
      final value = await DioHelper.getData(
        url: "/ride-requests/active",
        token: token,
      );

      final data = value.data;

      if (data["hasActive"] == true && data["request"] != null) {
        final req = data["request"] as Map;

        final newId = req["id"].toString();
        final newStatus = (req["status"] ?? "pending").toString();

        if (activeRequestId == newId && rideStatus == "accepted" && newStatus == "pending") {
          emit(CheckActiveRideSuccessState());
          return;
        }

        estimatedFare = req["estimatedFare"]?.toString();
        activeRequestId = newId;
        rideStatus = newStatus;

        final did = (req["driver_id"] ?? "").toString();
        driverId = did.isNotEmpty ? did : null;

        if ((rideStatus == "accepted" || rideStatus == "arrived" || rideStatus == "started") &&
            driverId != null && driverId!.isNotEmpty) {
          await getDriverById(userId: driverId!);
        }

        final pLat = double.parse(req["pickupLat"].toString());
        final pLng = double.parse(req["pickupLng"].toString());
        final dLat = double.parse(req["dropoffLat"].toString());
        final dLng = double.parse(req["dropoffLng"].toString());

        pickupLatLng = LatLng(pLat, pLng);
        dropoffLatLng = LatLng(dLat, dLng);

        pickupName = req["pickupAddress"]?.toString();
        dropoffName = req["dropoffAddress"]?.toString();
        currentRequestServiceType = (req["serviceType"] ?? "normal").toString();
        if ((pickupName == null || pickupName!.trim().isEmpty) && pickupLatLng != null) {
          pickupName = await _nearestPlaceName(pickupLatLng!);
          await drawRouteOnRoads();
        }

        if ((dropoffName == null || dropoffName!.trim().isEmpty) && dropoffLatLng != null) {
          dropoffName = await _nearestPlaceName(dropoffLatLng!);
        }

        selectingPoint = SelectingPoint.dropoff;
        _refreshMarkers();

        emit(CheckActiveRideSuccessState());
        return;
      }

      activeRequestId = null;
      rideStatus = "idle";
      emit(CheckActiveRideSuccessState());
    } catch (error) {
      if (error is DioError) {
        debugPrint("checkActiveRide DioError: ${error.response?.data ?? error.message}");
        emit(CheckActiveErrorState(error.toString()));
      } else {
        debugPrint("checkActiveRide error: $error");
        emit(CheckActiveErrorState(error.toString()));
      }
    }
  }

  String googleApiKey = googleMapKey;


  void _drawStraightLine() {
    polylines.clear();

    if (pickupLatLng == null || dropoffLatLng == null) return;

    polylines.add(
      Polyline(
        polylineId: const PolylineId("route"),
        points: [pickupLatLng!, dropoffLatLng!],
        width: 5,
        color: secondPrimaryColor
      ),
    );

    emit(UserMapMoveState());
  }

  Future<void> drawRouteOnRoads() async {
    if (pickupLatLng == null || dropoffLatLng == null) return;

    try {
      final polylinePoints = PolylinePoints();

      final result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: googleApiKey,
        request: PolylineRequest(
          origin: PointLatLng(pickupLatLng!.latitude, pickupLatLng!.longitude),
          destination: PointLatLng(dropoffLatLng!.latitude, dropoffLatLng!.longitude),
          mode: TravelMode.driving,
        ),
      );

      debugPrint("Polyline status: ${result.status}");
      debugPrint("Polyline error: ${result.errorMessage}");
      debugPrint("Polyline points count: ${result.points.length}");

      if (result.points.isEmpty) {
        _drawStraightLine();
        return;
      }

      final routePoints = result.points
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();

      polylines
        ..clear()
        ..add(Polyline(
          polylineId: const PolylineId("route"),
          points: routePoints,
          width: 5,
          color: secondPrimaryColor
        ));

      emit(UserMapMoveState());
    } catch (e) {
      debugPrint("drawRouteOnRoads exception: $e");
      _drawStraightLine();
    }
  }

  // ====== SOCKET ======
  void _connectSocket() {
    const socketUrl = "https://redosyria.napoltech.com";

    _socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setPath('/socket.io/')
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) async  {
      socketConnected = true;
      emit(UserSocketConnectedState());
      await checkActiveRide();
    });

    _socket!.onDisconnect((reason) {
      socketConnected = false;
      debugPrint("⚠️ socket disconnected: $reason");
      emit(UserSocketDisconnectedState());
    });

    _socket!.onConnectError((err) {
      socketConnected = false;
      debugPrint("❌ connect_error: $err");
      emit(UserSocketErrorState("connect_error: $err"));
    });

    _socket!.on("request:accepted", (data) async {
      try {
        if (data is! Map) return;

        final reqId = (data["requestId"] ?? "").toString();
        final did = (data["driverId"] ?? "").toString();
        if (reqId.isEmpty) return;

        activeRequestId = reqId;

        rideStatus = "accepted";
        driverId = did;

        _playDriverAcceptedOnce();

        if (driverId != null && driverId!.isNotEmpty) {
          await getDriverById(userId: driverId!);
        }

        if (driverLatLng != null && pickupLatLng != null) {
          await drawRouteBetween(driverLatLng!, pickupLatLng!);
        }

        emit(UserRideStatusChangedState("accepted"));
        emit(UserMapMoveState());
      } catch (e) {
        debugPrint("request:accepted handler error: $e");
      }
    });

    _socket!.on("trip:status_changed", (data) async {
      try {
        debugPrint("✅ trip:status_changed => $data");
        if (data is! Map) return;

        final reqId = (data["requestId"] ?? "").toString();
        final status = (data["status"] ?? "").toString();

        if (activeRequestId != null && reqId.isNotEmpty && activeRequestId != reqId) return;

        rideStatus = status;
        if (status == "accepted") {
          if (driverLatLng != null && pickupLatLng != null) {
            await drawRouteBetween(driverLatLng!, pickupLatLng!);
          }
        }
        if (status == "arrived") {
          _playDriverArrivedOnce();
        }

        if (status == "arrived" || status == "started") {
          if (pickupLatLng != null && dropoffLatLng != null) {
            await drawRouteBetween(pickupLatLng!, dropoffLatLng!);
          }
        }

        emit(UserRideStatusChangedState(status));

        if (status == "completed") {
          activeRequestId = null;
          driverModel = null;
          driverId = null;

          estimatedFare = null;
          distanceKm = null;
          durationMin = null;

          currentRequestServiceType = "normal";
          selectedServiceType = null;

          pickupLatLng = null;
          dropoffLatLng = null;
          pickupName = null;
          dropoffName = null;
          selectingPoint = SelectingPoint.pickup;

          markers.clear();
          polylines.clear();

          if (mapController != null && currentLatLng != null) {
            await mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(currentLatLng!, 15),
            );
          }

          emit(UserMapMoveState());
        }
      } catch (e) {
        debugPrint("trip:status_changed handler error: $e");
      }
    });

    _socket!.on("trip:driver_location", (data) async {
      if (data is! Map) return;

      final reqId = (data["requestId"] ?? "").toString();

      if (activeRequestId != null && reqId.isNotEmpty && activeRequestId != reqId) return;

      final lat = double.tryParse(data["lat"].toString());
      final lng = double.tryParse(data["lng"].toString());
      if (lat == null || lng == null) return;

      driverLatLng = LatLng(lat, lng);
      _refreshMarkers();

      if ((rideStatus == "accepted" || rideStatus == "pending") && pickupLatLng != null) {
        await drawRouteBetween(driverLatLng!, pickupLatLng!);
      }

      emit(UserMapMoveState());
    });


    _socket!.connect();
  }

  String currentRequestServiceType = "normal";

  Future<void> createRideRequest({required double distanceKm, required int durationMin,}) async {
    if (!socketConnected || _socket?.connected != true) {
      emit(UserCreateRequestErrorState("تحقق من اتصالك بالانترنت"));
      return;
    }

    if (pickupLatLng == null || dropoffLatLng == null) {
      emit(UserCreateRequestErrorState("حدد نقطة الانطلاق والوصول"));
      return;
    }

    if (pickupName == null || pickupName!.trim().isEmpty || pickupName == "جاري تحديد الاسم...") {
      try { pickupName = await _nearestPlaceName(pickupLatLng!); } catch (_) {}
    }
    if (dropoffName == null || dropoffName!.trim().isEmpty || dropoffName == "جاري تحديد الاسم...") {
      try { dropoffName = await _nearestPlaceName(dropoffLatLng!); } catch (_) {}
    }

    emit(UserCreatingRequestState());

    final payload = {
      "pickup": {
        "lat": pickupLatLng!.latitude,
        "lng": pickupLatLng!.longitude,
        "address": pickupName,
      },
      "dropoff": {
        "lat": dropoffLatLng!.latitude,
        "lng": dropoffLatLng!.longitude,
        "address": dropoffName,
      },
      "distanceKm": distanceKm,
      "durationMin": durationMin,
      "serviceType": selectedServiceType!.value,
    };

    _socket!.emitWithAck("rider:create_request", payload, ack: (data) {
      debugPrint("✅ ACK DATA = $data");
      if (data == null) {
        emit(UserCreateRequestErrorState("ماكو رد من السيرفر"));
        return;
      }

      final err = (data is Map) ? data["message"] ?? data["error"] : null;
      if (err != null) {
        debugPrint("❌ create request error: $err");
        emit(UserCreateRequestErrorState(err.toString()));
        return;
      }

      final req = (data is Map) ? data["request"] : null;
      final requestId = (req is Map ? req["id"] : null)?.toString() ?? "";

      if (requestId.isEmpty) {
        emit(UserCreateRequestErrorState("فشل إنشاء الطلب (id غير موجود)"));
        return;
      }

      estimatedFare = (req is Map ? req["estimatedFare"] : null)?.toString();
      activeRequestId = requestId;
      rideStatus = "pending";
      driverModel = null;
      driverId = null;
      currentRequestServiceType = selectedServiceType!.value;
      emit(UserRequestCreatedState(requestId));
    });
  }


  void cancelRideRequest() {
    if (!socketConnected || activeRequestId == null) return;

    _socket!.emit("rider:cancel_request", {"requestId": activeRequestId});
    driverModel = null;
    driverId = null;

    estimatedFare = null;
    activeRequestId = null;
    rideStatus = "idle";

    distanceKm = null;
    durationMin = null;
    selectedServiceType = null;

    pickupLatLng = null;
    dropoffLatLng = null;

    pickupName = null;
    dropoffName = null;

    selectingPoint = SelectingPoint.pickup;

    markers.clear();
    if (mapController != null && currentLatLng != null) {
      mapController!.animateCamera(CameraUpdate.newLatLngZoom(currentLatLng!, 15));
    }

    polylines.clear();
    currentRequestServiceType = "normal";
    selectedServiceType = null;
    emit(UserRideStatusChangedState("cancelled"));
    emit(UserMapMoveState());
  }

  // ── طريقة الدفع التي يختارها الزبون ────────────────────────────────────
  String selectedPaymentMethod = 'cash'; // 'cash' | 'online'
  bool paymentDoneOnline = false; // تم الدفع أونلاين بنجاح

  void selectPaymentMethod(String method) {
    selectedPaymentMethod = method;
    emit(UserPaymentSelectedState(method));
  }

  /// دفع أونلاين - يرسل للباكند ويتحقق من الرصيد
  Future<void> payOnlineRide() async {
    if (activeRequestId == null) return;
    emit(UserCompleteRideLoadingState());
    try {
      await DioHelper.postData(
        url: '/ride-requests/$activeRequestId/complete',
        data: {
          'paymentMethod': 'online',
          'finalFare': double.tryParse(estimatedFare ?? '0') ?? 0,
        },
        token: token,
      );
      paymentDoneOnline = true;
      // أبلغ السائق بأن الزبون دفع أونلاين
      _socket?.emit('rider:payment_online', {'requestId': activeRequestId});
      emit(UserPaymentPendingDriverState());
    } on DioError catch (e) {
      final statusCode = e.response?.statusCode;
      final msg = e.response?.data?['message']?.toString() ?? '';
      if (statusCode == 402 || msg.toLowerCase().contains('insufficient') || msg.contains('رصيد')) {
        emit(UserInsufficientBalanceState());
      } else {
        emit(UserCompleteRideErrorState(msg.isNotEmpty ? msg : e.message ?? 'حدث خطأ'));
      }
    } catch (e) {
      emit(UserCompleteRideErrorState(e.toString()));
    }
  }

  /// كاش - لا إجراء مطلوب من الزبون (السائق ينهي الرحلة)
  Future<void> completeRideAsRider({required double finalFare}) async {
    if (activeRequestId == null) return;
    emit(UserCompleteRideLoadingState());
    try {
      await DioHelper.postData(
        url: '/ride-requests/$activeRequestId/complete',
        data: {
          'paymentMethod': selectedPaymentMethod,
          'finalFare': finalFare,
        },
        token: token,
      );
      emit(UserCompleteRideSuccessState());
    } on DioError catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message ?? '';
      emit(UserCompleteRideErrorState(msg));
    } catch (e) {
      emit(UserCompleteRideErrorState(e.toString()));
    }
  }


  final AudioPlayer _userPlayer = AudioPlayer();
  bool _acceptedSoundPlayed = false;
  bool _arrivedSoundPlayed = false;

  Future<void> _setupAudio() async {
    await _userPlayer.setAudioContext(
      AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.notification,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
      ),
    );
  }

  Future<void> _playDriverAcceptedOnce() async {
    if (_acceptedSoundPlayed) return;
    _acceptedSoundPlayed = true;

    try {
      await _userPlayer.stop();
      await _userPlayer.setReleaseMode(ReleaseMode.stop);
      await _userPlayer.setVolume(1.0);
      await _userPlayer.play(AssetSource('sounds/acceptdiver.mp3'));
      debugPrint("🔔 USER: driver accepted sound played");
    } catch (e) {
      debugPrint("❌ USER play accepted sound error: $e");
    }
  }

  Future<void> _playDriverArrivedOnce() async {
    if (_arrivedSoundPlayed) return;
    _arrivedSoundPlayed = true;

    try {
      await _userPlayer.stop();
      await _userPlayer.setReleaseMode(ReleaseMode.stop);
      await _userPlayer.setVolume(1.0);
      await _userPlayer.play(AssetSource('sounds/arrivedriver.mp3'));
    } catch (e) {
      debugPrint("❌ USER play arrived sound error: $e");
    }
  }

  @override
  Future<void> close() {
    searchController.dispose();
    sheetController.dispose();
    _userPlayer.dispose();
    _socket?.dispose();
    return super.close();
  }


}