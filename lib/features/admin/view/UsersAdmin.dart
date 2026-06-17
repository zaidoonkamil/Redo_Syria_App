import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rido_syria_app/core/%20navigation/navigation.dart';

import 'package:rido_syria_app/core/styles/themes.dart';
import 'package:rido_syria_app/core/widgets/CustomButton.dart';
import 'package:rido_syria_app/core/widgets/CustomDialog.dart';
import 'package:rido_syria_app/features/admin/cubit/cubit.dart';
import 'package:rido_syria_app/features/admin/cubit/states.dart';
import 'package:rido_syria_app/features/admin/view/AddUser.dart';

import 'AddAdmin.dart';
import 'package:rido_syria_app/core/network/remote/dio_helper.dart';
import 'package:rido_syria_app/core/widgets/constant.dart';

class UsersAdmin extends StatefulWidget {
  const UsersAdmin({super.key});

  @override
  State<UsersAdmin> createState() => _AdminUsersState();
}

class _AdminUsersState extends State<UsersAdmin> {
  int _page = 1;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AppCubitAdmin()..getAdminsOnly(context: context, page: "1"),
      child: BlocConsumer<AppCubitAdmin, AppStatesAdmin>(
        listener: (context, state) {},
        builder: (context, state) {
          final cubit = AppCubitAdmin.get(context);
          final model = cubit.getAdminOnlyModel;

          final isLoading = state is GetUsersOnlyLoadingState && model == null;

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
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
                          )
                        ],
                      ),
                      child: isLoading
                          ? const Center(
                        child: CircularProgressIndicator(color: secondPrimaryColor),
                      )
                          : (model == null || model.users.isEmpty)
                          ? const Center(child: Text("لا يوجد مستخدمين"))
                          : Column(
                        children: [
                          _TopStatsRow(
                            total: model.pagination.totalDrivers,
                            page: model.pagination.currentPage,
                            pages: model.pagination.totalPages,
                            limit: model.pagination.limit,
                          ),
                          SizedBox(height: 4,),
                          const Divider(height: 1),
                          SizedBox(height: 4,),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: CustomButton(title: 'اضافة ادمن', onPressed: (){
                              navigateTo(context, AddAdmin());
                            }),
                          ),
                          SizedBox(height: 4,),
                          const Divider(height: 1),
                          SizedBox(height: 4,),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(minWidth: 1100),
                                child: SingleChildScrollView(
                                  child: DataTable(
                                    headingRowHeight: 52,
                                    dataRowMinHeight: 52,
                                    dataRowMaxHeight: 64,
                                    headingRowColor: MaterialStateProperty.all(secondPrimaryColor),
                                    columns: const [
                                      DataColumn(
                                        label: Text("ID",
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                      DataColumn(
                                        label: Text("الاسم",
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                      DataColumn(
                                        label: Text("الهاتف",
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                      DataColumn(
                                        label: Text("الدور",
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                      DataColumn(
                                        label: Text("الحالة",
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                       DataColumn(
                                         label: Text("الديون",
                                             style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                       ),
                                       DataColumn(
                                         label: Text("المحفظة",
                                             style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                       ),
                                      DataColumn(
                                        label: Text("تاريخ الإنشاء",
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                    rows: model.users.map((u) {
                                      return DataRow(
                                        cells: [
                                          DataCell(Text(u.id.toString())),
                                          DataCell(Text(u.name)),
                                          DataCell(Text(u.phone)),
                                          DataCell(_RoleChip(role: u.role, userId: u.id.toString(),)),
                                          DataCell(_StatusChip(status: u.status, userId: u.id.toString(),)),
                                           DataCell(Text(u.driverDebt.toString())),
                                           DataCell(
                                             InkWell(
                                               onTap: () => _showUserWalletTopUpDialog(context, u.id.toString(), u.name),
                                               borderRadius: BorderRadius.circular(8),
                                               child: Container(
                                                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                 decoration: BoxDecoration(
                                                   color: Colors.green.withOpacity(0.10),
                                                   borderRadius: BorderRadius.circular(8),
                                                   border: Border.all(color: Colors.green.withOpacity(0.3)),
                                                 ),
                                                 child: Row(
                                                   mainAxisSize: MainAxisSize.min,
                                                   children: [
                                                     Icon(Iconsax.wallet_add, color: Colors.green.shade700, size: 15),
                                                     const SizedBox(width: 5),
                                                     Text("شحن",
                                                         style: TextStyle(
                                                             color: Colors.green.shade700,
                                                             fontWeight: FontWeight.bold,
                                                             fontSize: 12)),
                                                   ],
                                                 ),
                                               ),
                                             ),
                                           ),
                                          DataCell(Text(_fmtDate(u.createdAt))),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Pagination
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: _PaginationBar(
                              currentPage: model.pagination.currentPage,
                              totalPages: model.pagination.totalPages,
                              onPage: (p) {
                                setState(() => _page = p);
                                cubit.getUsersOnly(context: context, page: p.toString());
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (state is GetUsersOnlyLoadingState && model != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: const [
                          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: secondPrimaryColor)),
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

  static String _fmtDate(DateTime d) {
    return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  }
}

class _TopStatsRow extends StatelessWidget {
  final int total;
  final int page;
  final int pages;
  final int limit;

  const _TopStatsRow({required this.total, required this.page, required this.pages, required this.limit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.end,
        children: [
          _MiniStat(title: "الإجمالي", value: total.toString(), icon: Iconsax.people),
          _MiniStat(title: "الصفحة", value: "$page / $pages", icon: Iconsax.layer),
          _MiniStat(title: "لكل صفحة", value: limit.toString(), icon: Iconsax.document),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MiniStat({required this.title, required this.value, required this.icon});

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
              Text(title, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String role;
  final String userId;
  const _RoleChip({required this.role, required this.userId});

  @override
  Widget build(BuildContext context) {
    final r = role.toLowerCase();
    final isUser = r == "user";
    final isDriver = r == "driver";
    final isAdmin = r == "admin";

    Color bg;
    Color border;
    Color text;

    if (isAdmin) {
      bg = Colors.purple.withOpacity(0.12);
      border = Colors.purple.withOpacity(0.35);
      text = Colors.purple.shade700;
    } else if (isDriver) {
      bg = Colors.blue.withOpacity(0.12);
      border = Colors.blue.withOpacity(0.35);
      text = Colors.blue.shade700;
    } else if (isUser) {
      bg = Colors.green.withOpacity(0.12);
      border = Colors.green.withOpacity(0.35);
      text = Colors.green.shade700;
    } else {
      bg = Colors.grey.withOpacity(0.12);
      border = Colors.grey.withOpacity(0.35);
      text = Colors.grey.shade700;
    }

    return InkWell(
      onTap: (){
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (_) => CustomConfirmDialog(
            title: "هل أنت متأكد من حذف هذا الادمن؟",
            confirmText: "تأكيد",
            cancelText: "إلغاء",
            onConfirm: () {
              context.read<AppCubitAdmin>().deleteUser(
                context: context,
                id: userId,
              );
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
        child: Text(role, style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 12)),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(status, style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 12)),
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
          children: pages.map((p) {
            if (p == -1) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text("...", style: TextStyle(fontWeight: FontWeight.bold)),
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
                  border: Border.all(color: selected ? secondPrimaryColor : Colors.black12),
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
      out..clear()..addAll([1, 2, 3, 4, -1, total]);
    }
    if (current >= total - 2) {
      out..clear()..addAll([1, -1, total - 3, total - 2, total - 1, total]);
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

  const _NavBtn({required this.title, required this.icon, required this.enabled, required this.onTap});

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
            Icon(icon, size: 18, color: enabled ? secondPrimaryColor : Colors.grey),
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

void _showUserWalletTopUpDialog(BuildContext context, String userId, String userName) {
  final amountCtrl = TextEditingController();
  final noteCtrl   = TextEditingController(text: "شحن محفظة من الإدارة");

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              "شحن محفظة: $userName",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Iconsax.wallet_add, color: Colors.green),
        ],
      ),
      content: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "مبلغ الشحن (IQD)",
                hintText: "مثلاً 10000",
                prefixIcon: Icon(Iconsax.money),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: "ملاحظة",
                hintText: "سبب الشحن",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text("إلغاء",
              style: TextStyle(color: Colors.redAccent)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          icon: const Icon(Iconsax.wallet_add, color: Colors.white, size: 17),
          label: const Text("شحن",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          onPressed: () async {
            final amount = amountCtrl.text.trim();
            if (amount.isEmpty) return;
            Navigator.pop(ctx);
            try {
              await DioHelper.postData(
                url: '/admin/users/$userId/wallet/credit',
                data: {
                  'amount': double.tryParse(amount) ?? 0,
                  'note': noteCtrl.text.trim(),
                },
                token: token,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('تم شحن محفظة $userName بمبلغ $amount IQD'),
                  backgroundColor: Colors.green,
                ));
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('خطأ: $e'),
                  backgroundColor: Colors.red,
                ));
              }
            }
          },
        ),
      ],
    ),
  );
}
