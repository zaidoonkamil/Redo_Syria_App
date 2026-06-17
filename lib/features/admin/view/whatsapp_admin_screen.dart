import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/styles/themes.dart';
import '../../../core/widgets/CustomButton.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../cubit/cubit.dart';
import '../cubit/states.dart';

class WhatsAppAdminScreen extends StatefulWidget {
  const WhatsAppAdminScreen({super.key});

  @override
  State<WhatsAppAdminScreen> createState() => _WhatsAppAdminScreenState();
}

class _WhatsAppAdminScreenState extends State<WhatsAppAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController(
    text: 'هذه رسالة تجريبية من لوحة تحكم Rido.',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = AppCubitAdmin.get(context);
      cubit.getWhatsAppStatus(context: context);
      cubit.getWhatsAppQr(context: context);
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppCubitAdmin, AppStatesAdmin>(
      listener: (context, state) {
        final cubit = AppCubitAdmin.get(context);
        if (state is WhatsAppInitSuccessState) {
          cubit.getWhatsAppQr(context: context);
          cubit.getWhatsAppStatus(context: context);
        }

        if (state is WhatsAppLogoutSuccessState ||
            state is WhatsAppSendSuccessState) {
          cubit.getWhatsAppStatus(context: context);
        }
      },
      builder: (context, state) {
        final cubit = AppCubitAdmin.get(context);
        final status = cubit.whatsAppStatus ?? {};
        final qrBytes = _decodeQr(
          cubit.whatsAppQrImage ?? status['qrImage']?.toString(),
        );
        final statusText = status['status']?.toString() ?? 'idle';
        final connectedNumber = status['connectedNumber']?.toString();
        final lastError = status['lastError']?.toString();
        final isLoading = state is WhatsAppLoadingState;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeaderCard(),
                  const SizedBox(height: 14),
                  _StatusCard(
                    status: statusText,
                    connectedNumber: connectedNumber,
                    lastError: lastError,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _ActionButton(
                        icon: Iconsax.play_circle,
                        label: 'تشغيل',
                        onTap:
                            isLoading
                                ? null
                                : () => cubit.initWhatsApp(context: context),
                      ),
                      _ActionButton(
                        icon: Icons.qr_code_rounded,
                        label: 'جلب QR',
                        onTap:
                            isLoading
                                ? null
                                : () => cubit.getWhatsAppQr(context: context),
                      ),
                      _ActionButton(
                        icon: Iconsax.refresh,
                        label: 'تحديث الحالة',
                        onTap:
                            isLoading
                                ? null
                                : () =>
                                    cubit.getWhatsAppStatus(context: context),
                      ),
                      _ActionButton(
                        icon: Iconsax.logout,
                        label: 'تسجيل خروج',
                        danger: true,
                        onTap:
                            isLoading
                                ? null
                                : () => cubit.logoutWhatsApp(context: context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _QrPanel(qrBytes: qrBytes, status: statusText),
                  const SizedBox(height: 14),
                  _TestMessagePanel(
                    formKey: _formKey,
                    phoneController: _phoneController,
                    messageController: _messageController,
                    isLoading: isLoading,
                    onSend: () {
                      if (_formKey.currentState!.validate()) {
                        cubit.sendWhatsAppTest(
                          context: context,
                          phone: _phoneController.text.trim(),
                          message: _messageController.text.trim(),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Uint8List? _decodeQr(String? dataUrl) {
    if (dataUrl == null || dataUrl.isEmpty) return null;
    final parts = dataUrl.split(',');
    final payload = parts.isNotEmpty ? parts.last : dataUrl;
    try {
      return base64Decode(payload);
    } catch (_) {
      return null;
    }
  }
}

class _HeaderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [
            secondPrimaryColor,
            secondPrimaryColor.withValues(alpha: 0.78),
          ],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ربط واتساب الأدمن',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'اربط رقم واتساب حتى يرسل النظام رموز OTP ورسائل التشغيل. عند فصل الجلسة تقدر تعيد الربط من هذه الصفحة.',
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.status,
    required this.connectedNumber,
    required this.lastError,
  });

  final String status;
  final String? connectedNumber;
  final String? lastError;

  Color get _statusColor {
    switch (status) {
      case 'ready':
        return Colors.green;
      case 'qr_ready':
      case 'authenticated':
      case 'initializing':
      case 'reconnecting':
        return primaryColor;
      case 'auth_failure':
      case 'failed':
      case 'disconnected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String get _statusLabel {
    switch (status) {
      case 'ready':
        return 'متصل وجاهز للإرسال';
      case 'qr_ready':
        return 'رمز QR جاهز للمسح';
      case 'authenticated':
        return 'تمت المصادقة وبانتظار الجاهزية';
      case 'initializing':
        return 'جاري تشغيل جلسة واتساب';
      case 'reconnecting':
        return 'جاري إعادة الاتصال تلقائيا';
      case 'disconnected':
        return 'تم فصل الاتصال';
      case 'failed':
        return 'فشل تشغيل الجلسة';
      case 'auth_failure':
        return 'فشل في المصادقة';
      default:
        return 'غير مرتبط';
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'حالة الربط',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(_statusLabel, style: const TextStyle(fontSize: 15)),
          if (connectedNumber != null && connectedNumber!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'الرقم المرتبط: $connectedNumber',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: secondPrimaryColor,
              ),
            ),
          ],
          if (lastError != null && lastError!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(lastError!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
    );
  }
}

class _QrPanel extends StatelessWidget {
  const _QrPanel({required this.qrBytes, required this.status});

  final Uint8List? qrBytes;
  final String status;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'QR الربط',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'إذا ظهر رمز QR امسحه من تطبيق واتساب على هاتف الأدمن عبر الأجهزة المرتبطة.',
            style: TextStyle(color: secondPrimaryTextColor),
          ),
          const SizedBox(height: 18),
          Center(
            child: Container(
              width: 240,
              height: 240,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child:
                  qrBytes != null
                      ? Image.memory(qrBytes!, fit: BoxFit.contain)
                      : Center(
                        child: Text(
                          status == 'ready'
                              ? 'الواتساب متصل وجاهز'
                              : 'اضغط تشغيل ثم جلب QR',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: secondPrimaryTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TestMessagePanel extends StatelessWidget {
  const _TestMessagePanel({
    required this.formKey,
    required this.phoneController,
    required this.messageController,
    required this.isLoading,
    required this.onSend,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController phoneController;
  final TextEditingController messageController;
  final bool isLoading;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'رسالة تجريبية',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'أرسل رسالة اختبار للتأكد أن الرقم المرتبط يعمل من داخل النظام.',
              style: TextStyle(color: secondPrimaryTextColor),
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: phoneController,
              hintText: 'رقم الهاتف',
              keyboardType: TextInputType.phone,
              suffixIcon: const Icon(Iconsax.call),
              validate: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'رجاء ادخل رقم الهاتف';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: messageController,
              hintText: 'نص الرسالة',
              maxLines: 4,
              suffixIcon: const Icon(Iconsax.message_text),
              validate: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'رجاء ادخل الرسالة';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: primaryColor),
                )
                : CustomButton(title: 'إرسال رسالة تجريبية', onPressed: onSend),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.red : secondPrimaryColor;

    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Opacity(
          opacity: onTap == null ? 0.55 : 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}
