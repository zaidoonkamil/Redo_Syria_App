import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rido_syria_app/core/widgets/app_bar.dart';

import '../../../core/styles/themes.dart';
import '../cubit/cubit.dart';
import '../cubit/states.dart';

class DebtsDriver extends StatelessWidget {
  const DebtsDriver({
    super.key,
    required this.isDebtBlocked,
    required this.driverDebt,
    required this.name,
    required this.phone,
    required this.status,
    required this.vehicleType,
    required this.vehicleColor,
    required this.vehicleNumber,
  });

  final String isDebtBlocked;
  final String driverDebt; // الآن يحمل رصيد المحفظة
  final String name;
  final String phone;
  final String status;
  final String vehicleType;
  final String vehicleColor;
  final String vehicleNumber;

  bool get _blocked => isDebtBlocked.toLowerCase() == "true" || isDebtBlocked == "1";

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) =>
      DriverCubit()..getCommissionSettings(context: context),
      child: BlocConsumer<DriverCubit, DriverStates>(
        listener: (context, state) {},
        builder: (context, state) {
          final cubit = DriverCubit.get(context);
          final loading = state is WalletSettingsLoadingState;

          final commissionType = cubit.commissionType;
          final commissionValue = cubit.commissionValue;

          return Container(
            color: Colors.white,
            child: SafeArea(
              child: Scaffold(
                body: Column(
                  children: [
                    CustomAppBarBack(),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _HeaderCard(
                              name: name,
                              phone: phone,
                              status: status,
                              blocked: _blocked,
                              walletBalance: driverDebt,
                            ),
                            const SizedBox(height: 12),
                            _CarCard(
                              vehicleType: vehicleType,
                              vehicleColor: vehicleColor,
                              vehicleNumber: vehicleNumber,
                            ),
                            const SizedBox(height: 12),
                            _SettingsCard(
                              commissionType: commissionType,
                              commissionValue: commissionValue,
                              loading: loading,
                            ),
                            const SizedBox(height: 12),
                            _HintCard(blocked: _blocked),
                          ],
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
}


class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.name,
    required this.phone,
    required this.status,
    required this.blocked,
    required this.walletBalance,
  });

  final String name;
  final String phone;
  final String status;
  final bool blocked;
  final String walletBalance;

  @override
  Widget build(BuildContext context) {
    final balance = double.tryParse(walletBalance) ?? 0;
    final badgeColor = blocked ? Colors.red : Colors.green;
    final badgeText = blocked ? "محظور - رصيد صفر" : "نشط";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 8),
            color: Color(0x14000000),
          ),
        ],
        border: Border.all(width: 1, color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      name.isEmpty ? "—" : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      phone.isEmpty ? "—" : phone,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: primaryColor.withOpacity(0.22)),
                ),
                child: Icon(Iconsax.user, color: primaryColor, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
              Text(
                ": حالة الحساب",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: balance > 0
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: balance > 0 ? Colors.green.shade200 : Colors.red.shade200,
              ),
            ),
            child: Row(
              children: [
                Text(
                  walletBalance.isEmpty ? "0" : walletBalance,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: balance > 0 ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
                const Expanded(
                  child: Text(
                    "رصيد المحفظة",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.end,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Iconsax.wallet,
                    color: balance > 0 ? Colors.green.shade700 : Colors.red.shade700),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CarCard extends StatelessWidget {
  const _CarCard({
    required this.vehicleType,
    required this.vehicleColor,
    required this.vehicleNumber,
  });

  final String vehicleType;
  final String vehicleColor;
  final String vehicleNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 8),
            color: Color(0x14000000),
          ),
        ],
        border: Border.all(width: 1, color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: const [
              Text(
                "معلومات السيارة",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              SizedBox(width: 4),
              Icon(Iconsax.car, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 88,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Image.asset(
                    "assets/images/car.png",
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.directions_car_filled,
                      color: Colors.grey.shade600,
                      size: 34,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    _InfoRow(title: "النوع", value: vehicleType.isEmpty ? "—" : vehicleType),
                    const SizedBox(height: 8),
                    _InfoRow(title: "اللون", value: vehicleColor.isEmpty ? "—" : vehicleColor),
                    const SizedBox(height: 8),
                    _InfoRow(title: "رقم السيارة", value: vehicleNumber.isEmpty ? "—" : vehicleNumber),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.commissionType,
    required this.commissionValue,
    required this.loading,
  });

  final String? commissionType;
  final double? commissionValue;
  final bool loading;

  String _typeLabel(String? t) {
    if (t == null) return "—";
    if (t.toLowerCase() == "percent") return "نسبة مئوية";
    if (t.toLowerCase() == "fixed") return "مبلغ ثابت";
    return t;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 8),
            color: Color(0x14000000),
          ),
        ],
        border: Border.all(width: 1, color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: const [
              Text(
                "إعدادات العمولة",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              SizedBox(width: 4),
              Icon(Iconsax.percentage_square, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          if (loading)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text("جاري جلب الإعدادات..."),
                ],
              ),
            )
          else ...[
            _InfoRow(
              title: "نوع العمولة",
              value: _typeLabel(commissionType),
            ),
            const SizedBox(height: 10),
            _InfoRow(
              title: "قيمة العمولة",
              value: commissionValue == null ? "—" : "${commissionValue!.toStringAsFixed(0)}%",
            ),
          ],
        ],
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.blocked});
  final bool blocked;

  @override
  Widget build(BuildContext context) {
    final color = blocked ? Colors.red : Colors.blueGrey;
    final text = blocked
        ? "ملاحظة: حسابك محظور لأن رصيد محفظتك وصل لصفر. اشحن المحفظة لاستئناف استقبال الطلبات."
        : "ملاحظة: إذا وصل رصيد محفظتك لصفر، سيتوقف استقبال الطلبات تلقائيًا. احرص على شحنها.";

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 13,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
          const SizedBox(width: 10),
          Icon(Icons.info_outline, color: color),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
