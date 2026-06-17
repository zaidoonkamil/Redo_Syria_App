import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/ navigation/navigation.dart';
import '../../../core/styles/themes.dart';
import '../../../core/widgets/CustomButton.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/constant.dart';
import '../../../core/network/local/cache_helper.dart';

import '../../admin/view/admin_dashboard_screen.dart';
import '../../driver/view/driver_home.dart';
import '../../user/view/home.dart';
import '../../driver/cubit/cubit.dart';
import '../../user/cubit/cubit.dart';

import '../cubit/cubit.dart';
import '../cubit/states.dart';

class VerifyAccountScreen extends StatelessWidget {
  VerifyAccountScreen({super.key, required this.phone});

  static GlobalKey<FormState> formKey = GlobalKey<FormState>();
  static TextEditingController codeController = TextEditingController();

  final String phone;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginCubit(),
      child: BlocConsumer<LoginCubit, LoginStates>(
        listener: (context, state) async {
          if (state is VerifyOtpSuccessState) {
            final cubit = LoginCubit.get(context);

            await CacheHelper.saveData(key: 'token', value: cubit.token);
            await CacheHelper.saveData(key: 'id', value: cubit.id);
            await CacheHelper.saveData(key: 'role', value: cubit.role);

            token = cubit.token.toString();
            id = cubit.id.toString();
            adminOrUser = cubit.role.toString();

            if (adminOrUser == 'admin') {
              cubit.registerDevice(cubit.id.toString());
              navigateAndFinish(context, AdminDashboardScreen());
            } else if (adminOrUser == 'driver') {
              cubit.registerDevice(cubit.id.toString());
              final driverCubit = DriverCubit();

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: CircularProgressIndicator(color: secondPrimaryColor),
                ),
              );

              try {
                await driverCubit.init();
                if (context.mounted) Navigator.pop(context);
                if (context.mounted) navigateAndFinish(context, DriverHome(cubit: driverCubit));
              } catch (_) {
                if (context.mounted) Navigator.pop(context);
                if (context.mounted) navigateAndFinish(context, DriverHome(cubit: driverCubit));
              }
            } else {
              cubit.registerDevice(cubit.id.toString());
              final userCubit = UserCubit();

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: CircularProgressIndicator(color: secondPrimaryColor),
                ),
              );

              try {
                await userCubit.init();
                if (context.mounted) Navigator.pop(context);
                if (context.mounted) navigateAndFinish(context, Home(cubit: userCubit));
              } catch (_) {
                if (context.mounted) Navigator.pop(context);
                if (context.mounted) navigateAndFinish(context, Home(cubit: userCubit));
              }
            }
          }
        },
        builder: (context, state) {
          final cubit = LoginCubit.get(context);
          cubit.initOtpFlow(phone, context);

          final secondsLeft = cubit.otpSecondsLeft;

          return Container(
            color: Colors.white,
            child: SafeArea(
              child: Scaffold(
                body: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      Container(
                        width: double.maxFinite,
                        height: 250,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(28),
                            bottomRight: Radius.circular(28),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [
                              secondPrimaryColor.withOpacity(0.55),
                              secondPrimaryColor,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(55.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'توثيق الحساب',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'ادخل رمز التحقق المرسل عبر واتساب',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'الى ${cubit.normalizePhone(phone)}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Form(
                          key: formKey,
                          child: Column(
                            children: [
                              const SizedBox(height: 40),

                              CustomTextField(
                                hintText: 'رمز التحقق (6 أرقام)',
                                controller: codeController,
                                keyboardType: TextInputType.number,
                                suffixIcon: const Icon(Iconsax.password_check),
                                validate: (String? value) {
                                  final v = (value ?? '').trim();
                                  if (v.isEmpty) return 'رجائاً ادخل رمز التحقق';
                                  if (v.length < 4) return 'الرمز قصير';
                                  return null;
                                },
                              ),

                              const SizedBox(height: 30),

                              ConditionalBuilder(
                                condition: state is! VerifyOtpLoadingState,
                                builder: (c) => CustomButton(
                                  title: 'تأكيد الرمز',
                                  onPressed: () {
                                    if (formKey.currentState!.validate()) {
                                      cubit.verifyOtp(
                                        phone: phone,
                                        code: codeController.text.trim(),
                                        context: context,
                                      );
                                    }
                                  },
                                ),
                                fallback: (c) => const CircularProgressIndicator(color: primaryColor),
                              ),

                              const SizedBox(height: 18),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  secondsLeft > 0 ? Container():GestureDetector(
                                    onTap: secondsLeft > 0
                                        ? null
                                        : () {
                                      cubit.sendOtp(phone: phone, context: context);
                                      cubit.startResendCooldown();
                                    },
                                    child: Text(
                                      'إعادة إرسال',
                                      style: TextStyle(
                                        color: secondsLeft > 0 ? Colors.grey : primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    secondsLeft > 0
                                        ? 'يمكن إعادة الإرسال بعد $secondsLeft ثانية'
                                        : 'لم يصلك الرمز؟',
                                    style: const TextStyle(
                                      color: secondPrimaryTextColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
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
