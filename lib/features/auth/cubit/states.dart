abstract class LoginStates {}

class LoginInitialState extends LoginStates {}

class ValidationState extends LoginStates {}
class PasswordVisibilityChanged extends LoginStates {}

class LoginLoadingState extends LoginStates {}
class LoginSuccessState extends LoginStates {}
class LoginErrorState extends LoginStates {}
class LoginNeedsVerificationState extends LoginStates {
  final String phone;
  LoginNeedsVerificationState(this.phone);
}

class SignUpLoadingState extends LoginStates {}
class SignUpSuccessState extends LoginStates {}
class SignUpErrorState extends LoginStates {}

class OtpUiUpdatedState extends LoginStates {}

class SendOtpSuccessState extends LoginStates {}
class SendOtpLoadingState extends LoginStates {}
class SendOtpErrorState extends LoginStates {}

class VerifyOtpLoadingState extends LoginStates {}
class VerifyOtpSuccessState extends LoginStates {}
class VerifyOtpErrorState extends LoginStates {}

// ─── Forgot Password ──────────────────────────────────────────────────────────
class ForgotOtpUiUpdatedState extends LoginStates {}

class ForgotSendOtpLoadingState extends LoginStates {}
class ForgotSendOtpSuccessState extends LoginStates {}
class ForgotSendOtpErrorState extends LoginStates {}

class ResetPasswordLoadingState extends LoginStates {}
class ResetPasswordSuccessState extends LoginStates {}
class ResetPasswordErrorState extends LoginStates {}
