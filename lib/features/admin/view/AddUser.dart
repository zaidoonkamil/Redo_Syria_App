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


class AddUser extends StatelessWidget {
  const AddUser({super.key});

  static final GlobalKey<FormState> userFormKey = GlobalKey<FormState>();
  static final GlobalKey<FormState> driverFormKey = GlobalKey<FormState>();

  static final TextEditingController userNameController = TextEditingController();
  static final TextEditingController userPhoneController = TextEditingController();
  static final TextEditingController userLocationController = TextEditingController();
  static final TextEditingController userPasswordController = TextEditingController();
  static final TextEditingController userRePasswordController = TextEditingController();

  static final TextEditingController driverNameController = TextEditingController();
  static final TextEditingController driverPhoneController = TextEditingController();
  static final TextEditingController driverLocationController = TextEditingController();
  static final TextEditingController driverPasswordController = TextEditingController();
  static final TextEditingController driverRePasswordController = TextEditingController();

  static final TextEditingController vehicleTypeController = TextEditingController();
  static final TextEditingController vehicleColorController = TextEditingController();
  static final TextEditingController vehicleNumberController = TextEditingController();

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

            driverNameController.clear();
            driverPhoneController.clear();
            driverLocationController.clear();
            driverPasswordController.clear();
            driverRePasswordController.clear();
            vehicleTypeController.clear();
            vehicleColorController.clear();
            vehicleNumberController.clear();
            LoginCubit.get(context).selectedImagesDriverImage.clear();
            LoginCubit.get(context).selectedImagesCarImages.clear();
            LoginCubit.get(context).selectedImagesDrivingLicenseFront.clear();
            LoginCubit.get(context).selectedImagesDrivingLicenseBack.clear();

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
                    child: _UserAddUserForm(
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


class _UserAddUserForm extends StatelessWidget {
  final LoginCubit cubit;
  final LoginStates state;

  const _UserAddUserForm({required this.cubit, required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Form(
          key: AddUser.userFormKey,
          child: Column(
            children: [
              const SizedBox(height: 22),
              CustomTextField(
                hintText: 'الاسم الثلاثي',
                prefixIcon: Iconsax.user,
                suffixIcon: const Icon(Iconsax.user),
                controller: AddUser.userNameController,
                validate: (v) => (v == null || v.isEmpty) ? 'رجائاً ادخل الاسم الثلاثي' : null,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: AddUser.userPhoneController,
                hintText: 'رقم الهاتف',
                prefixIcon: Iconsax.call,
                suffixIcon: const Icon(Iconsax.call),
                keyboardType: TextInputType.phone,
                validate: (v) => (v == null || v.isEmpty) ? 'رجائاً ادخل رقم الهاتف' : null,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: AddUser.userPasswordController,
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
                controller: AddUser.userRePasswordController,
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
                  title: 'انشاء حساب مستخدم',
                  onPressed: () {
                    if (AddUser.userFormKey.currentState!.validate()) {
                      if (AddUser.userPasswordController.text == AddUser.userRePasswordController.text) {
                        cubit.signUp(
                          name: AddUser.userNameController.text.trim(),
                          phone: AddUser.userPhoneController.text.trim(),
                          password: AddUser.userPasswordController.text.trim(),
                          role: 'user',
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

class _DriverAddUserForm extends StatelessWidget {
  final LoginCubit cubit;
  final LoginStates state;

  const _DriverAddUserForm({required this.cubit, required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Form(
          key: AddUser.driverFormKey,
          child: Column(
            children: [
              const SizedBox(height: 12),
              CustomTextField(
                hintText: 'الاسم الثلاثي',
                prefixIcon: Iconsax.user,
                suffixIcon: const Icon(Iconsax.user),
                controller: AddUser.driverNameController,
                validate: (v) => (v == null || v.isEmpty) ? 'رجائاً ادخل الاسم الثلاثي' : null,
              ),
              const SizedBox(height: 10),

              CustomTextField(
                controller: AddUser.driverPhoneController,
                hintText: 'رقم الهاتف',
                prefixIcon: Iconsax.call,
                suffixIcon: const Icon(Iconsax.call),
                keyboardType: TextInputType.phone,
                validate: (v) => (v == null || v.isEmpty) ? 'رجائاً ادخل رقم الهاتف' : null,
              ),
              const SizedBox(height: 10),

              CustomTextField(
                controller: AddUser.driverLocationController,
                hintText: 'موقع السائق',
                prefixIcon: Iconsax.location,
                suffixIcon: const Icon(Iconsax.location),
                validate: (v) => (v == null || v.isEmpty) ? 'رجائاً ادخل الموقع' : null,
              ),
              const SizedBox(height: 10),
              CustomTextField(
                controller: AddUser.vehicleTypeController,
                hintText: 'نوع المركبة (مثلاً: تويوتا)',
                prefixIcon: Iconsax.car,
                suffixIcon: const Icon(Iconsax.car),
                validate: (v) => (v == null || v.isEmpty) ? 'رجائاً ادخل نوع المركبة' : null,
              ),
              const SizedBox(height: 10),

              CustomTextField(
                controller: AddUser.vehicleColorController,
                hintText: 'لون المركبة',
                prefixIcon: Iconsax.color_swatch,
                suffixIcon: const Icon(Iconsax.color_swatch),
                validate: (v) => (v == null || v.isEmpty) ? 'رجائاً ادخل لون المركبة' : null,
              ),
              const SizedBox(height: 10),

              CustomTextField(
                controller: AddUser.vehicleNumberController,
                hintText: 'رقم المركبة',
                prefixIcon: Iconsax.hashtag,
                suffixIcon: const Icon(Iconsax.hashtag),
                validate: (v) => (v == null || v.isEmpty) ? 'رجائاً ادخل رقم المركبة' : null,
              ),

              const SizedBox(height: 10),

              _UploadHintCard(
                title: "صورة السائق",
                onTap: cubit.pickImagesImagesDriverImage,
                count: cubit.selectedImagesDriverImage.length,
              ),
              const SizedBox(height: 8),

              _UploadHintCard(
                title: "صور السيارة",
                onTap: cubit.pickImagesImagesCarImages,
                count: cubit.selectedImagesCarImages.length,
              ),
              const SizedBox(height: 8),

              _UploadHintCard(
                title: "اجازة القيادة (الوجه الأمامي)",
                onTap: cubit.pickImagesDrivingLicenseFront,
                count: cubit.selectedImagesDrivingLicenseFront.length,
              ),
              const SizedBox(height: 8),

              _UploadHintCard(
                title: "اجازة القيادة (الوجه الخلفي)",
                onTap: cubit.pickImagesDrivingLicenseBack,
                count: cubit.selectedImagesDrivingLicenseBack.length,
              ),


              const SizedBox(height: 10),

              CustomTextField(
                controller: AddUser.driverPasswordController,
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
              const SizedBox(height: 10),

              CustomTextField(
                controller: AddUser.driverRePasswordController,
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

              const SizedBox(height: 22),

              ConditionalBuilder(
                condition: state is! SignUpLoadingState,
                builder: (_) => CustomButton(
                  title: 'انشاء حساب سائق',
                  onPressed: () {
                    if (AddUser.driverFormKey.currentState!.validate()) {
                      if (AddUser.driverPasswordController.text != AddUser.driverRePasswordController.text) {
                        showSnackBarError(text: "كلمة السر غير متطابقة", context: context);
                        return;
                      }

                      cubit.signUpDriver(
                        name: AddUser.driverNameController.text.trim(),
                        phone: AddUser.driverPhoneController.text.trim(),
                        location: AddUser.driverLocationController.text.trim(),
                        password: AddUser.driverPasswordController.text.trim(),
                        context: context,
                        vehicleType: AddUser.vehicleTypeController.text.trim(),
                        vehicleColor: AddUser.vehicleColorController.text.trim(),
                        vehicleNumber: AddUser.vehicleNumberController.text.trim(),
                      );
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

class _UploadHintCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final int count;

  const _UploadHintCard({
    required this.title,
    required this.onTap,
    this.count = 0,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasFiles = count > 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasFiles ? primaryColor.withOpacity(0.35) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            const Icon(FontAwesomeIcons.chevronLeft, color: secondPrimaryTextColor, size: 14),

            const SizedBox(width: 10),

            if (hasFiles)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  "$count",
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const Spacer(),

            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: secondPrimaryTextColor,
                fontWeight: hasFiles ? FontWeight.w700 : FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),

            const SizedBox(width: 10),

            Icon(
              FontAwesomeIcons.cloudArrowUp,
              color: hasFiles ? primaryColor : primaryColor.withOpacity(0.6),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
