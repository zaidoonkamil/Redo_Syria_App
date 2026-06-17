import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rido_syria_app/core/styles/themes.dart';
import 'package:rido_syria_app/features/admin/cubit/cubit.dart';
import 'package:rido_syria_app/features/admin/cubit/states.dart';
import 'package:rido_syria_app/features/admin/view/setting.dart';

import '../../../core/widgets/constant.dart';
import 'AdminUsers.dart';
import 'UsersAdmin.dart';
import 'admin_notifications_screen.dart';
import 'all_user_chat_admin.dart';
import 'drivers.dart';
import 'whatsapp_admin_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AppCubitAdmin>(
      create: (_) => AppCubitAdmin()..loadDashboardStats(),
      child: const _AdminDashboardBody(),
    );
  }
}

class _AdminDashboardBody extends StatefulWidget {
  const _AdminDashboardBody({Key? key}) : super(key: key);

  @override
  State<_AdminDashboardBody> createState() => _AdminDashboardBodyState();
}

class _AdminDashboardBodyState extends State<_AdminDashboardBody> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DashboardHomeScreen(),
    AdminUsers(),
    Drivers(),
    UsersAdmin(),
    AdminNotificationsScreen(),
    AllUserChatAdmin(),
    Setting(),
    WhatsAppAdminScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                AdminAppBar(title: 'لوحة التحكم'),
                Expanded(child: _screens[_selectedIndex]),
              ],
            ),
          ),
          Container(
            width: 250,
            color: secondPrimaryColor,
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  'وصلنــــــــي',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: [
                      _buildMenuItem(
                        icon: Icons.dashboard,
                        title: 'الرئيسية',
                        index: 0,
                      ),
                      _buildMenuItem(
                        icon: Iconsax.user,
                        title: 'المستخدمين',
                        index: 1,
                      ),
                      _buildMenuItem(
                        icon: Iconsax.car,
                        title: 'الكباتن',
                        index: 2,
                      ),
                      _buildMenuItem(
                        icon: Iconsax.shield_tick,
                        title: 'الادمن',
                        index: 3,
                      ),
                      _buildMenuItem(
                        icon: Iconsax.notification,
                        title: 'الاشعارات',
                        index: 4,
                      ),
                      _buildMenuItem(
                        icon: Iconsax.sms,
                        title: 'الدعم',
                        index: 5,
                      ),
                      _buildMenuItem(
                        icon: Iconsax.setting,
                        title: 'الاعدادت',
                        index: 6,
                      ),
                      _buildMenuItem(
                        icon: Icons.phone_android_rounded,
                        title: 'ربط واتساب',
                        index: 7,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: isSelected ? Colors.white : Colors.transparent,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        trailing: Icon(icon, color: isSelected ? primaryColor : Colors.white),
        title: Align(
          alignment: Alignment.centerRight,
          child: Text(
            title,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: isSelected ? primaryColor : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        selected: isSelected,
        selectedTileColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }
}

class DashboardHomeScreen extends StatelessWidget {
  const DashboardHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubitAdmin, AppStatesAdmin>(
      builder: (context, state) {
        final cubit = AppCubitAdmin.get(context);

        if (state is AdminStatsLoadingState && cubit.statsOverview == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is AdminStatsErrorState && cubit.statsOverview == null) {
          return Center(child: Text("صار خطأ: ${state.message}"));
        }

        final o = cubit.statsOverview ?? {};
        final u = cubit.usersOverview ?? {};

        final ridesByStatus =
            (o["ridesByStatus"] is Map)
                ? Map<String, dynamic>.from(o["ridesByStatus"])
                : {};
        final usersByStatus =
            (u["usersByStatus"] is Map)
                ? Map<String, dynamic>.from(u["usersByStatus"])
                : {};

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.end,
                  children: [
                    _StatCard(
                      title: "المستخدمين",
                      value: "${o["totalUsers"] ?? 0}",
                      icon: Iconsax.user,
                    ),
                    _StatCard(
                      title: "السائقين",
                      value: "${o["totalDrivers"] ?? 0}",
                      icon: Iconsax.car,
                    ),
                    _StatCard(
                      title: "الرحلات",
                      value: "${o["totalRides"] ?? 0}",
                      icon: Iconsax.map_1,
                    ),
                    _StatCard(
                      title: "الإيراد",
                      value: "${o["revenueTotal"] ?? 0}",
                      icon: Iconsax.money,
                    ),
                    _StatCard(
                      title: "سائقين أونلاين",
                      value: "${o["onlineDrivers"] ?? "-"}",
                      icon: Iconsax.flash,
                    ),
                    _StatCard(
                      title: "سائقين فعالين",
                      value: "${o["activeDrivers"] ?? 0}",
                      icon: Iconsax.tick_circle,
                    ),
                  ],
                ),

                const SizedBox(height: 22),
                _SectionTitle("الرحلات حسب الحالة"),
                const SizedBox(height: 10),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.end,
                  children:
                      ridesByStatus.entries
                          .map(
                            (e) =>
                                StatusChip(title: e.key, value: "${e.value}"),
                          )
                          .toList(),
                ),

                const SizedBox(height: 22),
                _SectionTitle("إحصائيات المستخدمين"),
                const SizedBox(height: 10),

                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.end,
                  children: [
                    _StatCard(
                      title: "Pending Drivers",
                      value: "${u["pendingDrivers"] ?? 0}",
                      icon: Iconsax.timer_1,
                    ),
                    _StatCard(
                      title: "Devices",
                      value: "${u["devicesTotal"] ?? "-"}",
                      icon: Iconsax.mobile,
                    ),
                    _StatCard(
                      title: "Users With Devices",
                      value: "${u["usersWithDevices"] ?? "-"}",
                      icon: Iconsax.people,
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.end,
                  children:
                      usersByStatus.entries
                          .map(
                            (e) => StatusChip(
                              title: "status: ${e.key}",
                              value: "${e.value}",
                            ),
                          )
                          .toList(),
                ),

                const SizedBox(height: 22),
                _SectionTitle("الاحصائيات اليومية"),
                const SizedBox(height: 10),

                _TimeseriesTable(title: "الرحلات", rows: cubit.ridesSeries),
                const SizedBox(height: 12),
                _TimeseriesTable(title: "المستخدمين", rows: cubit.usersSeries),
                const SizedBox(height: 12),
                _TimeseriesTable(title: "الكباتن", rows: cubit.driversSeries),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _TimeseriesTable extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> rows;

  const _TimeseriesTable({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    final safeRows = rows.take(2).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1)},
            border: TableBorder.all(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(8),
            ),
            children: [
              TableRow(
                decoration: BoxDecoration(color: secondPrimaryColor),
                children: const [
                  Padding(
                    padding: EdgeInsets.all(10),
                    child: Text(
                      "التاريخ",
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(10),
                    child: Text(
                      "العدد",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              ...safeRows.map((r) {
                final date = (r["date"] ?? "").toString();
                final count = (r["count"] ?? 0).toString();

                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(date, textAlign: TextAlign.end),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        count,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: secondPrimaryColor),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String title;
  final String value;

  const StatusChip({Key? key, required this.title, required this.value})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final status = tripStatusFromKey(title.replaceAll("status:", "").trim());
    final style = statusStyle(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: style.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 16, color: style.text),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: style.text),
          ),
          const SizedBox(width: 6),
          Text(title, style: TextStyle(color: style.text, fontSize: 12)),
        ],
      ),
    );
  }
}

enum TripStatus { completed, cancelled, pending, active, unknown }

TripStatus tripStatusFromKey(String key) {
  switch (key.toLowerCase()) {
    case "completed":
      return TripStatus.completed;
    case "cancelled":
      return TripStatus.cancelled;
    case "pending":
      return TripStatus.pending;
    case "accepted":
    case "started":
    case "active":
      return TripStatus.active;
    default:
      return TripStatus.unknown;
  }
}

class _StatusStyle {
  final Color bg;
  final Color border;
  final Color text;
  final IconData icon;

  const _StatusStyle({
    required this.bg,
    required this.border,
    required this.text,
    required this.icon,
  });
}

_StatusStyle statusStyle(TripStatus status) {
  switch (status) {
    case TripStatus.completed:
      return _StatusStyle(
        bg: Colors.green.withOpacity(0.12),
        border: Colors.green.withOpacity(0.4),
        text: Colors.green.shade700,
        icon: Iconsax.tick_circle,
      );
    case TripStatus.cancelled:
      return _StatusStyle(
        bg: Colors.red.withOpacity(0.12),
        border: Colors.red.withOpacity(0.4),
        text: Colors.red.shade700,
        icon: Iconsax.close_circle,
      );
    case TripStatus.pending:
      return _StatusStyle(
        bg: Colors.orange.withOpacity(0.15),
        border: Colors.orange.withOpacity(0.4),
        text: Colors.orange.shade800,
        icon: Iconsax.clock,
      );
    case TripStatus.active:
      return _StatusStyle(
        bg: Colors.blue.withOpacity(0.12),
        border: Colors.blue.withOpacity(0.4),
        text: Colors.blue.shade700,
        icon: Iconsax.routing,
      );
    default:
      return _StatusStyle(
        bg: Colors.grey.withOpacity(0.12),
        border: Colors.grey.withOpacity(0.4),
        text: Colors.grey.shade700,
        icon: Iconsax.info_circle,
      );
  }
}

class AdminAppBar extends StatelessWidget {
  final String title;

  const AdminAppBar({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),

        color: containerColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: secondPrimaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Iconsax.user, color: primaryColor, size: 16),
              ),
              const SizedBox(width: 12),
              Image.asset('assets/images/$logo', width: 40, height: 40),
            ],
          ),

          Text(
            title,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
