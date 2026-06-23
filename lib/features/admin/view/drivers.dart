import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rido_syria_app/core/%20navigation/navigation.dart';
import 'package:rido_syria_app/core/network/remote/dio_helper.dart';

import 'package:rido_syria_app/core/styles/themes.dart';
import 'package:rido_syria_app/core/widgets/CustomDialog.dart';
import 'package:rido_syria_app/features/admin/cubit/cubit.dart';
import 'package:rido_syria_app/features/admin/cubit/states.dart';
import 'package:rido_syria_app/features/admin/model/GetDriverOnlyModel.dart';
import 'package:rido_syria_app/features/driver/view/Driver_Order.dart';

import '../../../core/widgets/CustomButton.dart';
import '../../../core/widgets/constant.dart';

class Drivers extends StatefulWidget {
  const Drivers({super.key});

  @override
  State<Drivers> createState() => _AdminUsersState();
}

class _AdminUsersState extends State<Drivers> {
  int _page = 1;

  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) => AppCubitAdmin()..getDriverOnly(context: context, page: "1"),
      child: BlocConsumer<AppCubitAdmin, AppStatesAdmin>(
        listener: (context, state) {},
        builder: (context, state) {
          final cubit = AppCubitAdmin.get(context);
          final model = cubit.getDriverOnlyModel;
          final isLoading = state is GetDriverOnlyLoadingState && model == null;
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        hintText: "ابحث بالاسم أو الرقم...",
                        prefixIcon: const Icon(Iconsax.search_normal),
                        suffixIcon:
                            _searchController.text.isEmpty
                                ? null
                                : IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _page = 1);
                                    cubit.getDriverOnly(
                                      context: context,
                                      page: "1",
                                    ); // رجع القائمة الطبيعية
                                  },
                                ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                      onChanged: (val) {
                        _debounce?.cancel();
                        _debounce = Timer(
                          const Duration(milliseconds: 450),
                          () {
                            final q = val.trim();
                            setState(() => _page = 1);

                            if (q.isEmpty) {
                              cubit.getDriverOnly(context: context, page: "1");
                            } else {
                              cubit.searchDriversOnly(
                                context: context,
                                q: q,
                                page: "1",
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child:
                          isLoading
                              ? const Center(
                                child: CircularProgressIndicator(
                                  color: secondPrimaryColor,
                                ),
                              )
                              : (model == null || model.drivers.isEmpty)
                              ? const Center(child: Text("لا يوجد مستخدمين"))
                              : Column(
                                children: [
                                  _TopStatsRow(
                                    total: model.pagination.totalDrivers,
                                    page: model.pagination.currentPage,
                                    pages: model.pagination.totalPages,
                                    limit: model.pagination.limit,
                                  ),
                                  SizedBox(height: 4),
                                  const Divider(height: 1),
                                  SizedBox(height: 4),
                                  Expanded(
                                    child: Center(
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 1200,
                                        ),
                                        child: ListView.separated(
                                          padding: const EdgeInsets.all(12),
                                          itemCount: model.drivers.length,
                                          separatorBuilder:
                                              (_, __) =>
                                                  const SizedBox(height: 10),
                                          itemBuilder: (context, index) {
                                            final d = model.drivers[index];
                                            return _DriverCard(driver: d);
                                          },
                                        ),
                                      ),
                                    ),
                                  ),

                                  const Divider(height: 1),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    child: _PaginationBar(
                                      currentPage: model.pagination.currentPage,
                                      totalPages: model.pagination.totalPages,
                                      onPage: (p) {
                                        setState(() => _page = p);
                                        cubit.getDriverOnly(
                                          context: context,
                                          page: p.toString(),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ),
                  if (state is GetDriverOnlyLoadingState && model != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: const [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: secondPrimaryColor,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text("جاري تحميل الصفحة..."),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TopStatsRow extends StatelessWidget {
  final int total;
  final int page;
  final int pages;
  final int limit;

  const _TopStatsRow({
    required this.total,
    required this.page,
    required this.pages,
    required this.limit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.end,
        children: [
          _MiniStat(
            title: "الإجمالي",
            value: total.toString(),
            icon: Iconsax.people,
          ),
          _MiniStat(
            title: "الصفحة",
            value: "$page / $pages",
            icon: Iconsax.layer,
          ),
          _MiniStat(
            title: "لكل صفحة",
            value: limit.toString(),
            icon: Iconsax.document,
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MiniStat({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
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
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
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

class _StatusChip extends StatelessWidget {
  final String status;
  final String userId;

  const _StatusChip({required this.status, required this.userId});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();

    Color bg;
    Color border;
    Color text;

    if (s == "active" || s == "approved") {
      bg = Colors.green.withOpacity(0.12);
      border = Colors.green.withOpacity(0.35);
      text = Colors.green.shade700;
    } else if (s == "pending") {
      bg = Colors.orange.withOpacity(0.15);
      border = Colors.orange.withOpacity(0.35);
      text = Colors.orange.shade800;
    } else if (s == "blocked" || s == "banned") {
      bg = Colors.red.withOpacity(0.12);
      border = Colors.red.withOpacity(0.35);
      text = Colors.red.shade700;
    } else {
      bg = Colors.grey.withOpacity(0.12);
      border = Colors.grey.withOpacity(0.35);
      text = Colors.grey.shade700;
    }

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder:
              (_) => CustomConfirmDialog(
                title:
                    s == "active"
                        ? "هل أنت متأكد من تغيير الحالة الى (مقفل)؟"
                        : "هل أنت متأكد من تغيير الحالة الى (مفتوح)؟",
                confirmText: "تأكيد",
                cancelText: "إلغاء",
                onConfirm: () {
                  if (s == "active") {
                    context.read<AppCubitAdmin>().updateStatusOfUser(
                      context: context,
                      id: userId.toString(),
                      status: 'blocked',
                    );
                  } else if (s == "blocked") {
                    context.read<AppCubitAdmin>().updateStatusOfUser(
                      context: context,
                      id: userId.toString(),
                      status: 'active',
                    );
                  } else if (s == "pending") {
                    context.read<AppCubitAdmin>().updateStatusOfUser(
                      context: context,
                      id: userId.toString(),
                      status: 'active',
                    );
                  }
                  Navigator.of(context).pop();
                },
              ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Text(
          status,
          style: TextStyle(
            color: text,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPage;

  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.onPage,
  });

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages(currentPage, totalPages);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _NavBtn(
          title: "التالي",
          icon: Iconsax.arrow_left_2,
          enabled: currentPage < totalPages,
          onTap: () => onPage(currentPage + 1),
        ),
        const SizedBox(width: 10),

        Wrap(
          spacing: 8,
          children:
              pages.map((p) {
                if (p == -1) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      "...",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }
                final selected = p == currentPage;
                return InkWell(
                  onTap: () => onPage(p),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 38,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? secondPrimaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? secondPrimaryColor : Colors.black12,
                      ),
                    ),
                    child: Text(
                      "$p",
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),

        const SizedBox(width: 10),
        _NavBtn(
          title: "السابق",
          icon: Iconsax.arrow_right_3,
          enabled: currentPage > 1,
          onTap: () => onPage(currentPage - 1),
        ),
      ],
    );
  }

  static List<int> _buildPages(int current, int total) {
    if (total <= 7) {
      return List.generate(total, (i) => i + 1);
    }

    final List<int> out = [];

    out.add(1);

    int start = (current - 1).clamp(2, total - 1);
    int end = (current + 1).clamp(2, total - 1);

    if (start > 2) out.add(-1);

    for (int i = start; i <= end; i++) {
      out.add(i);
    }

    if (end < total - 1) out.add(-1);

    out.add(total);

    if (current <= 3) {
      out
        ..clear()
        ..addAll([1, 2, 3, 4, -1, total]);
    }
    if (current >= total - 2) {
      out
        ..clear()
        ..addAll([1, -1, total - 3, total - 2, total - 1, total]);
    }

    final unique = <int>[];
    for (final x in out) {
      if (unique.isEmpty || unique.last != x) unique.add(x);
    }
    return unique;
  }
}

class _NavBtn extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _NavBtn({
    required this.title,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: enabled ? Colors.black12 : Colors.black12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: enabled ? secondPrimaryColor : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: enabled ? Colors.black87 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverCard extends StatefulWidget {
  final Driver driver;
  const _DriverCard({required this.driver});

  @override
  State<_DriverCard> createState() => _DriverCardState();
}

class _DriverCardState extends State<_DriverCard> {
  bool open = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.driver;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => open = !open),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: secondPrimaryColor.withOpacity(0.15),
                    child: Text(
                      d.name.isNotEmpty ? d.name[0] : "D",
                      style: const TextStyle(
                        color: secondPrimaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            d.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            textAlign: TextAlign.right,
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.25),
                              ),
                            ),
                            child: Text(
                              "ID: ${d.id}",
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: () {
                              navigateTo(
                                context,
                                DriverOrder(driverId: d.id.toString()),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: secondPrimaryColor.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: secondPrimaryColor.withOpacity(0.25),
                                ),
                              ),
                              child: Text(
                                "الطلبات",
                                style: TextStyle(
                                  color: secondPrimaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            d.phone,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Iconsax.call,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                barrierDismissible: true,
                                builder:
                                    (_) => CustomConfirmDialog(
                                      title:
                                          "هل أنت متأكد من حذف هذا المستخدم؟",
                                      confirmText: "تأكيد",
                                      cancelText: "إلغاء",
                                      onConfirm: () {
                                        context
                                            .read<AppCubitAdmin>()
                                            .deleteUser(
                                              context: context,
                                              id: d.id.toString(),
                                            );
                                        Navigator.of(context).pop();
                                      },
                                    ),
                              );
                            },

                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.redAccent.withOpacity(0.25),
                                ),
                              ),
                              child: Text(
                                "حذف المستخدم",
                                style: TextStyle(
                                  color: Colors.redAccent.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Spacer(),
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      _StatusChip(status: d.status, userId: d.id.toString()),
                      const SizedBox(height: 8),
                      Icon(
                        open ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1,
                        color: Colors.grey,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            crossFadeState:
                open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Divider(height: 16),
                  Wrap(
                    textDirection: TextDirection.rtl,
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.start,
                    children: [
                      _InfoPill(title: "نوع المركبة", value: d.vehicleType),
                      _InfoPill(title: "لون المركبة", value: d.vehicleColor),
                      _InfoPill(title: "رقم المركبة", value: d.vehicleNumber),
                      _InfoPill(title: "الديون", value: d.driverDebt),
                      _InfoPill(
                        title: "Debt Blocked",
                        value: d.isDebtBlocked ? "نعم" : "لا",
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.end,
                    children: [
                      _InfoPill(title: "الديون", value: d.driverDebt),
                      _InfoPill(
                        title: "Debt Blocked",
                        value: d.isDebtBlocked ? "نعم" : "لا",
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  CustomButton(
                    title: 'الطلبات',
                    onPressed: () {
                      navigateTo(
                        context,
                        DriverOrder(driverId: d.id.toString()),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap:
                        () => _showWalletTopUpDialog(context, d.id.toString()),
                    child: Container(
                      width: double.maxFinite,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.money_send,
                            color: Colors.green.shade700,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "شحن رصيد",
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _InfoLine(
                    icon: Iconsax.location,
                    title: "الموقع",
                    value: d.location,
                  ),

                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.end,
                    children: [
                      _InfoPill(title: "Created", value: _fmtDate(d.createdAt)),
                      _InfoPill(title: "Updated", value: _fmtDate(d.updatedAt)),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.end,
                    children: [
                      _ImageMiniCard(
                        title: "صورة السائق",
                        fileName: d.driverImage.main,
                      ),
                      _ImageMiniCard(
                        title: "صورة السيارة",
                        fileName: d.carImages.main,
                      ),
                      _ImageMiniCard(
                        title: "اجازة أمام",
                        fileName: d.drivingLicenseFront.main,
                      ),
                      _ImageMiniCard(
                        title: "اجازة خلف",
                        fileName: d.drivingLicenseBack.main,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
}

void _showWalletTopUpDialog(BuildContext context, String driverId) {
  final amountCtrl = TextEditingController();
  final noteCtrl = TextEditingController(text: "شحن محفظة من الإدارة");

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              "شحن محفظة الكابتن",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            SizedBox(width: 8),
            Icon(Iconsax.wallet_add, color: Colors.green),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Directionality(
              textDirection: TextDirection.rtl,
              child: TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "مبلغ الشحن (SYP)",
                  hintText: "مثلاً 10000",
                  prefixIcon: Icon(Iconsax.money),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Directionality(
              textDirection: TextDirection.rtl,
              child: TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  labelText: "ملاحظة",
                  hintText: "سبب الشحن",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "إلغاء",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            icon: const Icon(Iconsax.wallet_add, color: Colors.white, size: 18),
            label: const Text(
              "شحن",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () async {
              final amount = amountCtrl.text.trim();
              if (amount.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await DioHelper.postData(
                  url: '/admin/users/$driverId/wallet/credit',
                  data: {
                    'amount': double.tryParse(amount) ?? 0,
                    'note': noteCtrl.text.trim(),
                  },
                  token: token,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم شحن محفظة الكابتن بمبلغ $amount SYP'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('خطأ: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      );
    },
  );
}

class _InfoPill extends StatelessWidget {
  final String title;
  final String value;
  const _InfoPill({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _InfoLine({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(icon, size: 18, color: secondPrimaryColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _ImageMiniCard extends StatelessWidget {
  final String title;
  final String fileName;
  const _ImageMiniCard({required this.title, required this.fileName});

  @override
  Widget build(BuildContext context) {
    final imageUrl = "$url/uploads/$fileName";

    return Container(
      width: 230,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrl,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) => Container(
                    height: 120,
                    alignment: Alignment.center,
                    color: Colors.grey.shade100,
                    child: const Text("لا يمكن عرض الصورة"),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
