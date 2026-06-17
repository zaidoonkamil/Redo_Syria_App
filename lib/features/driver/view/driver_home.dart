import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:rido_syria_app/core/widgets/constant.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:rido_syria_app/core/styles/themes.dart';
import 'package:rido_syria_app/core/widgets/CustomButton.dart';
import 'package:rido_syria_app/core/widgets/show_toast.dart';
import 'package:rido_syria_app/features/driver/view/profile.dart';

import '../../../core/ navigation/navigation.dart';
import '../../user/view/notifications.dart';
import '../cubit/cubit.dart';
import '../cubit/states.dart';

class DriverHome extends StatelessWidget {
  const DriverHome({super.key, required this.cubit});

  final DriverCubit cubit;

  String _serviceLabel(String? serviceType) {
    return (serviceType ?? 'normal').toLowerCase() == 'vip' ? 'VIP' : 'عادي';
  }

  Color _serviceColor(String? serviceType) {
    return (serviceType ?? 'normal').toLowerCase() == 'vip'
        ? Colors.amber.shade800
        : primaryColor;
  }

  String getStatusArabic(String status) {
    switch (status) {
      case "accepted":
        return "مقبولة";
      case "completed":
        return "مكتملة";
      case "pending":
        return "قيد الانتظار";
      case "canceled":
        return "ملغية";
      case "arrived":
        return "وصلت";
      case "started":
        return "بدأت";
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: BlocConsumer<DriverCubit, DriverStates>(
        listener: (context, state) {
          if (state is DriverNewRequestState) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              DriverCubit.get(context).openPendingSheet();
            });
          }
          if (state is DriverPendingUpdatedState) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final c = DriverCubit.get(context);

              if (c.pendingRequests.isEmpty && c.activeRequestId == null) {
                c.collapseSheet();
              } else if (c.pendingRequests.isNotEmpty && c.tripStatus == "idle") {
                c.openPendingSheet();
              }
            });
          }

          if (state is DriverTripStatusChangedState) {
            if (state.status == "accepted" || state.status == "arrived" || state.status == "started") {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                DriverCubit.get(context).lockActiveTripSheet();
              });
            }

            if (state.status == "completed" || state.status == "cancelled" || state.status == "rejected") {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                DriverCubit.get(context).collapseSheet();
              });
            }
          }

          if (state is DriverLocationErrorState) {
            showSnackBarError(text: state.message, context: context);
          } else if (state is DriverSocketErrorState) {
            showSnackBarError(text: state.message, context: context);
          } else if (state is DriverWalletBlockedState) {
            showSnackBarError(text: state.message, context: context);
          } else if (state is DriverNewRequestState) {
            showSnackBarSuccess(text: "وصل طلب جديد", context: context);
          } else if (state is DriverTripStatusChangedState && state.status == "cancelled") {
            showSnackBarInfo(text: "الزبون لغى الطلب", context: context);
          } else if (state is DriverTripStatusChangedState && state.status == "rejected") {
            showSnackBarInfo(text: "تم رفض الطلب", context: context);
          } else if (state is DriverTripStatusChangedState) {
            showSnackBarInfo(text: "الحالة: ${getStatusArabic(state.status)}", context: context);
          } else if (state is DriverTripCompletedState) {
            _showTripSummaryDialog(context, state);
          } else if (state is DriverUserPaidOnlineState) {
            showSnackBarSuccess(
              text: "✔ الزبون دفع أونلاين - يمكنك إنهاء الرحلة الآن",
              context: context,
            );
          }
        },
        builder: (context, state) {
          final cubit = DriverCubit.get(context);
          final double minSize = 0.20;
          final double maxSize = 0.62;
          final double initialSize = 0.20;

          return Container(
            color: Colors.white,
            child: SafeArea(
              child: Scaffold(
                body: Stack(
                  children: [
                    Positioned.fill(child: _buildMap(cubit, state)),
                    Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.18,
                      padding: const EdgeInsets.only(top: 16, bottom: 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            primaryColor.withOpacity(0.35),
                            primaryColor.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _circleIcon(Iconsax.profile_circle, () {
                            navigateTo(context, const ProfileDriver());
                          }),

                          Text(
                            nameApp,
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                          _circleIcon(Iconsax.notification, () {
                            navigateTo(context, Notifications());
                          }),
                        ],
                      ),
                    ),

                    DraggableScrollableSheet(
                      controller: cubit.sheetController,
                      initialChildSize: initialSize,
                      minChildSize: minSize,
                      maxChildSize: maxSize,
                      snap: true,
                      snapSizes: const [0.20, 0.45, 0.62],
                      builder: (context, scrollController) {
                        return _bottomPanel(context, cubit, scrollController);
                      },
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMap(DriverCubit cubit, DriverStates state) {
    if (state is DriverLoadingLocationState && cubit.currentLatLng == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final initial = cubit.currentLatLng ?? const LatLng(33.3152, 44.3661);

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: initial, zoom: 15),
      onMapCreated: cubit.onMapCreated,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      markers: cubit.markers,
      polylines: cubit.polylines,
    );
  }

  Widget _bottomPanel(BuildContext context, DriverCubit cubit, ScrollController scrollController) {
    final activeReq = cubit.activeTripRequest;
    final pending = cubit.pendingRequests;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            const SizedBox(height: 10),

            cubit.riderModel != null ? Container() : Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // شارة رصيد المحفظة
                    // cubit.isOnline ? Container(
                    //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    //   decoration: BoxDecoration(
                    //     color: cubit.walletBalance > 0
                    //         ? Colors.green.withOpacity(0.12)
                    //         : Colors.red.withOpacity(0.12),
                    //     borderRadius: BorderRadius.circular(20),
                    //     border: Border.all(
                    //       color: cubit.walletBalance > 0 ? Colors.green : Colors.redAccent,
                    //       width: 0.8,
                    //     ),
                    //   ),
                    //   child: Row(
                    //     mainAxisSize: MainAxisSize.min,
                    //     children: [
                    //       Icon(
                    //         Iconsax.wallet,
                    //         size: 14,
                    //         color: cubit.walletBalance > 0 ? Colors.green : Colors.redAccent,
                    //       ),
                    //       const SizedBox(width: 5),
                    //       Text(
                    //         '${cubit.walletBalance.toStringAsFixed(0)} IQD',
                    //         style: TextStyle(
                    //           fontWeight: FontWeight.bold,
                    //           fontSize: 12,
                    //           color: cubit.walletBalance > 0 ? Colors.green : Colors.redAccent,
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ):Container(),
                    Text(
                      cubit.isOnline ? "قيد العمل" : 'في الاستراحة',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(
                        cubit.isOnline ? "Online" : "Offline",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cubit.isOnline ? Colors.green : Colors.redAccent,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(width: double.infinity, height: 2, color: borderColor),
              ],
            ),

            const SizedBox(height: 10),
            if (activeReq == null && pending.isEmpty) ...[
              const SizedBox(height: 10),
              CustomButton(
                title: cubit.isTogglingOnline
                    ? "جاري التحديث..."
                    : (cubit.isOnline ? "إيقاف استقبال الطلبات" : "تشغيل استقبال الطلبات"),
                onPressed: cubit.isTogglingOnline ? () {} : cubit.toggleOnline,
                color: cubit.isOnline ? Colors.redAccent : primaryColor,
              ),
            ]
            else if (activeReq == null && pending.isNotEmpty) ...[
              ...pending.map((req) {
                final requestId = (req["requestId"] ?? "").toString();
                return Column(
                  children: [
                    _requestInfo(cubit, req,context),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            title: "رفض",
                            onPressed: () => cubit.rejectRequest(requestId),
                            color: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CustomButton(
                            title: "قبول الطلب",
                            onPressed: () => cubit.acceptRequest(requestId),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                );
              }).toList(),
            ]else ...[
              if ((cubit.tripStatus == "accepted" || cubit.tripStatus == "arrived" || cubit.tripStatus == "started") &&
                  cubit.riderModel != null) ...[
                _riderInfoCard(cubit),
                const SizedBox(height: 10),
                Container(width: double.infinity, height: 2, color: borderColor),
                const SizedBox(height: 10),
              ],
              _requestInfo(cubit, activeReq!,context),
              const SizedBox(height: 12),
              _tripActions(cubit,context),
              const SizedBox(height: 12),
              _buildNavigateButton(context, cubit, activeReq),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildNavigateButton(
      BuildContext context,
      DriverCubit cubit,
      Map<String, dynamic> activeReq,
      ) {
    Map<String, dynamic>? target;
    String title = "الوجهة";

    if (cubit.tripStatus == "accepted") {
      target = activeReq["pickup"] as Map<String, dynamic>?;
      title = "نقطة الانطلاق";
    }


    if (cubit.tripStatus == "arrived" || cubit.tripStatus == "started") {
      target = activeReq["dropoff"] as Map<String, dynamic>?;
      title = "نقطة الوصول";
    }

    if (target == null) return const SizedBox.shrink();

    return CustomButton(
      title: "توجيه عبر تطبيق خرائط",
      onPressed: () {
        openDirectionsChooser(
          context: context,
          lat: (target!["lat"] as num).toDouble(),
          lng: (target["lng"] as num).toDouble(),
          title: title,
        );
      },
    );
  }

  Future<void> openDirectionsChooser({required BuildContext context, required double lat, required double lng, String? title,}) async {
    try {
      final maps = await MapLauncher.installedMaps;

      if (maps.isEmpty) {
        showSnackBarError(text: "ماكو تطبيق خرائط مثبت", context: context);
        return;
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 92,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: maps.length,
                      reverse: true,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) {
                        final m = maps[i];
                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () async {
                            Navigator.pop(context);
                            await m.showDirections(
                              destination: Coords(lat, lng),
                              destinationTitle: title ?? "الوجهة",
                              directionsMode: DirectionsMode.driving,
                            );
                          },
                          child: Container(
                            width: 110,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.black12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildMapIcon(m, size: 34),
                                const SizedBox(height: 8),
                                Text(
                                  m.mapName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("إلغاء"),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      print(e);
      showSnackBarError(text: "صار خطأ بفتح الخرائط: $e", context: context);
    }
  }


  Widget _riderInfoCard(DriverCubit cubit) {
    final rider = cubit.riderModel;
    if (rider == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: primaryColor.withOpacity(0.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                Text('معلومات الزبون', style: TextStyle(fontSize: 13)),
                SizedBox(width: 6),
                Icon(Iconsax.user, color: primaryColor),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  final uri = Uri.parse('tel:${rider.phone}');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
                child: const Icon(Iconsax.call, color: primaryColor),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(rider.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(rider.phone),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                height: 50,
                width: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(Iconsax.user, color: primaryColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _requestInfo(DriverCubit cubit, Map<String, dynamic> req, BuildContext context) {
    final p = (req["pickup"] is Map) ? req["pickup"] as Map : {};
    final d = (req["dropoff"] is Map) ? req["dropoff"] as Map : {};
    final fare = (req["estimatedFare"] ?? "").toString().trim();
    final serviceType = (req["serviceType"] ?? "normal").toString();
    final tripKm = (req["tripKm"] as num?)?.toDouble() ?? cubit.tripDistanceKm;
    final toPickupKm = (req["toPickupKm"] as num?)?.toDouble() ?? cubit.driverToPickupKm;

    final showToPickup = (cubit.tripStatus == "accepted" || cubit.tripStatus == "pending") && toPickupKm != null;
    final showTripKm = tripKm != null;

    final hasLeft = showToPickup || showTripKm;
    final hasFare = fare.isNotEmpty;
    final isActiveTrip = cubit.activeRequestId == (req['requestId'] ?? '').toString() && cubit.activeRequestId != null;

    String pickupText = (p["address"] ?? "—").toString().trim();
    String dropoffText = (d["address"] ?? "—").toString().trim();
    final bool twoLines = showToPickup && showTripKm;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: containerColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pickupText.isNotEmpty ? pickupText : "—",
                      maxLines: 1,
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "نقطة الانطلاق",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                      maxLines: 1,
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: borderColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.location5, color: Colors.green),
              ),
            ],
          ),

          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dropoffText.isNotEmpty ? dropoffText : "—",
                      maxLines: 1,
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "نقطة الوصول",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                      maxLines: 1,
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: borderColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.location5, color: Colors.redAccent),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: serviceType == "vip"
                      ? Colors.amber.withOpacity(0.15)
                      : primaryColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: serviceType == "vip" ? Colors.amber : primaryColor,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      serviceType == "vip" ? Iconsax.crown : Iconsax.car,
                      size: 16,
                      color: serviceType == "vip" ? Colors.amber[800] : primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      serviceType == "vip" ? "طلب VIP" : "طلب عادي",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: serviceType == "vip" ? Colors.amber[800] : primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (hasLeft || hasFare) ...[
            const SizedBox(height: 12),
            Container(width: double.maxFinite, height: 2, color: borderColor),
            const SizedBox(height: 12),

            Row(
              children: [
                if (hasLeft)
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: twoLines ? 2 : 2,
                        vertical: twoLines ? 6 : 8,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: primaryColor.withOpacity(0.15), width: 0.8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (showToPickup)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${toPickupKm!.toStringAsFixed(2)} كم",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: twoLines ? 12 : 14,
                                    color: primaryColor,
                                  ),
                                ),
                                SizedBox(width: twoLines ? 4 : 6),
                                Icon(Iconsax.routing,
                                    size: twoLines ? 14 : 18,
                                    color: primaryColor),
                                SizedBox(width: twoLines ? 4 : 6),
                                Text(
                                  "إلى الزبون",
                                  style: TextStyle(
                                    fontSize: twoLines ? 10 : 12,
                                  ),
                                ),
                              ],
                            ),

                          if (twoLines)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 2),
                              child: Divider(height: 1),
                            ),

                          if (showTripKm)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${tripKm.toStringAsFixed(2)} كم",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: twoLines ? 12 : 14,
                                    color: primaryColor,
                                  ),
                                ),
                                SizedBox(width: 2),
                                Icon(Iconsax.route_square,
                                    size: twoLines ? 14 : 16,
                                    color: primaryColor),
                                SizedBox(width: 2),
                                Text(
                                  "مسافة الرحلة",
                                  style: TextStyle(
                                    fontSize:  10,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),


                if (hasLeft && hasFare) const SizedBox(width: 12),

                if (hasFare)
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text("IQD $fare",
                                  maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end),
                              const Text(
                                "التكلفة المتوقعة",
                                style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor,fontSize: 10),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: borderColor, shape: BoxShape.circle),
                          child: const Icon(Iconsax.money, color: primaryColor),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _tripActions(DriverCubit cubit,BuildContext context) {
    if (cubit.tripStatus == "pending") {
      return Row(
        children: [
          Expanded(
            child: CustomButton(
              title: "رفض",
              onPressed: cubit.rejectCurrentRequest,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CustomButton(
              title: "قبول الطلب",
              onPressed: cubit.acceptCurrentRequest,
            ),
          ),
        ],
      );
    }

    if (cubit.tripStatus == "accepted") {
      return CustomButton(title: "وصلت لمكان الزبون", onPressed: cubit.arrivedToPickup);
    }
    if (cubit.tripStatus == "arrived") {
      return CustomButton(title: "بدء الرحلة", onPressed: cubit.startTrip);
    }
    if (cubit.tripStatus == "started") {
      return CustomButton(
        title: "إنهاء الرحلة",
        onPressed: cubit.endTrip,
        color: Colors.redAccent,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _circleIcon(IconData icon, VoidCallback onTap, {Color? bg}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: bg ?? primaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.35),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildMapIcon(dynamic m, {double size = 34}) {
    final icon = (m as dynamic).icon;

    if (icon is ImageProvider) {
      return Image(
        image: icon,
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => Icon(Iconsax.routing, size: size),
      );
    }

    if (icon is String) {
      return Image(
        image: AssetImage(icon),
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => Icon(Iconsax.routing, size: size),
      );
    }

    return Icon(Iconsax.routing, size: size);
  }

  // ── ديالوج اختيار طريقة الدفع ────────────────────────────────────────────
  void _showPaymentDialog(BuildContext context, DriverCubit cubit) {
    final fareController = TextEditingController(
      text: cubit.activeTripRequest?['estimatedFare']?.toString() ?? '',
    );
    String selectedMethod = 'cash';
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20,
              MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Center(child: Container(width: 46, height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.black12,
                    borderRadius: BorderRadius.circular(50)))),
              const Text('طريقة الدفع والأجرة',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  textAlign: TextAlign.right),
              const SizedBox(height: 16),
              Row(children: [
                _payMethodChip(label: 'نقود', icon: Iconsax.money,
                    value: 'cash', selected: selectedMethod == 'cash',
                    onTap: () => setS(() => selectedMethod = 'cash')),
                const SizedBox(width: 10),
                _payMethodChip(label: 'أونلاين', icon: Iconsax.card,
                    value: 'online', selected: selectedMethod == 'online',
                    onTap: () => setS(() => selectedMethod = 'online')),
              ]),
              const SizedBox(height: 16),
              Directionality(textDirection: TextDirection.rtl,
                child: TextFormField(controller: fareController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: 'الأجرة الفعلية (IQD)',
                    hintText: 'مثال: 5000', suffixIcon: const Icon(Iconsax.money),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))))),
              const SizedBox(height: 14),
              Container(padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selectedMethod == 'cash'
                      ? Colors.orange.withOpacity(0.08) : Colors.blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: selectedMethod == 'cash' ? Colors.orange : Colors.blue, width: 0.7)),
                child: Text(
                  selectedMethod == 'cash'
                      ? 'الزبون دفع نقداً. سيُخصم نصيب الأدمن من محفظتك.'
                      : 'الزبون دفع أونلاين. سيُضاف صافي أرباحك لمحفظتك.',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 12.5,
                    color: selectedMethod == 'cash'
                        ? Colors.orange.shade900 : Colors.blue.shade900))),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    cubit.endTrip();
                  },
                  child: const Text('تأكيد إنهاء الرحلة',
                      style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.bold, fontSize: 16)))),
            ]),
        )));
  }

  Widget _payMethodChip({required String label, required IconData icon,
    required String value, required bool selected, required VoidCallback onTap}) {
    return Expanded(child: GestureDetector(onTap: onTap,
      child: AnimatedContainer(duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
            color: selected ? primaryColor.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: selected ? primaryColor : Colors.black12,
                width: selected ? 1.5 : 1)),
        child: Column(children: [
          Icon(icon, color: selected ? primaryColor : Colors.black45),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontWeight: FontWeight.bold,
              color: selected ? primaryColor : Colors.black54)),
        ]))));
  }

  void _showTripSummaryDialog(BuildContext context, DriverTripCompletedState s) {
    showDialog(context: context, barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Text('ملخص الرحلة', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(width: 8),
          Icon(Iconsax.receipt, color: primaryColor),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _summaryRow(label: 'طريقة الدفع',
              value: s.paymentMethod == 'cash' ? 'نقداً 💵' : 'أونلاين 💳'),
          _summaryRow(label: 'الأجرة', value: '${s.finalFare.toStringAsFixed(0)} IQD'),
          _summaryRow(label: 'عمولة الأدمن',
              value: '${s.commission.toStringAsFixed(0)} IQD', valueColor: Colors.redAccent),
          if (s.paymentMethod == 'online')
            _summaryRow(label: 'صافي أرباحك',
                value: '${s.driverEarnings.toStringAsFixed(0)} IQD', valueColor: Colors.green),
          const Divider(height: 20),
          _summaryRow(label: 'رصيد المحفظة',
            value: s.newBalance != null ? '${s.newBalance!.toStringAsFixed(0)} IQD' : '---',
            valueColor: (s.newBalance ?? 1) > 0 ? Colors.green : Colors.redAccent, bold: true),
          if ((s.newBalance ?? 1) <= 0)
            Container(margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12)),
              child: const Text('رصيدك وصل لصفر!\nيجب شحن المحفظة لاستقبال رحلات.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.redAccent, fontSize: 13))),
        ]),
        actionsAlignment: MainAxisAlignment.center,
        actions: [TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('حسناً',
                style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)))],
      ));
  }

  Widget _summaryRow({required String label, required String value,
    Color? valueColor, bool bold = false}) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? Colors.black87, fontSize: bold ? 15 : 14)),
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
      ]));
  }

}
