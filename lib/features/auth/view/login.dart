import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rido_syria_app/core/widgets/show_toast.dart';
import 'package:rido_syria_app/features/admin/view/admin_dashboard_screen.dart';
import 'package:rido_syria_app/features/auth/view/TermsandConditions.dart';
import 'package:rido_syria_app/features/auth/view/register.dart';
import 'package:rido_syria_app/features/auth/view/verify_account.dart';
import 'package:rido_syria_app/features/auth/view/forgot_password_screen.dart';
import 'package:rido_syria_app/features/driver/view/driver_home.dart';
import 'package:rido_syria_app/features/user/view/home.dart';

import '../../../core/ navigation/navigation.dart';
import '../../../core/network/local/cache_helper.dart';
import '../../../core/styles/themes.dart';
import '../../../core/widgets/CustomButton.dart' show CustomButton;
import '../../../core/widgets/constant.dart';
import '../../../core/widgets/custom_checkbox.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../driver/cubit/cubit.dart';
import '../../user/cubit/cubit.dart';
import '../cubit/cubit.dart';
import '../cubit/states.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  static GlobalKey<FormState> formKey = GlobalKey<FormState>();
  static TextEditingController userNameController = TextEditingController();
  static TextEditingController passwordController = TextEditingController();
  static bool isValidationPassed = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) => LoginCubit(),
      child: BlocConsumer<LoginCubit,LoginStates>(
        listener: (context,state){
          if (state is LoginNeedsVerificationState) {
            navigateTo(
              context,
              VerifyAccountScreen(phone: state.phone),
            );
          }

          if(state is LoginSuccessState){
            CacheHelper.saveData(
              key: 'token',
              value: LoginCubit.get(context).token,
            ).then((value) {
              CacheHelper.saveData(
                key: 'id',
                value: LoginCubit.get(context).id,
              ).then((value)  {
                CacheHelper.saveData(
                  key: 'role',
                  value: LoginCubit.get(context).role,
                ).then((value) async {
                  token = LoginCubit.get(context).token.toString();
                  id = LoginCubit.get(context).id.toString();
                  adminOrUser = LoginCubit.get(context).role.toString();
                  if (adminOrUser == 'admin')
                  {
                    LoginCubit.get(context).registerDevice(LoginCubit.get(context).id.toString());
                    navigateAndFinish(context, AdminDashboardScreen());
                  } else if (adminOrUser == 'driver')
                  {
                    LoginCubit.get(context).registerDevice(LoginCubit.get(context).id.toString());
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
                    } catch (e) {
                      if (context.mounted) Navigator.pop(context);
                      if (context.mounted) navigateAndFinish(context, DriverHome(cubit: driverCubit));
                    }
                  }
                  else {
                    LoginCubit.get(context).registerDevice(LoginCubit.get(context).id.toString());

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
                    } catch (e) {
                      if (context.mounted) Navigator.pop(context);
                      if (context.mounted) navigateAndFinish(context, Home(cubit: userCubit));
                    }
                  }

                });
              });
            });
          }
        },
          builder: (context,state){
          var cubit=LoginCubit.get(context);
          return Container(
            color: Colors.white,
            child: SafeArea(
              child: Scaffold(
                body: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
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
                            padding: const EdgeInsets.all(70.0),
                            child: Text(
                              nameApp,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 35,
                                fontWeight: FontWeight.bold,
                              ),
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
                                hintText: '9647712842105',
                                controller: userNameController,
                                keyboardType: TextInputType.phone,
                                suffixIcon:Icon(Iconsax.call),
                                validate: (String? value) {
                                  if (value!.isEmpty) {
                                    return 'رجائا اخل رقم الهاتف';
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                hintText: 'XXXXXXXXXX',
                                controller: passwordController,
                                obscureText: cubit.isPasswordHidden,
                                suffixIcon: GestureDetector(
                                  onTap: () {
                                    cubit.togglePasswordVisibility();
                                  },
                                  child: Icon(
                                    cubit.isPasswordHidden ? Iconsax.eye_slash : Iconsax.eye,
                                    color: Colors.black87,
                                  ),
                                ),
                                validate: (String? value) {
                                  if (value!.isEmpty) {
                                    return 'رجائا اخل الرمز السري';
                                  }
                                },
                              ),

                              const SizedBox(height: 26),
                              ConditionalBuilder(
                                condition: state is !LoginLoadingState,
                                  builder: (c){
                                    return  CustomButton(
                                      title: 'تسجيل الدخول',
                                      onPressed: () {
                                        if (formKey.currentState!.validate()) {
                                          cubit.signIn(
                                            phone: userNameController.text.trim(),
                                            password: passwordController.text.trim(),
                                            context: context,
                                          );
                                        }
                                      },
                                    );
                                  },
                                fallback: (c)=> CircularProgressIndicator(color: primaryColor,),
                              ),
                              const SizedBox(height: 21),
                              // Row(
                              //   mainAxisAlignment: MainAxisAlignment.center,
                              //   children: [
                              //     GestureDetector(
                              //       onTap: () {
                              //         navigateTo(context, Register());
                              //       },
                              //       child: const Text(
                              //         'انشاء حساب ',
                              //         style: TextStyle(
                              //           color: primaryColor,
                              //
                              //           fontWeight: FontWeight.bold,
                              //         ),
                              //       ),
                              //     ),
                              //     const Text("لا تمتلك حساب ؟ ",style: TextStyle(color: secondPrimaryTextColor, fontSize: 12,),),
                              //   ],
                              // ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      navigateTo(context, const ForgotPasswordScreen());
                                    },
                                    child: const Text(
                                      'نسيت كلمة السر؟',
                                      style: TextStyle(
                                        color: secondPrimaryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
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
