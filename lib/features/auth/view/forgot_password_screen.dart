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
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  static final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  static final TextEditingController _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginCubit(),
      child: BlocConsumer<LoginCubit, LoginStates>(
        listener: (context, state) {
          if (state is ForgotSendOtpSuccessState) {
            final cubit = LoginCubit.get(context);
            final phone = cubit.forgotPhone ?? _phoneController.text.trim();

            navigateTo(
              context,
              BlocProvider.value(
                value: cubit,
                child: ResetPasswordScreen(phone: phone),
              ),
            );
          }
        },
        builder: (context, state) {
          final cubit = LoginCubit.get(context);
          return Container(
            color: Colors.white,
            child: SafeArea(
              child: Scaffold(
                body: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // ─── Header ────────────────────────────────────────────
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
                              children: const [
                                Text(
                                  'وصلنـــــــي',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 35,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'استعادة كلمة المرور',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'سيتم إرسال رمز التحقق عبر واتساب',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ─── Form ──────────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              const SizedBox(height: 40),
                              CustomTextField(
                                hintText: '9647712842105',
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                suffixIcon: const Icon(Iconsax.call),
                                validate: (String? value) {
                                  if ((value ?? '').trim().isEmpty) {
                                    return 'رجائاً ادخل رقم الهاتف';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 30),
                              ConditionalBuilder(
                                condition: state is! ForgotSendOtpLoadingState,
                                builder: (c) => CustomButton(
                                  title: 'إرسال رمز',
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      cubit.sendForgotOtp(
                                        phone: _phoneController.text.trim(),
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
