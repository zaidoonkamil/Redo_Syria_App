abstract class AppStatesAdmin {}

class AppInitialStateAdmin extends AppStatesAdmin {}

class AdminLoginLoadingState extends AppStatesAdmin {}

class AdminLoginSuccessState extends AppStatesAdmin {}

class AdminLoginErrorState extends AppStatesAdmin {}

class AdminStatsLoadingState extends AppStatesAdmin {}

class AdminStatsSuccessState extends AppStatesAdmin {}

class AdminStatsErrorState extends AppStatesAdmin {
  final String message;
  AdminStatsErrorState(this.message);
}

class AdminSendNotificationLoadingState extends AppStatesAdmin {}

class AdminSendNotificationSuccessState extends AppStatesAdmin {}

class AdminSendNotificationErrorState extends AppStatesAdmin {}

class GetUsersOnlyLoadingState extends AppStatesAdmin {}

class GetUsersOnlySuccessState extends AppStatesAdmin {}

class GetUsersOnlyErrorState extends AppStatesAdmin {}

class UpdateStatusOfUserLoadingState extends AppStatesAdmin {}

class UpdateStatusOfUserSuccessState extends AppStatesAdmin {}

class UpdateStatusOfUserErrorState extends AppStatesAdmin {}

class DeleteLoadingState extends AppStatesAdmin {}

class DeleteSuccessState extends AppStatesAdmin {}

class DeleteErrorState extends AppStatesAdmin {}

class GetDriverOnlyLoadingState extends AppStatesAdmin {}

class GetDriverOnlySuccessState extends AppStatesAdmin {}

class GetDriverOnlyErrorState extends AppStatesAdmin {}

class AdminPricingLoadingState extends AppStatesAdmin {}

class AdminPricingSuccessState extends AppStatesAdmin {}

class AdminPricingErrorState extends AppStatesAdmin {}

class AdminDebtSettingsLoadingState extends AppStatesAdmin {}

class AdminDebtSettingsSuccessState extends AppStatesAdmin {}

class AdminDebtSettingsErrorState extends AppStatesAdmin {}

class UpdateAdminPricingLoadingState extends AppStatesAdmin {}

class UpdateAdminPricingSuccessState extends AppStatesAdmin {}

class UpdateAdminPricingErrorState extends AppStatesAdmin {}

class UpdateAdminPricingTiersLoadingState extends AppStatesAdmin {}

class UpdateAdminPricingTiersSuccessState extends AppStatesAdmin {}

class UpdateAdminPricingTiersErrorState extends AppStatesAdmin {}

class UpdateAdminDebtSettingsLoadingState extends AppStatesAdmin {}

class UpdateAdminDebtSettingsSuccessState extends AppStatesAdmin {}

class UpdateAdminDebtSettingsErrorState extends AppStatesAdmin {}

class AdminPayDebtLoadingState extends AppStatesAdmin {}

class AdminPayDebtSuccessState extends AppStatesAdmin {}

class AdminPayDebtErrorState extends AppStatesAdmin {}

class WhatsAppLoadingState extends AppStatesAdmin {}

class WhatsAppStatusSuccessState extends AppStatesAdmin {}

class WhatsAppQrSuccessState extends AppStatesAdmin {}

class WhatsAppInitSuccessState extends AppStatesAdmin {}

class WhatsAppLogoutSuccessState extends AppStatesAdmin {}

class WhatsAppSendSuccessState extends AppStatesAdmin {}

class WhatsAppErrorState extends AppStatesAdmin {}
