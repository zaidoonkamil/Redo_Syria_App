import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/ navigation/navigation.dart';
import '../../../core/styles/themes.dart';
import '../../../core/widgets/CustomButton.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../cubit/cubit.dart';
import '../cubit/states.dart';
import 'login.dart';

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key, required this.phone});

  final String phone;

  static final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  static final TextEditingController _codeController = TextEditingController();
  static final TextEditingController _newPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginCubit, LoginStates>(
      listener: (context, state) {
        if (state is ResetPasswordSuccessState) {
          navigateAndFinish(context, const Login());
        }
      },
      builder: (context, state) {
        final cubit = LoginCubit.get(context);
        final secondsLeft = cubit.forgotSecondsLeft;

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
                                'وصلنـــــــي',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 35,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'تغيير كلمة المرور',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'الى $phone',
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
                        key: _formKey,
                        child: Column(
                          children: [
                            const SizedBox(height: 40),
                            CustomTextField(
                              hintText: 'رمز التحقق (6 أرقام)',
                              controller: _codeController,
                              keyboardType: TextInputType.number,
                              suffixIcon: const Icon(Iconsax.password_check),
                              validate: (String? value) {
                                final v = (value ?? '').trim();
                                if (v.isEmpty) return 'رجائاً ادخل رمز التحقق';
                                if (v.length < 4) return 'الرمز قصير جداً';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              hintText: 'كلمة المرور الجديدة',
                              controller: _newPasswordController,
                              obscureText: cubit.isPasswordHidden2,
                              suffixIcon: GestureDetector(
                                onTap: cubit.togglePasswordVisibility2,
                                child: Icon(
                                  cubit.isPasswordHidden2
                                      ? Iconsax.eye_slash
                                      : Iconsax.eye,
                                  color: Colors.black87,
                                ),
                              ),
                              validate: (String? value) {
                                final v = (value ?? '').trim();
                                if (v.isEmpty) return 'رجائاً ادخل كلمة مرور جديدة';
                                if (v.length < 6) return 'كلمة المرور قصيرة جداً (6 أحرف على الأقل)';
                                return null;
                              },
                            ),
                            const SizedBox(height: 30),
                            ConditionalBuilder(
                              condition: state is! ResetPasswordLoadingState,
                              builder: (c) => CustomButton(
                                title: 'تغيير كلمة المرور',
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    cubit.resetPassword(
                                      phone: phone,
                                      code: _codeController.text.trim(),
                                      newPassword: _newPasswordController.text,
                                      context: context,
                                    );
                                  }
                                },
                              ),
                              fallback: (c) => const CircularProgressIndicator(
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (secondsLeft == 0)
                                  GestureDetector(
                                    onTap: () {
                                      cubit.sendForgotOtp(
                                        phone: phone,
                                        context: context,
                                      );
                                    },
                                    child: const Text(
                                      'إعادة إرسال الرمز',
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                if (secondsLeft > 0)
                                  Text(
                                    'إعادة الإرسال بعد $secondsLeft ثانية',
                                    style: const TextStyle(
                                      color: secondPrimaryTextColor,
                                      fontSize: 13,
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
    );
  }
}
