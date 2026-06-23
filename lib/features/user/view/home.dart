import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rido_syria_app/features/user/cubit/states.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:rido_syria_app/core/%20navigation/navigation.dart';
import 'package:rido_syria_app/core/network/remote/dio_helper.dart';
import 'package:rido_syria_app/core/styles/themes.dart';
import 'package:rido_syria_app/core/widgets/CustomButton.dart';
import 'package:rido_syria_app/core/widgets/constant.dart';
import 'package:rido_syria_app/core/widgets/custom_text_field.dart';
import 'package:rido_syria_app/core/widgets/show_toast.dart';
import 'package:rido_syria_app/features/user/cubit/cubit.dart';
import 'package:rido_syria_app/features/user/view/chat.dart';
import 'package:rido_syria_app/features/user/view/notifications.dart';
import 'package:rido_syria_app/features/user/view/profile.dart';

class Home extends StatelessWidget {
  const Home({super.key, required this.cubit});

  final UserCubit cubit;

  String _serviceLabel(String? serviceType) {
    return (serviceType ?? 'normal').toLowerCase() == 'vip' ? 'VIP' : 'عادي';
  }

  Color _serviceColor(String? serviceType) {
    return (serviceType ?? 'normal').toLowerCase() == 'vip'
        ? Colors.amber.shade800
        : secondPrimaryColor;
  }

  String pickupText(UserCubit cubit) {
    if (cubit.activeRequestId != null) {
      return cubit.pickupName ?? "موقع الانطلاق";
    }
    return cubit.pickupName ?? "حدد نقطة الانطلاق";
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

  String dropoffText(UserCubit cubit) {
    if (cubit.activeRequestId != null) {
      return cubit.dropoffName ?? "موقع الوصول";
    }
    return cubit.dropoffName ?? "حدد نقطة الوصول";
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: BlocConsumer<UserCubit, UserStates>(
        listener: (context, state) {
          if (state is UserRequestCreatedState) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              UserCubit.get(context).openPendingSheet();
            });
          }

          if (state is UserRideStatusChangedState) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final c = UserCubit.get(context);
              if (state.status == "pending") c.openPendingSheet();
              if (state.status == "accepted" ||
                  state.status == "arrived" ||
                  state.status == "started")
                c.lockActiveTripSheet();
              if (state.status == "completed" || state.status == "cancelled")
                c.collapseSheet();
            });
          }

          if (state is UserLocationErrorState) {
            showSnackBarError(text: state.message, context: context);
          } else if (state is UserCreateRequestErrorState) {
            showSnackBarError(text: state.message, context: context);
          } else if (state is UserRequestCreatedState) {
            showSnackBarSuccess(
              text: "تم إنشاء الطلب: ${state.requestId}",
              context: context,
            );
          } else if (state is UserRideStatusChangedState) {
            showSnackBarInfo(
              text: "حالة الرحلة: ${getStatusArabic(state.status)}",
              context: context,
            );
          } else if (state is UserCompleteRideSuccessState) {
            showSnackBarSuccess(text: "تم تأكيد الدفع بنجاح", context: context);
          } else if (state is UserCompleteRideErrorState) {
            showSnackBarError(text: "خطأ: ${state.message}", context: context);
          } else if (state is UserInsufficientBalanceState) {
            showSnackBarError(
              text:
                  "رصيد محفظتك غير كافي للدفع. الرجاء شحن المحفظة وإعادة المحاولة",
              context: context,
            );
          } else if (state is UserPaymentPendingDriverState) {
            showSnackBarSuccess(
              text: "تم الدفع بنجاح ✔ انتظر الكابتن لينهي الرحلة",
              context: context,
            );
          }
        },
        builder: (context, state) {
          final cubit = UserCubit.get(context);
          final hideCenterPin =
              cubit.activeRequestId != null ||
              (cubit.pickupLatLng != null && cubit.dropoffLatLng != null);

          return Container(
            color: Colors.white,
            child: SafeArea(
              child: Scaffold(
                body: Stack(
                  children: [
                    Positioned.fill(child: _buildMap(context, cubit, state)),

                    Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.18,
                      padding: const EdgeInsets.only(top: 16, bottom: 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            secondPrimaryColor.withOpacity(0.35),
                            secondPrimaryColor.withOpacity(0.0),
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
                            navigateTo(context, const Profile());
                          }),

                          Text(
                            nameApp,
                            style: TextStyle(
                              color: secondPrimaryColor,
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
                    Center(
                      child: IgnorePointer(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 220),
                          opacity: hideCenterPin ? 0.0 : 1.0,
                          child: AnimatedSlide(
                            duration: const Duration(milliseconds: 220),
                            offset:
                                hideCenterPin
                                    ? const Offset(0, -0.25)
                                    : Offset.zero,
                            child: FractionalTranslation(
                              translation: const Offset(0, -0.5),
                              child: Image.asset(
                                cubit.pickupLatLng == null
                                    ? 'assets/images/pick2.png'
                                    : 'assets/images/drop2.png',
                                width: 46,
                                height: 46,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    DraggableScrollableSheet(
                      controller: cubit.sheetController,
                      initialChildSize: 0.32,
                      minChildSize: 0.32,
                      maxChildSize: 0.62,
                      snap: true,
                      snapSizes: const [0.32, 0.46, 0.62],
                      builder: (context, scrollController) {
                        return _bottomPanel(context, cubit, scrollController);
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMap(BuildContext context, UserCubit cubit, UserStates state) {
    if (state is UserLoadingLocationState && cubit.currentLatLng == null) {
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
      onCameraMove: cubit.onCameraMove,
      onCameraIdle: cubit.onCameraIdle,
    );
  }

  Widget _circleIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: secondPrimaryColor,
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

  Widget _driverInfoCard(UserCubit cubit) {
    final driver = cubit.driverModel;
    if (driver == null) return const SizedBox.shrink();

    final name = driver.name;
    final phone = driver.phone;
    final image = driver.drivingLicenseBack.main;
    final carType = driver.vehicleType;
    final carColor = driver.vehicleColor;
    final carPlate = driver.vehicleNumber;
    final carImage = driver.carImages.main;

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
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: secondPrimaryColor.withOpacity(0.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                cubit.rideStatus == "accepted" && cubit.driverModel != null
                    ? Text(
                      'الكابتن في الطريق اليك',
                      style: TextStyle(fontSize: 13),
                    )
                    : cubit.rideStatus == "arrived" && cubit.driverModel != null
                    ? Text(
                      'الكابتن وصل الى موقعك',
                      style: TextStyle(fontSize: 13),
                    )
                    : Text('الرحلة بدأت', style: TextStyle(fontSize: 13)),
                SizedBox(width: 6),
                Icon(Iconsax.car, color: secondPrimaryColor),
              ],
            ),
          ),
          SizedBox(height: 4),
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  final uri = Uri.parse('tel:$phone');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
                child: Icon(Iconsax.call, color: secondPrimaryColor),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(name),
                    Text(phone),
                    Text(
                      '$carType - $carColor - $carPlate',
                      style: TextStyle(color: secondPrimaryColor),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Image.network(
                  '$url/uploads/$image',
                  height: 50,
                  width: 50,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bottomPanel(
    BuildContext context,
    UserCubit cubit,
    ScrollController scrollController,
  ) {
    final hasActive = cubit.activeRequestId != null;
    final status = cubit.rideStatus;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 10, 16),
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
            const SizedBox(height: 5),

            if (hasActive && status == "pending") ...[
              const Text('جاري البحث عن سائق'),
              const SizedBox(height: 6),
              const LinearProgressIndicator(
                minHeight: 4,
                color: secondPrimaryColor,
              ),
              const SizedBox(height: 12),
            ],

            if ((status == "accepted" ||
                    status == "arrived" ||
                    status == "started") &&
                cubit.driverModel != null) ...[
              _driverInfoCard(cubit),
              const SizedBox(height: 10),
              Container(width: double.infinity, height: 2, color: borderColor),
              const SizedBox(height: 10),
            ],

            _userRequestInfoCard(cubit),

            // Container(width: double.infinity, height: 2, color: borderColor),
            const SizedBox(height: 8),

            if (hasActive)
              if (status == "started") ...[
                // الزبون يختار طريقة الدفع عندما تكون الرحلة بدأت
                _paymentSelectorCard(context, cubit),
                const SizedBox(height: 8),
              ] else if (status == "arrived") ...[
                GestureDetector(
                  onTap: () {
                    navigateTo(context, Chat(userId: int.parse(id)));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: containerColor,
                      border: Border.all(color: secondPrimaryColor),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "تواصل مع الدعم",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: secondPrimaryColor,
                              ),
                            ),
                            Text(
                              "هنالك مشكلة تواصل مع الدعم",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: secondPrimaryColor,
                                fontSize: 7.5,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 10),
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: secondPrimaryColor,
                          child: Icon(
                            Iconsax.headphone,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else
                CustomButton(
                  title: "إلغاء الرحلة",
                  onPressed: cubit.cancelRideRequest,
                  color: Colors.redAccent,
                )
            else
              CustomButton(
                title: cubit.mainButtonText,
                onPressed: cubit.onMainActionPressed,
              ),
          ],
        ),
      ),
    );
  }

  Widget _userRequestInfoCard(UserCubit cubit) {
    final dropoff = dropoffText(cubit);
    final fare = (cubit.estimatedFare ?? "").trim();
    final km = cubit.distanceKm;
    final hasKm = km != null;
    final hasFare = fare.isNotEmpty;
    final pointsSelected =
        cubit.pickupLatLng != null && cubit.dropoffLatLng != null;
    final hasActiveRequest = cubit.activeRequestId != null;
    final effectiveServiceType =
        hasActiveRequest
            ? cubit.currentRequestServiceType
            : cubit.selectedServiceType?.value;
    final serviceHint =
        effectiveServiceType == null
            ? 'اختر نوع الرحلة أولاً'
            : effectiveServiceType == 'vip'
            ? 'سيتم احتساب السعر حسب تسعيرة VIP'
            : 'سيتم احتساب السعر حسب التسعيرة العادية';
    final hasServiceType = effectiveServiceType != null;

    if (cubit.isSearching) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: containerColor),
        ),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: cubit.stopSearch,
                  icon: const Icon(
                    Iconsax.arrow_right_3,
                    color: secondPrimaryColor,
                  ),
                ),
                Expanded(
                  child: SearchTextField(
                    controller: cubit.searchController,
                    hintText:
                        cubit.searchingFor == SelectingPoint.pickup
                            ? "ابحث عن نقطة الانطلاق..."
                            : "ابحث عن نقطة الوصول...",
                    onChanged: cubit.searchPlaces,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (cubit.placeSuggestions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  "اكتب اسم المكان حتى تظهر الاقتراحات",
                  style: TextStyle(fontSize: 12),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cubit.placeSuggestions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final s = cubit.placeSuggestions[i];
                  return ListTile(
                    dense: true,
                    title: Text(
                      s.mainText.isNotEmpty ? s.mainText : s.description,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 12),
                    ),
                    subtitle:
                        s.secondaryText.isNotEmpty
                            ? Text(
                              s.secondaryText,
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 11),
                            )
                            : null,
                    onTap: () => cubit.selectPlaceSuggestion(s),
                  );
                },
              ),
          ],
        ),
      );
    }

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
          if (!pointsSelected || hasActiveRequest) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SearchTextField(
                        hintText: pickupText(cubit),
                        readOnly: true,
                        onTap:
                            hasActiveRequest
                                ? null
                                : () =>
                                    cubit.startSearch(SelectingPoint.pickup),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: borderColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Iconsax.location5,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                    Text(
                      "نقطة الانطلاق",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: secondPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                    SizedBox(width: 50),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SearchTextField(
                        hintText: dropoff,
                        readOnly: true,
                        onTap:
                            hasActiveRequest
                                ? null
                                : () =>
                                    cubit.startSearch(SelectingPoint.dropoff),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: borderColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Iconsax.location5,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                    Text(
                      "نقطة الوصول",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: secondPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                    SizedBox(width: 50),
                  ],
                ),
              ],
            ),
          ],

          if (pointsSelected && !hasActiveRequest) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap:
                        () => cubit.changeServiceType(RideServiceType.normal),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        color:
                            cubit.selectedServiceType == RideServiceType.normal
                                ? secondPrimaryColor.withOpacity(0.12)
                                : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              cubit.selectedServiceType ==
                                      RideServiceType.normal
                                  ? secondPrimaryColor
                                  : borderColor,
                        ),
                      ),
                      child: Column(
                        children: const [
                          Icon(Iconsax.car, color: secondPrimaryColor),
                          SizedBox(height: 2),
                          Text(
                            "عادي",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => cubit.changeServiceType(RideServiceType.vip),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        color:
                            cubit.selectedServiceType == RideServiceType.vip
                                ? secondPrimaryColor.withOpacity(0.12)
                                : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              cubit.selectedServiceType == RideServiceType.vip
                                  ? secondPrimaryColor
                                  : borderColor,
                        ),
                      ),
                      child: Column(
                        children: const [
                          Icon(Iconsax.crown, color: secondPrimaryColor),
                          SizedBox(height: 2),
                          Text(
                            "VIP",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          if (hasKm || hasFare) ...[
            const SizedBox(height: 4),
            if (hasServiceType) ...[
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _serviceColor(
                      effectiveServiceType,
                    ).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _serviceColor(
                        effectiveServiceType,
                      ).withOpacity(0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        effectiveServiceType == 'vip'
                            ? Iconsax.crown
                            : Iconsax.car,
                        size: 16,
                        color: _serviceColor(effectiveServiceType),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'نوع التسعير: ${_serviceLabel(effectiveServiceType)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _serviceColor(effectiveServiceType),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                if (hasKm)
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                " كم ${km.toStringAsFixed(2)}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                "المسافة",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: secondPrimaryColor,
                                  fontSize: 12,
                                ),
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
                          decoration: BoxDecoration(
                            color: borderColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Iconsax.route_square,
                            color: secondPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (hasKm && hasFare) const SizedBox(width: 12),
                if (hasFare)
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "SYP $fare",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                "المبلغ المتوقع",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: secondPrimaryColor,
                                  fontSize: 12,
                                ),
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
                          decoration: BoxDecoration(
                            color: borderColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Iconsax.money,
                            color: secondPrimaryColor,
                          ),
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

  // ── بطاقة اختيار طريقة الدفع للزبون عند status=started ─────────────────
  Widget _paymentSelectorCard(BuildContext context, UserCubit cubit) {
    return StatefulBuilder(
      builder: (ctx, setS) {
        final method = cubit.selectedPaymentMethod;
        final paid = cubit.paymentDoneOnline;
        final showOnlinePayment = DateTime.now().millisecondsSinceEpoch < 0;
        final loading =
            context.read<UserCubit>().state is UserCompleteRideLoadingState;

        // إذا دفع أونلاين بنجاح → بطاقة انتظار
        if (paid) return _pendingDriverCard();

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: secondPrimaryColor.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // ─ عنوان
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Text(
                    'اختر طريقة الدفع',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  SizedBox(width: 6),
                  Icon(Iconsax.wallet, color: secondPrimaryColor, size: 18),
                ],
              ),
              const SizedBox(height: 12),

              // ─ أزرار كاش / أونلاين
              Row(
                children: [
                  _riderPayChip(
                    ctx,
                    cubit,
                    label: 'نقداً',
                    icon: Iconsax.money,
                    value: 'cash',
                    selected: method == 'cash',
                    setS: setS,
                  ),
                  if (showOnlinePayment) const SizedBox(width: 10),
                  if (showOnlinePayment) _riderPayChip(
                    ctx,
                    cubit,
                    label: 'أونلاين',
                    icon: Iconsax.card,
                    value: 'online',
                    selected: method == 'online',
                    setS: setS,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ─ محتوى حسب الطريقة
              if (method == 'cash') ...[
                // كاش: معلومة فقط - السائق ينهي الرحلة
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: const [
                      Expanded(
                        child: Text(
                          'ستدفع نقداً للسائق مباشرة\nسينتهي السائق الرحلة بعد استلام المبلغ',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.5,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Iconsax.money, color: Colors.orange, size: 20),
                    ],
                  ),
                ),
              ] else ...[
                // أونلاين: زر ادفع الآن
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondPrimaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    icon:
                        loading
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Icon(
                              Iconsax.card,
                              color: Colors.white,
                              size: 18,
                            ),
                    label: Text(
                      loading ? 'جاري الدفع...' : 'ادفع أونلاين الآن',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: loading ? null : cubit.payOnlineRide,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ── بطاقة انتظار الكابتن بعد الدفع الأونلاين
  Widget _pendingDriverCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: const [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'تم الدفع بنجاح ✔',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'انتظر الكابتن لينهي الرحلة',
                  style: TextStyle(fontSize: 12.5, color: Colors.green),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.green,
            child: Icon(Iconsax.tick_circle, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _riderPayChip(
    BuildContext ctx,
    UserCubit cubit, {
    required String label,
    required IconData icon,
    required String value,
    required bool selected,
    required StateSetter setS,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          cubit.selectPaymentMethod(value);
          setS(() {});
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:
                selected ? secondPrimaryColor.withOpacity(0.10) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? secondPrimaryColor : Colors.black12,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? secondPrimaryColor : Colors.black45),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: selected ? secondPrimaryColor : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
