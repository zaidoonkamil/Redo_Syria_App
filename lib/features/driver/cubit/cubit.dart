import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:rido_syria_app/core/%20navigation/navigation.dart';
import 'package:rido_syria_app/core/network/remote/dio_helper.dart';
import 'package:rido_syria_app/features/auth/view/login.dart';
import 'package:rido_syria_app/features/driver/model/DriverOrderModel.dart';
import 'package:rido_syria_app/features/driver/model/ProfileModel.dart';
import 'package:rido_syria_app/features/driver/model/RiderModel.dart';

import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

import '../../../core/widgets/constant.dart';
import '../../../core/widgets/show_toast.dart';
import '../../admin/model/AdminDebtSettingsModel.dart';
import 'states.dart';

class DriverCubit extends Cubit<DriverStates> {
  DriverCubit() : super(DriverInitialState());

  static DriverCubit get(context) => BlocProvider.of(context);

  GoogleMapController? mapController;

  LatLng? currentLatLng;

  final Set<Marker> markers = {};
  final Set<Polyline> polylines = {};

  BitmapDescriptor? driverIcon;

  LatLng? pickupLatLng;
  LatLng? dropoffLatLng;

  BitmapDescriptor? pickupIcon;
  BitmapDescriptor? dropoffIcon;

  String googleApiKey = googleMapKey;

  IO.Socket? _socket;
  bool socketConnected = false;

  bool isOnline = false;
  bool walletBlocked = false;   // بدل debtBlocked
  double walletBalance = 0.0;   // آخر رصيد معروف للسائق

  Timer? _locationTimer;

  double? tripDistanceKm;
  double? driverToPickupKm;

  final List<Map<String, dynamic>> pendingRequests = [];

  final DraggableScrollableController sheetController =
  DraggableScrollableController();

  Future<void> _loadCustomIcons() async {
    pickupIcon  = await loadResizedMarker('assets/images/pick2.png', 50);
    dropoffIcon = await loadResizedMarker('assets/images/drop2.png', 50);
  }

  Future<void> _loadDriverIcon() async {
    driverIcon = await loadResizedMarker('assets/images/gps.png', 68);
  }

  Future<BitmapDescriptor> loadResizedMarker(String assetPath, int width) async {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    final frame = await codec.getNextFrame();
    final bytes = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

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
      print("🎛 sheet attached=${sheetController.isAttached} -> to $size");

      if (tries >= 10) return;
      Future.delayed(const Duration(milliseconds: 50), () => tryAnimate(tries + 1));
    }

    tryAnimate();
  }
  void openPendingSheet() => _animateSheet(0.45);
  void lockActiveTripSheet() => _animateSheet(0.62);
  void collapseSheet() => _animateSheet(0.2);


  Map<String, dynamic>? activeTripRequest;
  String? activeRequestId;
  String? activeRiderId;

  String tripStatus = "idle";

  final String socketUrl = url;

  Future<void> init() async {
    await _setupAudio();
    await _loadDriverIcon();
    await _loadCustomIcons();
    await _getCurrentLocation();
    await checkActiveTrip();
    _connectSocket();
  }

  void _attachKmToRequest(Map<String, dynamic> req) {
    try {
      final p = req["pickup"];
      final d = req["dropoff"];
      if (p is! Map || d is! Map) return;

      final pickup = LatLng(
        (p["lat"] as num).toDouble(),
        (p["lng"] as num).toDouble(),
      );

      final dropoff = LatLng(
        (d["lat"] as num).toDouble(),
        (d["lng"] as num).toDouble(),
      );

      req["tripKm"] = _calcDistanceKm(pickup, dropoff);

      if (currentLatLng != null) {
        req["toPickupKm"] = _calcDistanceKm(currentLatLng!, pickup);
      } else {
        req["toPickupKm"] = null;
      }
    } catch (_) {}
  }

  double _calcDistanceKm(LatLng a, LatLng b) {
    final meters = Geolocator.distanceBetween(
      a.latitude, a.longitude,
      b.latitude, b.longitude,
    );
    return meters / 1000.0;
  }

  void _recalcDistances() {
    if (pickupLatLng != null && dropoffLatLng != null) {
      tripDistanceKm = _calcDistanceKm(pickupLatLng!, dropoffLatLng!);
    } else {
      tripDistanceKm = null;
    }

    if (currentLatLng != null && pickupLatLng != null) {
      driverToPickupKm = _calcDistanceKm(currentLatLng!, pickupLatLng!);
    } else {
      driverToPickupKm = null;
    }
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (currentLatLng != null) {
      mapController!.animateCamera(CameraUpdate.newLatLngZoom(currentLatLng!, 15));
    }
  }

  Future<void> _getCurrentLocation() async {
    emit(DriverLoadingLocationState());
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        emit(DriverLocationErrorState("فعّل GPS حتى نكدر نحدد موقعك"));
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        emit(DriverLocationErrorState("صلاحية الموقع مرفوضة نهائياً. افتحها من الإعدادات"));
        return;
      }
      if (perm == LocationPermission.denied) {
        emit(DriverLocationErrorState("صلاحية الموقع مرفوضة"));
        return;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      currentLatLng = LatLng(pos.latitude, pos.longitude);
      _recalcDistances();
      if ((tripStatus == "accepted" || tripStatus == "pending") && pickupLatLng != null) {
        await drawRouteBetween(currentLatLng!, pickupLatLng!);
      }
      emit(DriverMapUpdatedState());

      _refreshDriverMarker();
      emit(DriverLocationReadyState());
    } catch (e) {
      emit(DriverLocationErrorState("خطأ بالموقع: $e"));
    }
  }

  DriverOrderModel? driverOrderModel;
  void getDriverOrder({required BuildContext context,required String driverId}) {
    emit(DriverOrderLoadingState());
    DioHelper.getData(
      url: '/ride-requests/driver/$driverId',
    ).then((value) {
      driverOrderModel = DriverOrderModel.fromJson(value.data);
      emit(DriverOrderSuccessState());
    }).catchError((error) {
      if (error is DioError) {
        showSnackBarError(text: error.toString(), context: context,);
        print(error.toString());
        emit(DriverOrderErrorState());
      }else {
        print("Unknown Error: $error");
      }
    });
  }

  void _clearActiveTrip({bool keepDriverMarker = true}) {
    activeTripRequest = null;
    activeRequestId = null;
    activeRiderId = null;
    riderModel = null;
    tripStatus = "idle";
    tripDistanceKm = null;
    driverToPickupKm = null;

    if (keepDriverMarker) {
      markers.removeWhere((m) => m.markerId.value != "driver");
    } else {
      markers.clear();
    }

    polylines.clear();
    emit(DriverRequestClearedState());
    emit(DriverMapUpdatedState());
  }

  ProfileModel? profileModel;
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

  bool isTogglingOnline = false;

  void _refreshDriverMarker() {
    // if (currentLatLng == null) return;
    //
    // markers.removeWhere((m) => m.markerId.value == "driver");
    //
    // markers.add(
    //   Marker(
    //     markerId: const MarkerId("driver"),
    //     position: currentLatLng!,
    //     infoWindow: const InfoWindow(title: "السائق"),
    //     icon: driverIcon ?? BitmapDescriptor.defaultMarker,
    //     anchor: const Offset(0.5, 0.8),
    //   ),
    // );
    // emit(DriverMapUpdatedState());

    return ;
  }

  void rejectCurrentRequest() {
    _stopRingtone();
    if (!socketConnected) return;
    if (activeRequestId == null) return;

    _socket!.emit("driver:reject_request", {"requestId": activeRequestId});

    tripStatus = "idle";
    _clearActiveTrip();
    emit(DriverTripStatusChangedState("rejected"));
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  Future<void> checkActiveTrip() async {
    emit(DriverCheckActiveTripLoadingState());

    try {
      final value = await DioHelper.getData(
        url: "/ride-requests/active",
        token: token,
      );
      final data = value.data;
      if (data["hasActive"] == true && data["request"] != null) {
        final req = Map<String, dynamic>.from(data["request"]);

        activeRequestId = req["id"].toString();
        tripStatus = (req["status"] ?? "idle").toString();

        activeTripRequest = {
          "requestId": req["id"]?.toString(),
          "estimatedFare": req["estimatedFare"]?.toString(),
          "riderId": req["rider_id"]?.toString(),
          "serviceType": (req["serviceType"] ?? "normal").toString(),
          "pickup": {
            "lat": _toDouble(req["pickupLat"]),
            "lng": _toDouble(req["pickupLng"]),
            "address": (req["pickupAddress"] ?? "").toString(),
          },
          "dropoff": {
            "lat": _toDouble(req["dropoffLat"]),
            "lng": _toDouble(req["dropoffLng"]),
            "address": (req["dropoffAddress"] ?? "").toString(),
          },
        };

        pendingRequests.clear();

        _setRequestMarkersFromData(activeTripRequest!);
        _recalcDistances();
        activeRiderId = (activeTripRequest!["riderId"] ?? "").toString();
        if (activeRiderId != null && activeRiderId!.isNotEmpty) {
          await getRiderById(riderId: activeRiderId!);
        }

        if (tripStatus == "accepted" || tripStatus == "arrived" || tripStatus == "started") {
          lockActiveTripSheet();
        } else {
          collapseSheet();
        }

        emit(DriverTripStatusChangedState(tripStatus));
        emit(DriverCheckActiveTripSuccessState());
        return;
      }

      _clearActiveTrip();
      emit(DriverCheckActiveTripSuccessState());
    } catch (e) {
      emit(DriverCheckActiveTripErrorState(e.toString()));
    }
  }


  // ===== SOCKET =====
  void _connectSocket() {
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
    _socket!.onAny((event, data) {
      print("📩 EVENT=$event | type=${data.runtimeType} | data=$data");
    });

    _socket!.onConnect((_) async {
      socketConnected = true;
      emit(DriverSocketConnectedState());
      await checkActiveTrip();
    });

    _socket!.onDisconnect((reason) {
      socketConnected = false;
      _stopLocationUpdates();
      isOnline = false;
      emit(DriverSocketDisconnectedState());
    });

    _socket!.onConnectError((err) {
      socketConnected = false;
      emit(DriverSocketErrorState("connect_error: $err"));
    });


    _socket!.on("trip:status_changed", (data) async  {
      if (data is! Map) return;

      final status = (data["status"] ?? "").toString();
      final reqId  = (data["requestId"] ?? "").toString();
      if (reqId.isEmpty) return;

      pendingRequests.removeWhere((e) => e["requestId"]?.toString() == reqId);
      if (status == "cancelled") {
        await _stopRingtone();
      }
      if (status == "cancelled") {
        if (activeRequestId != null && activeRequestId == reqId) {
          polylines.clear();

          _clearActiveTrip();
          collapseSheet();

          emit(DriverMapUpdatedState());
          emit(DriverTripStatusChangedState("cancelled"));
        }

        emit(DriverPendingUpdatedState());
        emit(DriverMapUpdatedState());
        return;
      }


      if (activeRequestId != null && activeRequestId == reqId) {
        tripStatus = status;
        if (status == "accepted") {
          if (currentLatLng != null && pickupLatLng != null) {
            await drawRouteBetween(currentLatLng!, pickupLatLng!);
          }
        }

        if (status == "arrived" || status == "started") {
          if (pickupLatLng != null && dropoffLatLng != null) {
            await drawRouteBetween(pickupLatLng!, dropoffLatLng!);
          }
        }

        if (status == "completed") {
          polylines.clear();
        }
        emit(DriverMapUpdatedState());

        emit(DriverTripStatusChangedState(status));
        emit(DriverMapUpdatedState());
      } else {
        // تحديثات تخص pending فقط
        emit(DriverPendingUpdatedState());
      }
    });

    _socket!.on("request:new", (data) {
      debugPrint("////////////////////////////");
      debugPrint("🔥 NEW REQUEST ARRIVED");
      if (data is! Map) return;

      final raw = Map<String, dynamic>.from(data);
      final inner = raw["request"] is Map ? Map<String, dynamic>.from(raw["request"]) : raw;

      final normalized = inner.containsKey("pickupLat")
          ? {
        "requestId": inner["id"]?.toString(),
        "estimatedFare": inner["estimatedFare"]?.toString(),
        "riderId": inner["rider_id"]?.toString(),
        "serviceType": (inner["serviceType"] ?? "normal").toString(),
        "pickup": {
          "lat": (inner["pickupLat"] as num).toDouble(),
          "lng": (inner["pickupLng"] as num).toDouble(),
          "address": (inner["pickupAddress"] ?? "").toString(),
        },
        "dropoff": {
          "lat": (inner["dropoffLat"] as num).toDouble(),
          "lng": (inner["dropoffLng"] as num).toDouble(),
          "address": (inner["dropoffAddress"] ?? "").toString(),
        },
      }
          : inner;

      final reqId = (normalized["requestId"] ?? "").toString();
      if (reqId.isEmpty) return;

      if (activeRequestId != null && tripStatus != "idle") return;

      _attachKmToRequest(normalized);

      final exists = pendingRequests.any((e) => e["requestId"]?.toString() == reqId);
      if (!exists) pendingRequests.add(normalized);
      _playNewRequestSound();
      emit(DriverNewRequestState());
    });

    _socket!.on("request:assigned", (data) {
      if (data is Map) {
        final status = (data["status"] ?? "assigned").toString();
        tripStatus = status;
        emit(DriverTripStatusChangedState(status));
      }
    });

    _socket!.on("driver:online_ack", (data) {
      if (data is Map) {
        walletBalance = (data['balance'] as num?)?.toDouble() ?? walletBalance;
      }
      emit(DriverOnlineChangedState());
    });

    _socket!.on("driver:wallet_blocked", (data) {
      walletBlocked = true;
      isOnline = false;
      _stopLocationUpdates();
      final balance = (data is Map ? (data['balance'] as num?)?.toDouble() : null) ?? 0.0;
      walletBalance = balance;
      final msg = (data is Map ? data['message'] : null)?.toString() ?? 'رصيد محفظتك صفر. يجب الشحن لاستقبال رحلات جديدة';
      emit(DriverWalletBlockedState(msg, balance: balance));
    });

    _socket!.on("trip:completed", (data) {
      if (data is! Map) return;
      final method = (data['paymentMethod'] ?? '').toString();
      final fare = (data['finalFare'] as num?)?.toDouble() ?? 0.0;
      final commission = (data['commission'] as num?)?.toDouble() ?? 0.0;
      final earnings = (data['driverEarnings'] as num?)?.toDouble() ?? 0.0;
      final newBal = (data['newBalance'] as num?)?.toDouble();
      if (newBal != null) walletBalance = newBal;

      emit(DriverTripCompletedState(
        paymentMethod: method,
        finalFare: fare,
        commission: commission,
        driverEarnings: earnings,
        newBalance: newBal,
      ));
    });

    _socket!.on("driver:debt_blocked", (data) {
      walletBlocked = true;
      isOnline = false;
      _stopLocationUpdates();
      final msg = (data is Map ? data["message"] : null)?.toString() ?? "رصيد محفظتك صفر";
      emit(DriverWalletBlockedState(msg));
    });

    _socket!.on("rider:payment_online", (data) {
      // الزبون دفع أونلاين - أبلغ السائق
      emit(DriverUserPaidOnlineState());
    });

    _socket!.connect();
  }

  Future<void> acceptRequest(String requestId) async {
    await _stopRingtone();
    if (!socketConnected) return;

    if (activeRequestId != null && tripStatus != "idle") return;

    final req = pendingRequests.firstWhere((e) => e["requestId"]?.toString() == requestId, orElse: () => {},);
    if (req.isEmpty) return;

    final riderId = (req["riderId"] ?? "").toString();

    _socket!.emit("driver:accept_request", {"requestId": requestId});

    activeTripRequest = req;
    activeRequestId = requestId;
    activeRiderId = riderId;
    tripStatus = "accepted";

    pendingRequests.clear();

    _setRequestMarkersFromData(activeTripRequest!);
    if (currentLatLng != null && pickupLatLng != null) {
      await drawRouteBetween(currentLatLng!, pickupLatLng!);
    }

    if (riderId.isNotEmpty) await getRiderById(riderId: riderId);

    emit(DriverTripStatusChangedState("accepted"));
    lockActiveTripSheet();

  }

  void rejectRequest(String requestId) {
    _stopRingtone();
    if (!socketConnected) return;

    _socket!.emit("driver:reject_request", {"requestId": requestId});
    pendingRequests.removeWhere((e) => e["requestId"]?.toString() == requestId);

    if (pendingRequests.isEmpty && activeRequestId == null) {
      collapseSheet();
    } else if (pendingRequests.isNotEmpty && tripStatus == "idle") {
      openPendingSheet();
    }

    emit(DriverTripStatusChangedState("rejected"));
  }


  void _setRequestMarkersFromData(Map<String, dynamic> req) {
    try {

      final p = req["pickup"];
      final d = req["dropoff"];

      if (p is Map && d is Map) {
        final pLat = (p["lat"] as num).toDouble();
        final pLng = (p["lng"] as num).toDouble();
        final dLat = (d["lat"] as num).toDouble();
        final dLng = (d["lng"] as num).toDouble();

        markers.removeWhere((m) => m.markerId.value == "pickup" || m.markerId.value == "dropoff");

        pickupLatLng = LatLng(pLat, pLng);
        dropoffLatLng = LatLng(dLat, dLng);

        _recalcDistances();

        markers.add(Marker(
          markerId: const MarkerId("pickup"),
          position: pickupLatLng!,
          infoWindow: InfoWindow(title: "نقطة البدء", snippet: (p["address"] ?? "").toString()),
          icon: pickupIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ));

        markers.add(Marker(
          markerId: const MarkerId("dropoff"),
          position: dropoffLatLng!,
          infoWindow: InfoWindow(title: "نقطة الوصول", snippet: (d["address"] ?? "").toString()),
          icon: dropoffIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ));
        _refreshDriverMarker();
        emit(DriverMapUpdatedState());
      }
    } catch (_) {}
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

      debugPrint("Polyline status: ${result.status}");
      debugPrint("Polyline error: ${result.errorMessage}");
      debugPrint("Polyline points count: ${result.points.length}");

      final points = result.points.isEmpty
          ? [origin, destination]
          : result.points.map((p) => LatLng(p.latitude, p.longitude)).toList();

      polylines
        ..clear()
        ..add(Polyline(
          polylineId: const PolylineId("route"),
          points: points,
          width: 5,
          color: Colors.blue,
        ));

      emit(DriverMapUpdatedState());
    } catch (_) {
      polylines
        ..clear()
        ..add(Polyline(
          polylineId: const PolylineId("route"),
          points: [origin, destination],
          width: 5,
          color: Colors.blue,
        ));
      emit(DriverMapUpdatedState());
    }
  }


  // ===== ONLINE / OFFLINE =====
  Future<void> toggleOnline() async {
    if (!socketConnected) {
      emit(DriverSocketErrorState("تحقق من اتصالك بالانترنت"));
      return;
    }
    if (walletBlocked) {
      emit(DriverWalletBlockedState("رصيد محفظتك صفر. اشحنها لاستقبال طلبات", balance: walletBalance));
      return;
    }
    if (isTogglingOnline) return;

    isTogglingOnline = true;

    isOnline = !isOnline;
    emit(DriverOnlineChangedState());

    try {
      if (isOnline) {
        _socket!.emit("driver:online", {});

        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        currentLatLng = LatLng(pos.latitude, pos.longitude);

        _refreshDriverMarker();
        emit(DriverMapUpdatedState());

        _socket!.emitWithAck("driver:location", {
          "lat": pos.latitude,
          "lng": pos.longitude,
          "heading": pos.heading,
        }, ack: (res) {
          print("✅ driver:location ACK => $res");
        });

        _startLocationUpdates();
      } else {
        _socket!.emit("driver:offline", {});
        _stopLocationUpdates();
      }
    } catch (e) {
      if (isOnline) {
        isOnline = false;
        emit(DriverOnlineChangedState());
      }
      print("❌ toggleOnline error $e");
    } finally {
      isTogglingOnline = false;
    }
  }

  void _startLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        currentLatLng = LatLng(pos.latitude, pos.longitude);
        _recalcDistances();
        _refreshDriverMarker();
        if ((tripStatus == "accepted" || tripStatus == "pending") && pickupLatLng != null) {
          await drawRouteBetween(currentLatLng!, pickupLatLng!);
        }
        emit(DriverMapUpdatedState());

        if (socketConnected && isOnline) {
          _socket!.emitWithAck("driver:location", {
            "lat": pos.latitude,
            "lng": pos.longitude,
            "heading": pos.heading,
          }, ack: (res) {
            print("✅ driver:location ACK => $res");
          });

        }
      } catch (_) {}
    });
  }

  void _stopLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  RiderModel? riderModel;
  String? riderId;
  Future<void> getRiderById({required String riderId}) async {
    try {
      final value = await DioHelper.getData(url: '/user/$riderId');
      riderModel = RiderModel.fromJson(value.data);
      emit(DriverMapUpdatedState());
    } catch (e) {
      debugPrint("getRiderById error: $e");
    }
  }

  void acceptCurrentRequest() async {
    if (!socketConnected) return;
    if (activeRequestId == null) return;

    _socket!.emit("driver:accept_request", {"requestId": activeRequestId});
    tripStatus = "accepted";

    final id = activeRiderId;
    if (id != null && id.isNotEmpty) {
      await getRiderById(riderId: id);
    }

    emit(DriverTripStatusChangedState("accepted"));
  }

  void arrivedToPickup() {
    if (!socketConnected || activeRequestId == null) return;
    _socket!.emit("driver:arrived", {"requestId": activeRequestId});
    tripStatus = "arrived";
    if (pickupLatLng != null && dropoffLatLng != null) {
      drawRouteBetween(pickupLatLng!, dropoffLatLng!);
    }

    emit(DriverTripStatusChangedState("arrived"));
  }

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

  void startTrip() {
    if (!socketConnected || activeRequestId == null) return;
    _socket!.emit("driver:start_trip", {"requestId": activeRequestId});
    tripStatus = "started";
    if (pickupLatLng != null && dropoffLatLng != null) {
      drawRouteBetween(pickupLatLng!, dropoffLatLng!);
    }
    emit(DriverTripStatusChangedState("started"));
  }

  /// إنهاء الرحلة - طريقة الدفع تختارها الزبون من جهته
  void endTrip() {
    if (!socketConnected || activeRequestId == null) return;
    _socket!.emit("driver:end_trip", {"requestId": activeRequestId});

    tripStatus = "completed";
    _clearActiveTrip();
    emit(DriverTripStatusChangedState("completed"));
  }

  final AudioPlayer _player = AudioPlayer();
  bool _isRingtonePlaying = false;

  Future<void> _setupAudio() async {
    await _player.setAudioContext(
      AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.notificationRingtone,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
      ),
    );
  }

  Future<void> _playNewRequestSound() async {
    if (_isRingtonePlaying) return;
    _isRingtonePlaying = true;

    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(1.0);
      await _player.play(AssetSource('sounds/alirt-driver.mp3'));
      debugPrint("🔊 PLAYING RINGTONE");
    } catch (_) {}

    Future.delayed(const Duration(seconds: 2), () {
      _isRingtonePlaying = false;
    });
  }

  Future<void> _stopRingtone() async {
    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.stop);
    } catch (e) {
      debugPrint("❌ stop error: $e");
    }
    _isRingtonePlaying = false;
  }

  double? commissionValue;
  String? commissionType;

  void getCommissionSettings({required BuildContext context}) {
    emit(WalletSettingsLoadingState());
    DioHelper.getData(
        url: '/admin/debt/settings',
    ).then((value) {
      final data = value.data;
      commissionValue = double.tryParse(data['commissionValue']?.toString() ?? '');
      commissionType = data['commissionType']?.toString();
      emit(WalletSettingsSuccessState());
    }).catchError((error) {
      emit(WalletSettingsErrorState());
    });
  }

  @override
  Future<void> close() {
    _stopLocationUpdates();
    _socket?.dispose();
    sheetController.dispose();
    _player.dispose();
    return super.close();
  }

}
