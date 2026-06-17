import 'package:flutter/material.dart';
import 'package:rido_syria_app/features/admin/view/admin_dashboard_screen.dart';
import 'package:rido_syria_app/features/auth/view/login.dart';
import 'package:rido_syria_app/features/driver/cubit/cubit.dart';
import 'package:rido_syria_app/features/driver/view/driver_home.dart';

import '../../core/ navigation/navigation.dart';
import '../../core/network/local/cache_helper.dart';
import '../../core/styles/themes.dart';
import '../../core/widgets/constant.dart';
import '../user/cubit/cubit.dart';
import '../user/view/home.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  
  @override
  void initState() {
    super.initState();
    _boot();

  }

  Future<void> _boot() async {
    await Future.delayed(const Duration(seconds: 2));

    if (CacheHelper.getData(key: 'token') == null) {
      token = '';
      if (!mounted) return;
      navigateAndFinish(context, Login());
      return;
    }
    adminOrUser = CacheHelper.getData(key: 'role');
    token = CacheHelper.getData(key: 'token');
    id = CacheHelper.getData(key: 'id') ?? '';

    if (adminOrUser == 'admin') {
      if (!mounted) return;
      navigateAndFinish(context, AdminDashboardScreen());
      return;
    }else if (adminOrUser == 'driver') {
      final driverCubit = DriverCubit();
      try {
        await driverCubit.init();
        if (!mounted) return;
        navigateAndFinish(context, DriverHome(cubit: driverCubit));
      } catch (e) {
        if (!mounted) return;
        navigateAndFinish(context, DriverHome(cubit: driverCubit));
      }
      return;
    }else{
      final userCubit = UserCubit();
      try {
        await userCubit.init();
        if (!mounted) return;
        navigateAndFinish(context, Home(cubit: userCubit));
      } catch (e) {
        if (!mounted) return;
        navigateAndFinish(context, Home(cubit: userCubit));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(flex: 2,),
              Center(child: Container(
                padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.black87
                  ),
                  child: Image.asset('assets/images/$logo',width: 120,)),),
              Spacer(flex: 1,),
              CircularProgressIndicator(color: secondPrimaryColor),
              Spacer(flex: 1,),
            ],
          ),
        ),
      ),
    );
  }
}