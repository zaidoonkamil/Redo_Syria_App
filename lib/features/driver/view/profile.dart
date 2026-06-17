import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rido_syria_app/core/widgets/CustomDialog.dart';
import 'package:rido_syria_app/core/widgets/circular_progress.dart';
import 'package:rido_syria_app/features/driver/view/Driver_Order.dart';

import '../../../core/ navigation/navigation.dart';
import '../../../core/network/remote/dio_helper.dart';
import '../../../core/styles/themes.dart';
import '../../../core/widgets/app_bar.dart';
import '../../../core/widgets/constant.dart';
import '../../../core/widgets/show_toast.dart';
import '../../auth/view/TermsandConditions.dart';
import '../../user/view/wallet_user.dart';
import '../cubit/cubit.dart';
import '../cubit/states.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'debts_driver.dart';


class ProfileDriver extends StatelessWidget {
  const ProfileDriver({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) =>
      DriverCubit()..getProfile(context: context),
      child: BlocConsumer<DriverCubit, DriverStates>(
        listener: (context, state) {},
        builder: (context, state) {
          final cubit = DriverCubit.get(context);

          return Container(
            color: Colors.white,
            child: SafeArea(
              child: Scaffold(
                body: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      CustomAppBarBack(),
                      const SizedBox(height: 15),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ConditionalBuilder(
                          condition: cubit.profileModel != null,
                          builder: (context) {
                            return userProfileCard(
                                name: cubit.profileModel!.name,
                                phone: cubit.profileModel!.phone,
                                image: '',
                                context: context);
                          },
                          fallback: (c) => UserProfileCardLoading(),
                        ),
                      ),
                      const SizedBox(height: 22),
                      _buildSettingsItem(
                        title: "طلباتي",
                        subtitle: "تفاصيل كل طلباتك",
                        icon: Iconsax.receipt,
                        onTap: () {
                          navigateTo(context, DriverOrder(driverId: id));
                        },
                      ),
                      SizedBox(height: 8,),
                      _buildSettingsItem(
                        title: "محفظتي",
                        subtitle: "رصيدك وحركات المحفظة",
                        icon: Iconsax.wallet_2,
                        onTap: () {
                          navigateTo(context, const WalletUserView());
                        },
                      ),
                      SizedBox(height: 8,),
                      _buildSettingsItem(
                        title: "ديوني",
                        subtitle: "تفاصيل ديونك",
                        icon: Iconsax.wallet_2,
                        onTap: () {
                          navigateTo(context, DebtsDriver
                            (isDebtBlocked: cubit.profileModel!.isDebtBlocked.toString(),
                              driverDebt: cubit.profileModel!.driverDebt,
                              name: cubit.profileModel!.name,
                              phone: cubit.profileModel!.phone,
                              status: cubit.profileModel!.status,
                              vehicleType: cubit.profileModel!.vehicleType,
                              vehicleColor: cubit.profileModel!.vehicleColor,
                              vehicleNumber: cubit.profileModel!.vehicleNumber,
                          ));
                        },
                      ),

                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 4,),
                          socialCircle(
                            icon: FontAwesomeIcons.facebookF,
                            onTap: () async{
                              final url =
                                  'https://www.facebook.com/share/1HKQkQDjuf/?mibextid=wwXIfr';
                              await launch(
                                url,
                                enableJavaScript: true,
                              ).catchError((e) {
                                showSnackBarError(
                                  text: e.toString(),
                                  context: context,
                                );
                              });
                            },
                          ),
                          SizedBox(width: 4,),
                          socialCircle(
                            icon: FontAwesomeIcons.tiktok,
                            onTap: () async{
                              final url =
                                  'https://www.tiktok.com/@wasslni.iq?_r=1&_t=ZS-92liOSKkfCh';
                              await launch(
                                url,
                                enableJavaScript: true,
                              ).catchError((e) {
                                showSnackBarError(
                                  text: e.toString(),
                                  context: context,
                                );
                              });
                            },
                          ),
                          SizedBox(width: 4,),
                          socialCircle(
                            icon: FontAwesomeIcons.instagram,
                            onTap: () async{
                              final url =
                                  'https://www.instagram.com/wasslni.iq?igsh=MWw1M3NzMHowcWZsdg==';
                              await launch(
                                url,
                                enableJavaScript: true,
                              ).catchError((e) {
                                showSnackBarError(
                                  text: e.toString(),
                                  context: context,
                                );
                              });
                            },
                          ),
                          SizedBox(width: 4,),
                          socialCircle(
                            icon: FontAwesomeIcons.linkedinIn,
                            onTap: () async{
                              final url =
                                  'https://www.linkedin.com/company/wasslni/';
                              await launch(
                                url,
                                enableJavaScript: true,
                              ).catchError((e) {
                                showSnackBarError(
                                  text: e.toString(),
                                  context: context,
                                );
                              });
                            },
                          ),
                          SizedBox(width: 4,),
                          socialCircle(
                            icon: Icons.info_outline_rounded,
                            onTap: () {
                              navigateTo(context, Termsandconditions());

                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                       logoutButton(
                         onPressed: () {
                           showDialog(
                             context: context,
                             builder: (_) => CustomConfirmDialog(
                               title: "هل حقاً ترغب في تسجيل الخروج؟",
                               cancelText: "إلغاء",
                               confirmText: "نعم",
                               onConfirm: () {
                                 Navigator.of(context).pop();
                                 signOut(context);
                               },
                             ),
                           );
                         },
                          title: "تسجيل الخروج",
                          icon: Icons.logout_rounded,
                          color: primaryColor,
                        ),

                      const SizedBox(height: 12),

                       logoutButton(
                        color: Colors.redAccent,
                        title: 'حذف الحساب',
                        icon: Icons.delete_outline_rounded,
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => CustomConfirmDialog(
                              title: "هل حقا ترغب في حذف الحساب ؟",
                              cancelText: "إلغاء",
                              confirmText: "نعم",
                              onConfirm: () {
                                cubit.deleteAccount(context: context);
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 60),
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

  Widget userProfileCard({
    required String name,
    required String phone,
    required String image,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.arrow_back_ios_new,color: primaryColor,),
          Spacer(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  phone,
                  style: TextStyle(
                    fontSize: 12,
                    color: primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: primaryColor.withOpacity(0.12),
              border: Border.all(
                color: primaryColor.withOpacity(0.30),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: (image.isEmpty)
                  ? Icon(
                Iconsax.profile_circle,
                size: 22,
                color: primaryColor.withOpacity(0.6),
              )
                  : Image.network(
                '$url/uploads/$image',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Iconsax.profile_circle,
                    size: 22,
                    color: primaryColor.withOpacity(0.6),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withOpacity(0.18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: primaryColor
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: primaryColor,
                    height: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primaryColor.withOpacity(0.22)),
              ),
              child: Icon(icon, color: primaryColor, size: 22),
            ),
          ],
        ),
      ),
    );
  }

  Widget logoutButton({
    required VoidCallback onPressed,
    Color color = primaryColor,
    String title = "تسجيل الخروج",
    IconData icon = Icons.logout_rounded,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),

        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color == Colors.redAccent ? Colors.redAccent : primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget socialCircle({required IconData icon, required VoidCallback onTap, Color? color, double size = 24,}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: secondPrimaryColor.withOpacity(0.12),
          border: Border.all(
            color: secondPrimaryColor.withOpacity(0.25),
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            color: secondPrimaryColor,
            size: size,
          ),
        ),
      ),
    );
  }

}
