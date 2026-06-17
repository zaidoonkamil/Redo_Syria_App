abstract class UserStates {}

class UserInitialState extends UserStates {}

class AddOrderLoadingState extends UserStates {}
class AddOrderSuccessState extends UserStates {}
class AddOrderErrorState extends UserStates {}

class GetProfileLoadingState extends UserStates {}
class GetProfileSuccessState extends UserStates {}
class GetProfileErrorState extends UserStates {}

class DeleteProfileLoadingState extends UserStates {}
class DeleteProfileSuccessState extends UserStates {}
class DeleteProfileErrorState extends UserStates {}

class UserOrderLoadingState extends UserStates {}
class UserOrderSuccessState extends UserStates {}
class UserOrderErrorState extends UserStates {}

class GetNotificationsLoadingState extends UserStates {}
class GetNotificationsSuccessState extends UserStates {}
class GetNotificationsErrorState extends UserStates {}

class GetWalletLoadingState extends UserStates {}
class GetWalletSuccessState extends UserStates {}
class GetWalletErrorState extends UserStates {}

class GetWalletTransactionsLoadingState extends UserStates {}
class GetWalletTransactionsSuccessState extends UserStates {}
class GetWalletTransactionsErrorState extends UserStates {}


class UserLoadingLocationState extends UserStates {}
class UserLocationReadyState extends UserStates {}
class UserLocationErrorState extends UserStates {
  final String message;
  UserLocationErrorState(this.message);
}

class CheckActiveRideLoadingState extends UserStates {}
class CheckActiveRideSuccessState extends UserStates {}
class CheckActiveErrorState extends UserStates {
  final String message;
  CheckActiveErrorState(this.message);
}

class UserMapMoveState extends UserStates {}

class UserCreatingRequestState extends UserStates {}
class UserRequestCreatedState extends UserStates {
  final String requestId;
  UserRequestCreatedState(this.requestId);
}
class UserCreateRequestErrorState extends UserStates {
  final String message;
  UserCreateRequestErrorState(this.message);
}

class UserSocketConnectedState extends UserStates {}
class UserSocketDisconnectedState extends UserStates {}
class UserSocketErrorState extends UserStates {
  final String message;
  UserSocketErrorState(this.message);
}

class UserRideStatusChangedState extends UserStates {
  final String status;
  UserRideStatusChangedState(this.status);
}
class UserDriverLocationUpdatedState extends UserStates {}

class UserPaymentSelectedState extends UserStates {
  final String paymentMethod; // 'cash' | 'online'
  UserPaymentSelectedState(this.paymentMethod);
}

class UserCompleteRideLoadingState extends UserStates {}
class UserCompleteRideSuccessState extends UserStates {}
class UserCompleteRideErrorState extends UserStates {
  final String message;
  UserCompleteRideErrorState(this.message);
}

/// تم الدفع أونلاين - انتظار الكابتن لينهي الرحلة
class UserPaymentPendingDriverState extends UserStates {}

/// رصيد المحفظة غير كافي
class UserInsufficientBalanceState extends UserStates {}