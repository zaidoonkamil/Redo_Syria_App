import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rido_syria_app/core/styles/themes.dart';
import 'package:rido_syria_app/core/widgets/CustomButton.dart';
import 'package:rido_syria_app/core/widgets/show_toast.dart';
import 'package:rido_syria_app/features/admin/cubit/cubit.dart';
import 'package:rido_syria_app/features/admin/cubit/states.dart';
import 'package:rido_syria_app/features/admin/model/AdminPricingTiersModel.dart';

class Setting extends StatefulWidget {
  const Setting({super.key});

  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  final _pricingFormKey = GlobalKey<FormState>();
  final _tiersFormKey = GlobalKey<FormState>();

  final _baseFareController = TextEditingController();
  final _priceController = TextEditingController();
  final _pricePerMinuteController = TextEditingController();
  final _minimumFareController = TextEditingController();
  final _surgeMultiplierController = TextEditingController();

  final _debtFormKey = GlobalKey<FormState>();
  final _commissionController = TextEditingController();

  final List<_TierInputRow> _tierRows = [];

  bool _surgeEnabled = false;
  String? _lastPricingSignature;
  String? _lastDebtSignature;

  @override
  void dispose() {
    _baseFareController.dispose();
    _priceController.dispose();
    _pricePerMinuteController.dispose();
    _minimumFareController.dispose();
    _surgeMultiplierController.dispose();
    _commissionController.dispose();
    _disposeTierRows();
    super.dispose();
  }

  void _disposeTierRows() {
    for (final row in _tierRows) {
      row.dispose();
    }
    _tierRows.clear();
  }

  void _replaceTierRows(List<PricingTierItem> tiers) {
    _disposeTierRows();

    if (tiers.isEmpty) {
      _tierRows.add(_TierInputRow(fromKm: '0'));
      return;
    }

    for (final tier in tiers) {
      _tierRows.add(
        _TierInputRow(
          fromKm: tier.fromKm,
          toKm: tier.toKm,
          pricePerKm: tier.pricePerKm,
        ),
      );
    }
  }

  void _syncPricingInputs(AppCubitAdmin cubit) {
    final pricing = cubit.adminPricingModel?.pricing;
    final tiers = cubit.pricingTiers;
    final signature = [
      cubit.pricingServiceType,
      pricing?.baseFare ?? '',
      pricing?.pricePerKm ?? '',
      pricing?.pricePerMinute?.toString() ?? '',
      pricing?.minimumFare?.toString() ?? '',
      pricing?.surgeEnabled?.toString() ?? 'false',
      pricing?.surgeMultiplier ?? '',
      tiers.map((tier) => '${tier.fromKm}-${tier.toKm ?? 'open'}-${tier.pricePerKm}').join('|'),
    ].join('::');

    if (_lastPricingSignature == signature) {
      return;
    }

    _baseFareController.text = pricing?.baseFare?.toString() ?? '';
    _priceController.text = pricing?.pricePerKm?.toString() ?? '';
    _pricePerMinuteController.text = pricing?.pricePerMinute?.toString() ?? '';
    _minimumFareController.text = pricing?.minimumFare?.toString() ?? '';
    _surgeMultiplierController.text = pricing?.surgeMultiplier?.toString() ?? '1';
    _surgeEnabled = pricing?.surgeEnabled == true;
    _replaceTierRows(tiers);
    _lastPricingSignature = signature;
  }

  void _syncDebtInputs(AppCubitAdmin cubit) {
    final signature = [
      cubit.commissionValue ?? '',
      cubit.commissionTypeValue ?? '',
    ].join('::');

    if (_lastDebtSignature == signature) {
      return;
    }
    _commissionController.text = cubit.commissionValue ?? '';
    _lastDebtSignature = signature;
  }

  double? _parseNumber(String value) {
    return double.tryParse(value.trim());
  }

  bool _isZero(double value) => value.abs() <= 0.0001;

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  List<Map<String, dynamic>>? _buildTierPayload(BuildContext context) {
    if (!_tiersFormKey.currentState!.validate()) {
      return null;
    }

    if (_tierRows.isEmpty) {
      showSnackBarError(text: 'أضف شريحة واحدة على الأقل', context: context);
      return null;
    }

    final payload = <Map<String, dynamic>>[];
    double? previousToKm;

    for (var index = 0; index < _tierRows.length; index++) {
      final row = _tierRows[index];
      final fromKm = _parseNumber(row.fromKmController.text);
      final toText = row.toKmController.text.trim();
      final toKm = toText.isEmpty ? null : _parseNumber(toText);
      final pricePerKm = _parseNumber(row.pricePerKmController.text);

      if (fromKm == null || fromKm < 0) {
        showSnackBarError(text: 'قيمة بداية الشريحة ${index + 1} غير صحيحة', context: context);
        return null;
      }

      if (pricePerKm == null || pricePerKm <= 0) {
        showSnackBarError(text: 'سعر الكيلومتر في الشريحة ${index + 1} غير صحيح', context: context);
        return null;
      }

      if (toKm != null && toKm <= fromKm) {
        showSnackBarError(text: 'نهاية الشريحة ${index + 1} لازم تكون أكبر من البداية', context: context);
        return null;
      }

      if (index == 0 && !_isZero(fromKm)) {
        showSnackBarError(text: 'أول شريحة لازم تبدأ من 0 كم', context: context);
        return null;
      }

      if (index > 0) {
        if (previousToKm == null) {
          showSnackBarError(text: 'الشريحة المفتوحة لازم تكون الأخيرة', context: context);
          return null;
        }

        if ((fromKm - previousToKm).abs() > 0.0001) {
          showSnackBarError(
            text: 'بداية الشريحة ${index + 1} لازم تساوي نهاية الشريحة السابقة',
            context: context,
          );
          return null;
        }
      }

      if (toKm == null && index != _tierRows.length - 1) {
        showSnackBarError(text: 'فقط آخر شريحة تكون مفتوحة النهاية', context: context);
        return null;
      }

      payload.add({
        'fromKm': _formatNumber(fromKm),
        'toKm': toKm == null ? null : _formatNumber(toKm),
        'pricePerKm': _formatNumber(pricePerKm),
      });

      previousToKm = toKm;
    }

    if (payload.last['toKm'] != null) {
      showSnackBarError(text: 'آخر شريحة لازم تكون مفتوحة النهاية', context: context);
      return null;
    }

    return payload;
  }

  Widget _sectionContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: containerColor,
        border: Border.all(width: 1, color: borderColor),
      ),
      child: child,
    );
  }

  Widget _sectionHeader({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    String? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.08),
            secondPrimaryColor.withOpacity(0.08),
          ],
        ),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (trailing != null)
            Text(
              trailing,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.black54,
                  ),
            ),
          if (trailing != null) const Spacer(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(title),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: iconColor.withOpacity(0.12),
            ),
            child: Icon(icon, color: iconColor),
          ),
        ],
      ),
    );
  }

  Widget _serviceTypeOption({
    required BuildContext context,
    required String label,
    required String value,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: selected ? secondPrimaryColor.withOpacity(0.12) : Colors.white,
            border: Border.all(
              color: selected ? secondPrimaryColor : borderColor,
            ),
          ),
          child: Column(
            children: [
              Icon(
                value == 'vip' ? Iconsax.crown : Iconsax.car,
                color: selected ? secondPrimaryColor : Colors.black54,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: selected ? secondPrimaryColor : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    bool allowZero = true,
    bool optional = false,
  }) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixIcon: icon == null ? null : Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        validator: (value) {
          final text = (value ?? '').trim();
          if (text.isEmpty) {
            return optional ? null : 'هذا الحقل مطلوب';
          }

          final number = num.tryParse(text);
          if (number == null) return 'القيمة غير صحيحة';
          if (!allowZero && number <= 0) return 'لازم تكون أكبر من صفر';
          if (allowZero && number < 0) return 'لازم تكون صفر أو أكثر';
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AppCubitAdmin()
        ..getAdminPricing(context: context)
        ..getAdminDebtSettings(context: context),
      child: BlocConsumer<AppCubitAdmin, AppStatesAdmin>(
        listener: (context, state) {
          if (state is UpdateAdminPricingSuccessState) {
            showSnackBarSuccess(text: 'تم تحديث إعدادات التسعير', context: context);
          }
          if (state is UpdateAdminPricingTiersSuccessState) {
            showSnackBarSuccess(text: 'تم تحديث الشرائح السعرية', context: context);
          }
          if (state is UpdateAdminDebtSettingsSuccessState) {
            showSnackBarSuccess(text: 'تم تحديث إعدادات العمولة', context: context);
          }
        },
        builder: (context, state) {
          final cubit = AppCubitAdmin.get(context);

          final isLoadingGet = state is AdminPricingLoadingState;
          final isLoadingUpdate = state is UpdateAdminPricingLoadingState;
          final isLoadingTiersUpdate = state is UpdateAdminPricingTiersLoadingState;
          final isLoadingDebtGet = state is AdminDebtSettingsLoadingState;
          final isLoadingDebtUpdate = state is UpdateAdminDebtSettingsLoadingState;

          final pricingModel = cubit.adminPricingModel;
          final debtModel = cubit.adminDebtSettingsModel;
          final currentServiceType = cubit.pricingServiceType;

          if (pricingModel != null) {
            _syncPricingInputs(cubit);
          }
          if (debtModel != null) {
            _syncDebtInputs(cubit);
          }

          if (isLoadingGet || pricingModel == null) {
            return const SafeArea(
              child: Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: secondPrimaryColor),
                ),
              ),
            );
          }

          final pricing = pricingModel.pricing;
          final tierCount = cubit.pricingTiers.length;

          return SafeArea(
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _sectionContainer(
                        child: Column(
                          children: [
                            _sectionHeader(
                              context: context,
                              title: 'نوع التسعير',
                              subtitle: currentServiceType == 'vip'
                                  ? 'أنت تعدل الآن تسعيرة VIP'
                                  : 'أنت تعدل الآن التسعيرة العادية',
                              icon: currentServiceType == 'vip' ? Iconsax.crown : Iconsax.car,
                              iconColor: currentServiceType == 'vip' ? Colors.amber : secondPrimaryColor,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _serviceTypeOption(
                                  context: context,
                                  label: 'عادي',
                                  value: 'normal',
                                  selected: currentServiceType == 'normal',
                                  onTap: () => cubit.changeAdminPricingServiceType(
                                    context: context,
                                    serviceType: 'normal',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _serviceTypeOption(
                                  context: context,
                                  label: 'VIP',
                                  value: 'vip',
                                  selected: currentServiceType == 'vip',
                                  onTap: () => cubit.changeAdminPricingServiceType(
                                    context: context,
                                    serviceType: 'vip',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _sectionContainer(
                        child: Column(
                          children: [
                            _sectionHeader(
                              context: context,
                              title: 'إعدادات التسعير الأساسية',
                              subtitle:
                                  'Base: ${pricing?.baseFare ?? '--'} | Min: ${pricing?.minimumFare ?? '--'} | Tiers: $tierCount',
                              icon: Iconsax.wallet,
                              iconColor: Colors.blue,
                              trailing: 'IQD',
                            ),
                            const SizedBox(height: 18),
                            Form(
                              key: _pricingFormKey,
                              child: Column(
                                children: [

                                  _numberField(
                                    controller: _priceController,
                                    label: 'السعر لكل كيلومتر',
                                    hint: 'مثال: 500',
                                    icon: Iconsax.routing,
                                  ),
                                  const SizedBox(height: 12),
                                  _numberField(
                                    controller: _minimumFareController,
                                    label: 'الحد الأدنى',
                                    hint: 'مثال: 3000',
                                    icon: Iconsax.chart,
                                  ),
                                  // const SizedBox(height: 12),
                                  // SwitchListTile.adaptive(
                                  //   contentPadding: EdgeInsets.zero,
                                  //   value: _surgeEnabled,
                                  //   activeColor: secondPrimaryColor,
                                  //   title: const Text(
                                  //     'تفعيل Surge',
                                  //     textAlign: TextAlign.right,
                                  //   ),
                                  //   subtitle: const Text(
                                  //     'فعّلها إذا تريد تطبيق معامل مضاعف على السعر النهائي',
                                  //     textAlign: TextAlign.right,
                                  //   ),
                                  //   onChanged: (value) {
                                  //     setState(() {
                                  //       _surgeEnabled = value;
                                  //     });
                                  //   },
                                  // ),
                                  // const SizedBox(height: 12),
                                  // _numberField(
                                  //   controller: _surgeMultiplierController,
                                  //   label: 'Surge multiplier',
                                  //   hint: 'مثال: 1 أو 1.5',
                                  //   icon: Iconsax.flash_1,
                                  //   allowZero: false,
                                  // ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            isLoadingUpdate
                                ? const CircularProgressIndicator(color: secondPrimaryColor)
                                : CustomButton(
                                    title: 'تحديث إعدادات التسعير',
                                    onPressed: () async {
                                      if (!_pricingFormKey.currentState!.validate()) {
                                        return;
                                      }

                                      await cubit.updateAdminPricingAndReload(
                                        context: context,
                                        serviceType: currentServiceType,
                                        baseFare: _baseFareController.text.trim(),
                                        pricePerKm: _priceController.text.trim(),
                                        pricePerMinute: _pricePerMinuteController.text.trim(),
                                        minimumFare: _minimumFareController.text.trim(),
                                        surgeEnabled: _surgeEnabled,
                                        surgeMultiplier: _surgeMultiplierController.text.trim(),
                                      );
                                    },
                                  ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _sectionContainer(
                        child: Column(
                          children: [
                            _sectionHeader(
                              context: context,
                              title: 'الشرائح السعرية',
                              subtitle: tierCount == 0
                                  ? 'لا توجد شرائح محفوظة، سيتم استخدام السعر لكل كيلومتر'
                                  : '$tierCount شريحة محفوظة لهذا النوع',
                              icon: Iconsax.hierarchy,
                              iconColor: Colors.deepPurple,
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'اترك نهاية آخر شريحة فارغة حتى تكون مفتوحة. مثال: 0-10 ثم 10-20 ثم 20-مفتوحة.',
                                textAlign: TextAlign.right,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.black54,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Form(
                              key: _tiersFormKey,
                              child: Column(
                                children: [
                                  for (var index = 0; index < _tierRows.length; index++) ...[
                                    _TierCard(
                                      index: index,
                                      row: _tierRows[index],
                                      onRemove: _tierRows.length == 1
                                          ? null
                                          : () {
                                              setState(() {
                                                final row = _tierRows.removeAt(index);
                                                row.dispose();
                                              });
                                            },
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: secondPrimaryColor,
                                side: const BorderSide(color: secondPrimaryColor),
                                minimumSize: const Size(double.infinity, 46),
                              ),
                              onPressed: () {
                                setState(() {
                                  final nextFrom = _tierRows.isEmpty
                                      ? ''
                                      : _tierRows.last.toKmController.text.trim();
                                  _tierRows.add(_TierInputRow(fromKm: nextFrom));
                                });
                              },
                              icon: const Icon(Iconsax.add),
                              label: const Text('إضافة شريحة'),
                            ),
                            const SizedBox(height: 14),
                            isLoadingTiersUpdate
                                ? const CircularProgressIndicator(color: secondPrimaryColor)
                                : CustomButton(
                                    title: 'حفظ الشرائح السعرية',
                                    onPressed: () async {
                                      final payload = _buildTierPayload(context);
                                      if (payload == null) {
                                        return;
                                      }

                                      await cubit.updateAdminPricingTiersAndReload(
                                        context: context,
                                        serviceType: currentServiceType,
                                        tiers: payload,
                                      );
                                    },
                                  ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _sectionContainer(
                        child: Column(
                          children: [
                            _sectionHeader(
                              context: context,
                              title: 'إعدادات عمولة السائق',
                              subtitle: 'Commission: ${cubit.commissionValue ?? '--'} نوع: ${cubit.commissionTypeValue ?? '--'}',
                              icon: Iconsax.percentage_square,
                              iconColor: Colors.green,
                              trailing: cubit.commissionTypeValue ?? '--',
                            ),
                            const SizedBox(height: 18),
                            if (isLoadingDebtGet || debtModel == null)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(color: secondPrimaryColor),
                              )
                            else
                              Form(
                                key: _debtFormKey,
                                child: Column(
                                  children: [
                                    _numberField(
                                      controller: _commissionController,
                                      label: 'نسبة العمولة (%)',
                                      hint: 'مثال: 20',
                                      icon: Iconsax.percentage_square,
                                    ),
                                    const SizedBox(height: 14),
                                    isLoadingDebtUpdate
                                        ? const CircularProgressIndicator(color: secondPrimaryColor)
                                        : CustomButton(
                                            title: 'تحديث إعدادات العمولة',
                                            onPressed: () async {
                                              if (!_debtFormKey.currentState!.validate()) {
                                                return;
                                              }
                                              await cubit.updateAdminDebtSettingsAndReload(
                                                context: context,
                                                driverDebtLimit: '0',
                                                driverCommissionValue: _commissionController.text.trim(),
                                                commissionType: 'percent',
                                              );
                                            },
                                          ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TierInputRow {
  final TextEditingController fromKmController;
  final TextEditingController toKmController;
  final TextEditingController pricePerKmController;

  _TierInputRow({
    String? fromKm,
    String? toKm,
    String? pricePerKm,
  })  : fromKmController = TextEditingController(text: fromKm ?? ''),
        toKmController = TextEditingController(text: toKm ?? ''),
        pricePerKmController = TextEditingController(text: pricePerKm ?? '');

  void dispose() {
    fromKmController.dispose();
    toKmController.dispose();
    pricePerKmController.dispose();
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.index,
    required this.row,
    this.onRemove,
  });

  final int index;
  final _TierInputRow row;
  final VoidCallback? onRemove;

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool optional = false,
  }) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        validator: (value) {
          final text = (value ?? '').trim();
          if (text.isEmpty) {
            return optional ? null : 'هذا الحقل مطلوب';
          }
          final number = num.tryParse(text);
          if (number == null) return 'القيمة غير صحيحة';
          if (number < 0) return 'القيمة لازم تكون موجبة';
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Iconsax.trash, color: Colors.redAccent),
                )
              else
                const SizedBox(width: 48),
              const Spacer(),
              Text(
                'الشريحة ${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: secondPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _numberField(
            controller: row.fromKmController,
            label: 'من كم',
            hint: 'مثال: 0',
          ),
          const SizedBox(height: 10),
          _numberField(
            controller: row.toKmController,
            label: 'إلى كم',
            hint: 'فارغ = مفتوحة النهاية',
            optional: true,
          ),
          const SizedBox(height: 10),
          _numberField(
            controller: row.pricePerKmController,
            label: 'السعر لكل كم',
            hint: 'مثال: 500',
          ),
        ],
      ),
    );
  }
}
