import 'package:dio/dio.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rido_syria_app/core/network/remote/dio_helper.dart';

import 'package:rido_syria_app/features/admin/cubit/states.dart';
import 'package:rido_syria_app/features/admin/model/GetAdminOnlyModel.dart';
import 'package:rido_syria_app/features/admin/model/GetDriverOnlyModel.dart';
import 'package:rido_syria_app/features/admin/cubit/states.dart';

import '../../../core/widgets/constant.dart';
import '../../../core/widgets/show_toast.dart';
import '../model/AdminDebtSettingsModel.dart';
import '../model/AdminPricingModel.dart';
import '../model/AdminPricingTiersModel.dart';
import '../model/GetUsersOnlyModel.dart';

class AppCubitAdmin extends Cubit<AppStatesAdmin> {
  AppCubitAdmin() : super(AppInitialStateAdmin());

  static AppCubitAdmin get(BuildContext context) =>
      BlocProvider.of<AppCubitAdmin>(context);

  String pricingServiceType = 'normal';

  Map<String, dynamic>? statsOverview;
  Map<String, dynamic>? usersOverview;
  List<Map<String, dynamic>> ridesSeries = [];
  List<Map<String, dynamic>> usersSeries = [];
  List<Map<String, dynamic>> driversSeries = [];

  Future<void> loadDashboardStats() async {
    emit(AdminStatsLoadingState());
    try {
      final res1 = await DioHelper.getData(
        url: "/admin/stats/overview",
        token: token,
      );

      final res2 = await DioHelper.getData(
        url: "/admin/stats/users/overview",
        token: token,
      );

      final rRides = await DioHelper.getData(
        url: "/admin/stats/timeseries",
        query: {"type": "rides", "group": "day"},
        token: token,
      );

      final rUsers = await DioHelper.getData(
        url: "/admin/stats/timeseries",
        query: {"type": "users", "group": "day"},
        token: token,
      );

      final rDrivers = await DioHelper.getData(
        url: "/admin/stats/timeseries",
        query: {"type": "drivers", "group": "day"},
        token: token,
      );

      statsOverview = Map<String, dynamic>.from(res1.data);
      usersOverview = Map<String, dynamic>.from(res2.data);

      // data: [{date: '2026-01-01', count: 5}, ...]
      ridesSeries = List<Map<String, dynamic>>.from(rRides.data ?? []);
      usersSeries = List<Map<String, dynamic>>.from(rUsers.data ?? []);
      driversSeries = List<Map<String, dynamic>>.from(rDrivers.data ?? []);

      emit(AdminStatsSuccessState());
    } catch (e) {
      String msg = e.toString();
      if (e is DioException) {
        msg = e.response?.data?["error"]?.toString() ?? e.message ?? msg;
      }
      emit(AdminStatsErrorState(msg));
    }
  }

  Future<void> sendNotification({
    required String title,
    required String message,
    String? role,
    String? userId,
  }) async {
    emit(AdminSendNotificationLoadingState());
    try {
      final Map<String, dynamic> data = {"title": title, "message": message};

      if (userId != null && userId.isNotEmpty) {
        data["target_type"] = "user";
        data["target_value"] = userId;
      } else if (role != null && role.isNotEmpty) {
        data["target_type"] = "role";
        data["target_value"] = role;
      } else {
        data["target_type"] = "all";
      }

      final response = await DioHelper.postData(
        url: "/notification",
        data: data,
        token: token,
      );

      if (response.statusCode == 200) {
        emit(AdminSendNotificationSuccessState());
      } else {
        emit(AdminSendNotificationErrorState());
      }
    } catch (e) {
      print("Send Notification Error: $e");
      emit(AdminSendNotificationErrorState());
    }
  }

  GetUsersOnlyModel? getUsersOnlyModel;
  void getUsersOnly({required BuildContext context, required String page}) {
    emit(GetUsersOnlyLoadingState());
    DioHelper.getData(url: '/usersOnly?page=$page')
        .then((value) {
          getUsersOnlyModel = GetUsersOnlyModel.fromJson(value.data);
          emit(GetUsersOnlySuccessState());
        })
        .catchError((error) {
          if (error is DioError) {
            showSnackBarError(text: error.toString(), context: context);
            print(error.toString());
            emit(GetUsersOnlyErrorState());
          } else {
            print("Unknown Error: $error");
          }
        });
  }

  void updateStatusOfUser({
    required BuildContext context,
    required String id,
    required String status,
  }) {
    emit(UpdateStatusOfUserLoadingState());
    DioHelper.patchData(
          url: '/users/$id/status',
          token: token,
          data: {'status': status},
        )
        .then((value) {
          final model = getUsersOnlyModel;
          if (model != null) {
            final int userId = int.tryParse(id) ?? -1;
            final index = model.users.indexWhere((u) => u.id == userId);
            if (index != -1) {
              model.users[index].status = status;
            }
          }

          emit(UpdateStatusOfUserSuccessState());
          emit(GetUsersOnlySuccessState());
        })
        .catchError((error) {
          if (error is DioError) {
            showSnackBarError(text: error.toString(), context: context);
            print(error.toString());
            emit(UpdateStatusOfUserErrorState());
          } else {
            print("Unknown Error: $error");
          }
        });
  }

  void deleteUser({required BuildContext context, required String id}) {
    emit(DeleteLoadingState());
    DioHelper.deleteData(url: '/users/$id')
        .then((value) {
          final int targetId = int.tryParse(id) ?? -1;
          if (getUsersOnlyModel != null) {
            getUsersOnlyModel!.users.removeWhere((u) => u.id == targetId);
          }
          if (getDriverOnlyModel != null) {
            getDriverOnlyModel!.drivers.removeWhere((d) => d.id == targetId);
          }
          if (getAdminOnlyModel != null) {
            getAdminOnlyModel!.users.removeWhere((a) => a.id == targetId);
          }

          emit(DeleteSuccessState());
          emit(GetUsersOnlySuccessState());
          emit(GetDriverOnlySuccessState());
        })
        .catchError((error) {
          if (error is DioError) {
            showSnackBarError(text: error.toString(), context: context);
            print(error.toString());
            emit(DeleteErrorState());
          } else {
            print("Unknown Error: $error");
          }
        });
  }

  GetAdminOnlyModel? getAdminOnlyModel;
  void getAdminsOnly({required BuildContext context, required String page}) {
    emit(GetUsersOnlyLoadingState());
    DioHelper.getData(url: '/adminOnly?page=$page')
        .then((value) {
          getAdminOnlyModel = GetAdminOnlyModel.fromJson(value.data);
          emit(GetUsersOnlySuccessState());
        })
        .catchError((error) {
          if (error is DioError) {
            showSnackBarError(text: error.toString(), context: context);
            print(error.toString());
            emit(GetUsersOnlyErrorState());
          } else {
            print("Unknown Error: $error");
          }
        });
  }

  GetDriverOnlyModel? getDriverOnlyModel;
  void getDriverOnly({required BuildContext context, required String page}) {
    emit(GetDriverOnlyLoadingState());
    DioHelper.getData(url: '/driversOnly?page=$page')
        .then((value) {
          getDriverOnlyModel = GetDriverOnlyModel.fromJson(value.data);
          emit(GetDriverOnlySuccessState());
        })
        .catchError((error) {
          if (error is DioError) {
            showSnackBarError(text: error.toString(), context: context);
            print(error.toString());
            emit(GetDriverOnlyErrorState());
          } else {
            print("Unknown Error: $error");
          }
        });
  }

  AdminPricingModel? adminPricingModel;
  AdminPricingTiersModel? adminPricingTiersModel;

  Future<void> getAdminPricing({
    required BuildContext context,
    String serviceType = 'normal',
  }) async {
    pricingServiceType = serviceType;
    emit(AdminPricingLoadingState());
    adminPricingModel = null;
    adminPricingTiersModel = null;

    try {
      final responses = await Future.wait([
        DioHelper.getData(
          url: '/admin/pricing',
          query: {'serviceType': serviceType},
          token: token,
        ),
        DioHelper.getData(
          url: '/admin/pricing/tiers',
          query: {'serviceType': serviceType},
          token: token,
        ),
      ]);

      adminPricingModel = AdminPricingModel.fromJson(responses[0].data);
      adminPricingTiersModel = AdminPricingTiersModel.fromJson(
        responses[1].data,
      );
      emit(AdminPricingSuccessState());
    } catch (error) {
      final message = _extractErrorMessage(error);
      showSnackBarError(text: message, context: context);
      print(message);
      emit(AdminPricingErrorState());
    }
  }

  Future<void> changeAdminPricingServiceType({
    required BuildContext context,
    required String serviceType,
  }) async {
    if (pricingServiceType == serviceType &&
        adminPricingModel != null &&
        adminPricingTiersModel != null) {
      return;
    }
    await getAdminPricing(context: context, serviceType: serviceType);
  }

  String? get pricePerKmValue {
    return adminPricingModel?.pricing?.pricePerKm?.toString();
  }

  String? get baseFareValue {
    return adminPricingModel?.pricing?.baseFare?.toString();
  }

  String? get pricePerMinuteValue {
    return adminPricingModel?.pricing?.pricePerMinute?.toString();
  }

  String? get minimumFareValue {
    return adminPricingModel?.pricing?.minimumFare?.toString();
  }

  bool get surgeEnabledValue {
    return adminPricingModel?.pricing?.surgeEnabled == true;
  }

  String? get surgeMultiplierValue {
    return adminPricingModel?.pricing?.surgeMultiplier?.toString();
  }

  List<PricingTierItem> get pricingTiers {
    return adminPricingTiersModel?.tiers ?? const [];
  }

  Future<void> updateAdminPricingAndReload({
    required BuildContext context,
    required String serviceType,
    required String baseFare,
    required String pricePerKm,
    required String pricePerMinute,
    required String minimumFare,
    required bool surgeEnabled,
    required String surgeMultiplier,
  }) async {
    final updated = await updateAdminPricing(
      context: context,
      serviceType: serviceType,
      baseFare: baseFare,
      pricePerKm: pricePerKm,
      pricePerMinute: pricePerMinute,
      minimumFare: minimumFare,
      surgeEnabled: surgeEnabled,
      surgeMultiplier: surgeMultiplier,
    );

    if (!updated) {
      return;
    }

    await Future.delayed(const Duration(milliseconds: 150));
    await getAdminPricing(context: context, serviceType: serviceType);
  }

  Future<bool> updateAdminPricing({
    required BuildContext context,
    required String serviceType,
    required String baseFare,
    required String pricePerKm,
    required String pricePerMinute,
    required String minimumFare,
    required bool surgeEnabled,
    required String surgeMultiplier,
  }) async {
    emit(UpdateAdminPricingLoadingState());
    try {
      await DioHelper.putData(
        url: '/admin/pricing',
        token: token,
        data: {
          "serviceType": serviceType,
          "baseFare": baseFare,
          "pricePerKm": pricePerKm,
          "pricePerMinute": pricePerMinute,
          "minimumFare": minimumFare,
          "surgeEnabled": surgeEnabled,
          "surgeMultiplier": surgeMultiplier,
        },
      );
      emit(UpdateAdminPricingSuccessState());
      return true;
    } catch (error) {
      final message = _extractErrorMessage(error);
      showSnackBarError(text: message, context: context);
      print(message);
      emit(UpdateAdminPricingErrorState());
      return false;
    }
  }

  Future<void> updateAdminPricingTiersAndReload({
    required BuildContext context,
    required String serviceType,
    required List<Map<String, dynamic>> tiers,
  }) async {
    final updated = await updateAdminPricingTiers(
      context: context,
      serviceType: serviceType,
      tiers: tiers,
    );

    if (!updated) {
      return;
    }

    await Future.delayed(const Duration(milliseconds: 150));
    await getAdminPricing(context: context, serviceType: serviceType);
  }

  Future<bool> updateAdminPricingTiers({
    required BuildContext context,
    required String serviceType,
    required List<Map<String, dynamic>> tiers,
  }) async {
    emit(UpdateAdminPricingTiersLoadingState());
    try {
      await DioHelper.putData(
        url: '/admin/pricing/tiers',
        token: token,
        data: {'serviceType': serviceType, 'tiers': tiers},
      );
      emit(UpdateAdminPricingTiersSuccessState());
      return true;
    } catch (error) {
      final message = _extractErrorMessage(error);
      showSnackBarError(text: message, context: context);
      print(message);
      emit(UpdateAdminPricingTiersErrorState());
      return false;
    }
  }

  String? get debtLimitValue {
    return adminDebtSettingsModel?.limit?.toString();
  }

  String? get commissionValue {
    return adminDebtSettingsModel?.commissionValue?.toString();
  }

  String? get commissionTypeValue {
    return adminDebtSettingsModel?.commissionType?.toString();
  }

  AdminDebtSettingsModel? adminDebtSettingsModel;
  void getAdminDebtSettings({required BuildContext context}) {
    emit(AdminDebtSettingsLoadingState());
    DioHelper.getData(url: '/admin/debt/settings', token: token)
        .then((value) {
          adminDebtSettingsModel = AdminDebtSettingsModel.fromJson(value.data);
          emit(AdminDebtSettingsSuccessState());
        })
        .catchError((error) {
          if (error is DioError) {
            showSnackBarError(text: error.toString(), context: context);
            print(error.toString());
            emit(AdminDebtSettingsErrorState());
          } else {
            print("Unknown Error: $error");
          }
        });
  }

  Future<void> updateAdminDebtSettings({
    required BuildContext context,
    required String driverDebtLimit,
    required String driverCommissionValue,
    String commissionType = "percent",
  }) async {
    emit(UpdateAdminDebtSettingsLoadingState());
    try {
      await DioHelper.putData(
        url: '/admin/debt/settings',
        token: token,
        data: {
          "DRIVER_DEBT_LIMIT": driverDebtLimit,
          "DRIVER_COMMISSION_TYPE": commissionType,
          "DRIVER_COMMISSION_VALUE": driverCommissionValue,
        },
      );
      emit(UpdateAdminDebtSettingsSuccessState());
    } catch (error) {
      showSnackBarError(text: error.toString(), context: context);
      emit(UpdateAdminDebtSettingsErrorState());
    }
  }

  Future<void> updateAdminDebtSettingsAndReload({
    required BuildContext context,
    required String driverDebtLimit,
    required String driverCommissionValue,
    String commissionType = "percent",
  }) async {
    await updateAdminDebtSettings(
      context: context,
      driverDebtLimit: driverDebtLimit,
      driverCommissionValue: driverCommissionValue,
      commissionType: commissionType,
    );
    await Future.delayed(const Duration(milliseconds: 50));
    getAdminDebtSettings(context: context);
  }

  Future<void> payDriverDebt({
    required BuildContext context,
    required String driverId,
    required String amount,
    String? note,
  }) async {
    emit(AdminPayDebtLoadingState());

    try {
      await DioHelper.postData(
        url: '/admin/drivers/$driverId/debt/pay',
        token: token,
        data: {"amount": amount, "note": note ?? "admin payment"},
      );

      emit(AdminPayDebtSuccessState());

      // (اختياري) حدّث القائمة محلياً حتى يبان مباشرة
      final model = getDriverOnlyModel;
      if (model != null) {
        final id = int.tryParse(driverId) ?? -1;
        final idx = model.drivers.indexWhere((d) => d.id == id);
        if (idx != -1) {
          final current = double.tryParse(model.drivers[idx].driverDebt) ?? 0;
          final paid = double.tryParse(amount) ?? 0;
          final next = (current - paid);
          model.drivers[idx].driverDebt = (next < 0 ? 0 : next).toString();
          model.drivers[idx].isDebtBlocked =
              false; // لأن الراوت يسوي unblock اذا نزل عن الحد
        }
      }

      // حتى يرجع يرسم
      emit(GetDriverOnlySuccessState());
    } catch (e) {
      showSnackBarError(text: e.toString(), context: context);
      emit(AdminPayDebtErrorState());
    }
  }

  String driversQuery = "";

  void searchDriversOnly({
    required BuildContext context,
    required String q,
    required String page,
  }) {
    driversQuery = q;
    emit(GetDriverOnlyLoadingState());

    DioHelper.getData(
          url: '/driversOnly/search',
          query: {"q": q, "page": page, "limit": 30},
        )
        .then((value) {
          getDriverOnlyModel = GetDriverOnlyModel.fromJson(value.data);
          emit(GetDriverOnlySuccessState());
        })
        .catchError((error) {
          if (error is DioError) {
            showSnackBarError(text: error.toString(), context: context);
            emit(GetDriverOnlyErrorState());
          } else {
            print("Unknown Error: $error");
            emit(GetDriverOnlyErrorState());
          }
        });
  }

  Map<String, dynamic>? whatsAppStatus;
  String? whatsAppQrImage;

  String normalizePhone(String phone) {
    phone = phone.trim();

    if (phone.startsWith('964') && phone.length == 13) {
      return phone;
    } else if (phone.startsWith('0') && phone.length == 11) {
      return '964${phone.substring(1)}';
    } else if (phone.length == 10) {
      return '964$phone';
    } else {
      return phone;
    }
  }

  void getWhatsAppStatus({required BuildContext context}) {
    emit(WhatsAppLoadingState());
    DioHelper.getData(url: '/whatsapp/status', token: token)
        .then((value) {
          whatsAppStatus = Map<String, dynamic>.from(value.data);
          emit(WhatsAppStatusSuccessState());
        })
        .catchError((error) {
          if (!context.mounted) {
            emit(WhatsAppErrorState());
            return;
          }
          showSnackBarError(
            text: _extractErrorMessage(error),
            context: context,
          );
          emit(WhatsAppErrorState());
        });
  }

  void initWhatsApp({required BuildContext context}) {
    emit(WhatsAppLoadingState());
    DioHelper.postData(url: '/whatsapp/init', token: token, data: {})
        .then((value) {
          whatsAppStatus = Map<String, dynamic>.from(value.data);
          emit(WhatsAppInitSuccessState());
        })
        .catchError((error) {
          if (!context.mounted) {
            emit(WhatsAppErrorState());
            return;
          }
          showSnackBarError(
            text: _extractErrorMessage(error),
            context: context,
          );
          emit(WhatsAppErrorState());
        });
  }

  void getWhatsAppQr({required BuildContext context}) {
    emit(WhatsAppLoadingState());
    DioHelper.getData(url: '/whatsapp/qr', token: token)
        .then((value) {
          whatsAppQrImage = value.data['qrImage']?.toString();
          whatsAppStatus ??= {};
          whatsAppStatus!.addAll(Map<String, dynamic>.from(value.data));
          emit(WhatsAppQrSuccessState());
        })
        .catchError((error) {
          if (!context.mounted) {
            emit(WhatsAppErrorState());
            return;
          }
          showSnackBarError(
            text: _extractErrorMessage(error),
            context: context,
          );
          emit(WhatsAppErrorState());
        });
  }

  void logoutWhatsApp({required BuildContext context}) {
    emit(WhatsAppLoadingState());
    DioHelper.postData(url: '/whatsapp/logout', token: token, data: {})
        .then((value) {
          whatsAppStatus = Map<String, dynamic>.from(value.data);
          whatsAppQrImage = null;
          emit(WhatsAppLogoutSuccessState());
        })
        .catchError((error) {
          if (!context.mounted) {
            emit(WhatsAppErrorState());
            return;
          }
          showSnackBarError(
            text: _extractErrorMessage(error),
            context: context,
          );
          emit(WhatsAppErrorState());
        });
  }

  void sendWhatsAppTest({
    required BuildContext context,
    required String phone,
    required String message,
  }) {
    emit(WhatsAppLoadingState());
    DioHelper.postData(
          url: '/whatsapp/send',
          token: token,
          data: {'phone': normalizePhone(phone), 'message': message},
        )
        .then((value) {
          if (!context.mounted) {
            emit(WhatsAppSendSuccessState());
            return;
          }
          showSnackBarSuccess(
            text: 'تم إرسال الرسالة التجريبية',
            context: context,
          );
          emit(WhatsAppSendSuccessState());
        })
        .catchError((error) {
          if (!context.mounted) {
            emit(WhatsAppErrorState());
            return;
          }
          showSnackBarError(
            text: _extractErrorMessage(error),
            context: context,
          );
          emit(WhatsAppErrorState());
        });
  }

  String _extractErrorMessage(Object error) {
    if (error is DioException) {
      final path = error.requestOptions.path;
      if (error.response?.statusCode == 404 && path.startsWith('/whatsapp')) {
        return 'راوتات واتساب غير موجودة على السيرفر الحالي. حدث الباك إند أو شغل التطبيق على رابط الباك المحلي الجديد.';
      }

      final responseData = error.response?.data;
      if (responseData is Map) {
        final message = responseData['message'] ?? responseData['error'];
        if (message != null && message.toString().trim().isNotEmpty) {
          return message.toString();
        }
      }
      return error.message ?? error.toString();
    }

    if (error is DioError) {
      final responseData = error.response?.data;
      if (responseData is Map) {
        final message = responseData['message'] ?? responseData['error'];
        if (message != null && message.toString().trim().isNotEmpty) {
          return message.toString();
        }
      }
    }

    return error.toString();
  }
}
