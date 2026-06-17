import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:image_picker/image_picker.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:rido_syria_app/features/auth/cubit/states.dart';

import '../../../core/network/remote/dio_helper.dart';
import '../../../core/widgets/show_toast.dart';

class LoginCubit extends Cubit<LoginStates> {
  LoginCubit() : super(LoginInitialState());

  static LoginCubit get(context) => BlocProvider.of(context);

  bool agreeTerms = false;

  void toggleAgreeTerms(bool? value) {
    agreeTerms = value ?? false;
    emit(ValidationState());
  }

  void validation(){
    emit(ValidationState());
  }

  bool isPasswordHidden = true;
  void togglePasswordVisibility() {
    isPasswordHidden = !isPasswordHidden;
    emit(PasswordVisibilityChanged());
  }

  bool isPasswordHidden2 = true;
  void togglePasswordVisibility2() {
    isPasswordHidden2 = !isPasswordHidden2;
    emit(PasswordVisibilityChanged());
  }


  Future<void> registerDevice(String userId) async {
    final playerId = OneSignal.User.pushSubscription.id;

    if (playerId != null) {
      try {
        final response = await DioHelper.postData(
          url: "/register-device",
          data: {
            "user_id": userId,
            "player_id": playerId,
          },
        );

        if (response.statusCode == 200) {
          print("✅ تم تسجيل الجهاز بنجاح");
        } else {
          print("❌ خطأ أثناء تسجيل الجهاز: ${response.statusMessage}");
        }
      } catch (error) {
        print("❌ Error: $error");
      }
    } else {
      print("❌ لم يتم الحصول على player_id من OneSignal");
    }
  }

  String normalizePhone(String phone) {
    phone = phone.trim();

    if (phone.startsWith('964') && phone.length == 13) {
      return phone;
    } else if (phone.startsWith('0') && phone.length == 11) {
      return '964' + phone.substring(1);
    } else if (phone.length == 10) {
      return '964' + phone;
    } else {
      return phone;
    }
  }


  signUp({required String name, required String phone, required String password, required String role, required BuildContext context,}){
    var phoneAfterUpdate=normalizePhone(phone);
    emit(SignUpLoadingState());
    DioHelper.postData(
      url: '/users',
      data:
      {
        'name': name,
        'phone': phoneAfterUpdate,
        'password': password,
        'role': role,
        'status': 'pending',
      },
    ).then((value) {
      emit(SignUpSuccessState());
    }).catchError((error)
    {
      if (error is DioError) {
        print(error.response?.data["error"]);
        showSnackBarError(text: error.response?.data["error"], context: context,);
        emit(SignUpErrorState());
      }else {
        print("Unknown Error: $error");
      }
    });
  }

  List<XFile> selectedImagesDriverImage = [];
  Future<void> pickImagesImagesDriverImage() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> resultList = await picker.pickMultiImage();

    if (resultList.isNotEmpty) {
      selectedImagesDriverImage = resultList;
      emit(ValidationState());
    }
  }

  List<XFile> selectedImagesCarImages = [];
  Future<void> pickImagesImagesCarImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> resultList = await picker.pickMultiImage();

    if (resultList.isNotEmpty) {
      selectedImagesCarImages = resultList;
      emit(ValidationState());
    }
  }

  List<XFile> selectedImagesDrivingLicenseFront = [];
  Future<void> pickImagesDrivingLicenseFront() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> resultList = await picker.pickMultiImage();

    if (resultList.isNotEmpty) {
      selectedImagesDrivingLicenseFront = resultList;
      emit(ValidationState());
    }
  }

  List<XFile> selectedImagesDrivingLicenseBack = [];
  Future<void> pickImagesDrivingLicenseBack() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> resultList = await picker.pickMultiImage();

    if (resultList.isNotEmpty) {
      selectedImagesDrivingLicenseBack = resultList;
      emit(ValidationState());
    }
  }

  signUpDriver({
    required String name, required String phone, required String password, required String vehicleType,
    required String vehicleColor, required String vehicleNumber, String? status, required String location,
    required BuildContext context,})async{
    var phoneAfterUpdate=normalizePhone(phone);
    emit(SignUpLoadingState());
    if (selectedImagesDriverImage.isEmpty) {
      showSnackBarError(text: "رجائا اضغط على البطاقة لاختيار صورة لك", context: context);
      emit(SignUpErrorState());
      return;
    }
    if (selectedImagesCarImages.isEmpty) {
      showSnackBarError(text: "رجائاً اختر صور السيارة", context: context);
      emit(SignUpErrorState());
      return;
    }
    if (selectedImagesDrivingLicenseFront.isEmpty) {
      showSnackBarError(text: "رجائاً اختر صورة اجازة القيادة (الأمامي)", context: context);
      emit(SignUpErrorState());
      return;
    }
    if (selectedImagesDrivingLicenseBack.isEmpty) {
      showSnackBarError(text: "رجائاً اختر صورة اجازة القيادة (الخلفي)", context: context);
      emit(SignUpErrorState());
      return;
    }

    FormData formData = FormData.fromMap(
        {
          'name': name,
          'phone': phoneAfterUpdate,
          'password': password,
          'vehicleType': vehicleType,
          'vehicleColor': vehicleColor,
          'vehicleNumber': vehicleNumber,
          'location': location,
          'status': status ??'pending'
        },
        ListFormat.multiCompatible
    );

    for (var file in selectedImagesDriverImage) {
      formData.files.add(
        MapEntry(
          "driverImage",
          await MultipartFile.fromFile(
          file.path, filename: file.name,
          contentType: MediaType('image', 'jpeg'),
        ),
      ),
    );
    }
    for (var file in selectedImagesCarImages) {
      formData.files.add(
        MapEntry(
          "carImages",
          await MultipartFile.fromFile(
          file.path, filename: file.name,
          contentType: MediaType('image', 'jpeg'),
        ),
      ),
    );
    }
    for (var file in selectedImagesDrivingLicenseFront) {
      formData.files.add(
        MapEntry(
          "drivingLicenseFront",
          await MultipartFile.fromFile(
          file.path, filename: file.name,
          contentType: MediaType('image', 'jpeg'),
        ),
      ),
    );
    }
    for (var file in selectedImagesDrivingLicenseBack) {
      formData.files.add(
        MapEntry(
          "drivingLicenseBack",
          await MultipartFile.fromFile(
          file.path, filename: file.name,
          contentType: MediaType('image', 'jpeg'),
        ),
      ),
    );
    }


    DioHelper.postData(
      url: '/drivers/register',
      data: formData,
    ).then((value) {
      emit(SignUpSuccessState());
    }).catchError((error)
    {
      if (error is DioError) {
        print(error.response?.data["error"]);
        showSnackBarError(text: error.response?.data["error"], context: context,);
        emit(SignUpErrorState());
      }else {
        print("Unknown Error: $error");
      }
    });
  }


  String? token;
  String? role;
  String? id;
  String? phonee;
  bool? isVerified;

  signIn({required String phone, required String password,required BuildContext context,}){
    emit(LoginLoadingState());
    DioHelper.postData(
      url: '/login',
      data:
      {
        'phone': phone,
        'password': password,
      },
    ).then((value) {
     token=value.data['token'];
     role=value.data['user']['role'];
     id=value.data['user']['id'].toString();
     phonee=value.data['user']['phone'].toString();
     isVerified=value.data['user']['isVerified'];
     emit(LoginSuccessState());
    }).catchError((error) {
      if (error is DioError) {
        final status = error.response?.statusCode;
        final msg = error.response?.data is Map
            ? (error.response?.data["error"] ?? "").toString()
            : "";
        if (status == 403 && msg.contains("الحساب غير موثق")) {
          emit(LoginNeedsVerificationState(normalizePhone(phone)));
          return;
        }
        showSnackBarError(text: msg.isNotEmpty ? msg : "حدث خطأ", context: context);
        emit(LoginErrorState());
      } else {
        showSnackBarError(text: "حدث خطأ غير متوقع", context: context);
        emit(LoginErrorState());
      }
    });

  }

  sendOtp({required String phone, required BuildContext context}) {
    final phoneAfterUpdate = normalizePhone(phone);
    emit(SendOtpLoadingState());
    DioHelper.postData(
      url: '/resend-otp', // ✅ مهم
      data: {'phone': phoneAfterUpdate},
    ).then((value) {
      emit(SendOtpSuccessState());
    }).catchError((error) {
      if (error is DioError) {
        showSnackBarError(
          text: error.response?.data["error"] ?? "حدث خطأ غير معروف",
          context: context,
        );
        emit(SendOtpErrorState());
      } else {
        emit(SendOtpErrorState());
      }
    });
  }

  verifyOtp({required String phone, required String code, required BuildContext context}) {
    emit(VerifyOtpLoadingState());
    DioHelper.postData(
      url: '/verify-otp',
      data: {'phone': normalizePhone(phone), 'code': code},
    ).then((value) {
      token = value.data['token'];
      role  = value.data['user']?['role'];
      id    = value.data['user']?['id']?.toString();
      phonee= value.data['user']?['phone']?.toString();
      emit(VerifyOtpSuccessState());
    }).catchError((error) {
      if (error is DioError) {
        showSnackBarError(
          text: error.response?.data["error"] ?? "حدث خطأ غير معروف",
          context: context,
        );
        emit(VerifyOtpErrorState());
      } else {
        emit(VerifyOtpErrorState());
      }
    });
  }

  Timer? _otpTimer;
  int otpSecondsLeft = 0;
  String? otpPhone;
  bool otpInitialized = false;

  bool get canResendOtp => otpSecondsLeft == 0;

  void initOtpFlow(String phone, BuildContext context) {
    if (otpInitialized && otpPhone == phone) return;

    otpInitialized = true;
    otpPhone = normalizePhone(phone);

    sendOtp(phone: otpPhone!, context: context);
    startResendCooldown();
  }

  void startResendCooldown([int seconds = 60]) {
    _otpTimer?.cancel();
    otpSecondsLeft = seconds;
    emit(OtpUiUpdatedState());

    _otpTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      otpSecondsLeft -= 1;
      if (otpSecondsLeft <= 0) {
        otpSecondsLeft = 0;
        t.cancel();
      }
      emit(OtpUiUpdatedState());
    });
  }

  // ─── Forgot Password ─────────────────────────────────────────────────────────
  Timer? _forgotTimer;
  int forgotSecondsLeft = 0;
  String? forgotPhone;

  bool get canResendForgotOtp => forgotSecondsLeft == 0;

  void sendForgotOtp({required String phone, required BuildContext context}) {
    final normalized = normalizePhone(phone);
    emit(ForgotSendOtpLoadingState());
    DioHelper.postData(
      url: '/forgot-password',
      data: {'phone': normalized},
    ).then((value) {
      forgotPhone = normalized;
      startForgotCooldown();
      emit(ForgotSendOtpSuccessState());
    }).catchError((error) {
      if (error is DioError) {
        showSnackBarError(
          text: error.response?.data["error"] ?? "حدث خطأ غير معروف",
          context: context,
        );
        emit(ForgotSendOtpErrorState());
      } else {
        emit(ForgotSendOtpErrorState());
      }
    });
  }

  void startForgotCooldown([int seconds = 60]) {
    _forgotTimer?.cancel();
    forgotSecondsLeft = seconds;
    emit(ForgotOtpUiUpdatedState());

    _forgotTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      forgotSecondsLeft -= 1;
      if (forgotSecondsLeft <= 0) {
        forgotSecondsLeft = 0;
        t.cancel();
      }
      emit(ForgotOtpUiUpdatedState());
    });
  }

  void resetPassword({
    required String phone,
    required String code,
    required String newPassword,
    required BuildContext context,
  }) {
    emit(ResetPasswordLoadingState());
    DioHelper.postData(
      url: '/reset-password',
      data: {
        'phone': normalizePhone(phone),
        'code': code.trim(),
        'newPassword': newPassword,
      },
    ).then((value) {
      final msg = value.data['message'] ?? 'تم تغيير كلمة المرور بنجاح';
      showSnackBarSuccess(text: msg, context: context);
      emit(ResetPasswordSuccessState());
    }).catchError((error) {
      if (error is DioError) {
        showSnackBarError(
          text: error.response?.data["error"] ?? "حدث خطأ غير معروف",
          context: context,
        );
        emit(ResetPasswordErrorState());
      } else {
        emit(ResetPasswordErrorState());
      }
    });
  }

  @override
  Future<void> close() {
    _otpTimer?.cancel();
    _forgotTimer?.cancel();
    return super.close();
  }

}