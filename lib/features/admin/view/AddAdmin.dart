import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rido_syria_app/core/widgets/app_bar.dart';
import 'package:rido_syria_app/features/auth/cubit/cubit.dart';
import 'package:rido_syria_app/features/auth/cubit/states.dart';

import '../../../core/styles/themes.dart';
import '../../../core/widgets/CustomButton.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/show_toast.dart';


class AddAdmin extends StatelessWidget {
  const AddAdmin({super.key});

  static final GlobalKey<FormState> userFormKey = GlobalKey<FormState>();

  static final TextEditingController userNameController = TextEditingController();
  static final TextEditingController userPhoneController = TextEditingController();
  static final TextEditingController userLocationController = TextEditingController();
  static final TextEditingController userPasswordController = TextEditingController();
  static final TextEditingController userRePasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) => LoginCubit(),
      child: BlocConsumer<LoginCubit, LoginStates>(
        listener: (context, state) {
          if (state is SignUpSuccessState) {
            userNameController.clear();
            userPhoneController.clear();
            userLocationController.clear();
            userPasswordController.clear();
            userRePasswordController.clear();
            showSnackBarSuccess(text: "تم انشاء الحساب بنجاح", context: context);
          }
        },
        builder: (context, state) {
          var cubit = LoginCubit.get(context);

          return SafeArea(
            child: Scaffold(
              body: Column(
                children: [
                  CustomAppBarBack(),
                  const SizedBox(height: 14),
                  const SizedBox(height: 14),
                  Expanded(
                    child: _UserAddAdminForm(
                      cubit: cubit,
                      state: state,
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


class _UserAddAdminForm extends StatelessWidget {
  final LoginCubit cubit;
  final LoginStates state;

  const _UserAddAdminForm({required this.cubit, required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Form(
          key: AddAdmin.userFormKey,
          child: Column(
            children: [
              const SizedBox(height: 22),
              CustomTextField(
                hintText: 'الاسم الثلاثي',
                prefixIcon: Iconsax.user,
                suffixIcon: const Icon(Iconsax.user),
                controller: AddAdmin.userNameController,
                validate: (v) => (v == null || v.isEmpty) ? 'رجائاً ادخل الاسم الثلاثي' : null,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: AddAdmin.userPhoneController,
                hintText: 'رقم الهاتف',
                prefixIcon: Iconsax.call,
                suffixIcon: const Icon(Iconsax.call),
                keyboardType: TextInputType.phone,
                validate: (v) => (v == null || v.isEmpty) ? 'رجائاً ادخل رقم الهاتف' : null,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: AddAdmin.userPasswordController,
                hintText: 'كلمة السر',
                prefixIcon: Iconsax.lock,
                obscureText: cubit.isPasswordHidden,
                suffixIcon: GestureDetector(
                  onTap: cubit.togglePasswordVisibility,
                  child: Icon(
                    cubit.isPasswordHidden ? Iconsax.eye_slash : Iconsax.eye,
                    color: Colors.black87,
                  ),
                ),
                validate: (v) => (v == null || v.isEmpty) ? 'رجائاً ادخل كلمة السر' : null,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: AddAdmin.userRePasswordController,
                hintText: 'اعد كتابة كلمة السر',
                prefixIcon: Iconsax.lock,
                obscureText: cubit.isPasswordHidden2,
                suffixIcon: GestureDetector(
                  onTap: cubit.togglePasswordVisibility2,
                  child: Icon(
                    cubit.isPasswordHidden2 ? Iconsax.eye_slash : Iconsax.eye,
                    color: Colors.black87,
                  ),
                ),
                validate: (v) => (v == null || v.isEmpty) ? 'رجائاً اعد ادخال كلمة السر' : null,
              ),

              const SizedBox(height: 26),

              ConditionalBuilder(
                condition: state is! SignUpLoadingState,
                builder: (_) => CustomButton(
                  title: 'انشاء حساب ادمن',
                  onPressed: () {
                    if (AddAdmin.userFormKey.currentState!.validate()) {
                      if (AddAdmin.userPasswordController.text == AddAdmin.userRePasswordController.text) {
                        cubit.signUp(
                          name: AddAdmin.userNameController.text.trim(),
                          phone: AddAdmin.userPhoneController.text.trim(),
                          password: AddAdmin.userPasswordController.text.trim(),
                          role: 'admin',
                          context: context,
                        );
                      } else {
                        showSnackBarError(text: "كلمة السر غير متطابقة", context: context);
                      }
                    }
                  },
                ),
                fallback: (_) => const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(color: primaryColor),
                ),
              ),

              const SizedBox(height: 22),
            ],
          ),
        ),
      ),
    );
  }
}