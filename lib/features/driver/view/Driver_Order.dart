import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rido_syria_app/core/styles/themes.dart';
import 'package:rido_syria_app/features/driver/cubit/cubit.dart';
import 'package:rido_syria_app/features/driver/cubit/states.dart';

import '../../../core/widgets/app_bar.dart';
import '../model/DriverOrderModel.dart';

class DriverOrder extends StatelessWidget {
  const DriverOrder({super.key, required this.driverId});

  final String driverId;

  String _serviceLabel(String serviceType) {
    return serviceType.toLowerCase() == 'vip' ? 'VIP' : 'عادي';
  }

  Color _serviceColor(String serviceType) {
    return serviceType.toLowerCase() == 'vip' ? Colors.amber : primaryColor;
  }

  String _historyPriceText(Ride ride) {
    final serviceLabel = _serviceLabel(ride.serviceType);
    return 'الرحلة محسوبة كخدمة $serviceLabel، والمبلغ المسجل ${ride.estimatedFare} ل.س لمسافة ${ride.distanceKm} كم';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (BuildContext context) =>
              DriverCubit()
                ..getDriverOrder(context: context, driverId: driverId),
      child: BlocConsumer<DriverCubit, DriverStates>(
        listener: (context, state) {},
        builder: (context, state) {
          final cubit = DriverCubit.get(context);
          return Container(
            color: Colors.white,
            child: SafeArea(
              child: Scaffold(
                body: Column(
                  children: [
                    CustomAppBarBack(),
                    Expanded(
                      child: ConditionalBuilder(
                        condition:
                            cubit.driverOrderModel != null &&
                            cubit.driverOrderModel!.rides.isNotEmpty,
                        builder: (c) {
                          return ListView.builder(
                            physics: AlwaysScrollableScrollPhysics(),
                            itemCount: cubit.driverOrderModel!.rides.length,
                            itemBuilder: (context, index) {
                              final ride = cubit.driverOrderModel!.rides[index];
                              return orderItem(context, ride);
                            },
                          );
                        },
                        fallback:
                            (c) => SizedBox(
                              height: double.maxFinite,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: primaryColor,
                                ),
                              ),
                            ),
                      ),
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

  Widget orderItem(BuildContext context, ride) {
    Color statusColor;
    String statusText;

    print(ride.status);
    switch (ride.status) {
      case Status.COMPLETED:
        statusColor = Colors.green;
        statusText = "مكتمل";
        break;

      case Status.CANCELLED:
        statusColor = Colors.red;
        statusText = "ملغي";
        break;

      default:
        statusColor = Colors.orange;
        statusText = "غير معروف";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _serviceColor(ride.serviceType).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _serviceLabel(ride.serviceType),
                  style: TextStyle(
                    color: _serviceColor(ride.serviceType),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    "#${ride.id}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  Text(
                    " : معرف الرحلة",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),
          Container(width: double.maxFinite, height: 1, color: borderColor),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  ride.pickupAddress ?? "-",
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: borderColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Iconsax.location5, color: primaryColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  ride.dropoffAddress ?? "-",
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(width: 6),
              Container(
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: borderColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Iconsax.flag, color: primaryColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(width: double.maxFinite, height: 1, color: borderColor),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoChip("دقيقة", ride.durationMin),
              _infoChip("كم", ride.distanceKm),
              _infoChip("ل.س", ride.estimatedFare),
            ],
          ),

          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: primaryColor.withOpacity(0.12)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _historyPriceText(ride),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 11.5, height: 1.45),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Iconsax.info_circle, color: primaryColor, size: 18),
              ],
            ),
          ),

          const SizedBox(height: 10),
          Container(width: double.maxFinite, height: 1, color: borderColor),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [_infoTime(_formatDate(ride.createdAt), Iconsax.clock)],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String label, dynamic value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
          Text(
            " ${value ?? "--"}",
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _infoTime(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 18),
          Text(
            " $label",
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final d = date.toLocal();
    return "${d.year}/${d.month}/${d.day} - ${d.hour}:${d.minute.toString().padLeft(2, '0')}";
  }
}
