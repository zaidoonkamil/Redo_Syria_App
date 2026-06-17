abstract class DriverStates {}

class DriverInitialState extends DriverStates {}

class DriverLoadingLocationState extends DriverStates {}
class DriverLocationReadyState extends DriverStates {}
class DriverLocationErrorState extends DriverStates {
  final String message;
  DriverLocationErrorState(this.message);
}

class DriverSocketConnectedState extends DriverStates {}
class DriverSocketDisconnectedState extends DriverStates {}
class DriverSocketErrorState extends DriverStates {
  final String message;
  DriverSocketErrorState(this.message);
}

class DriverOnlineChangedState extends DriverStates {}

class DriverNewRequestState extends DriverStates {}
class DriverRequestClearedState extends DriverStates {}

class DriverTripStatusChangedState extends DriverStates {
  final String status;
  DriverTripStatusChangedState(this.status);
}

class DriverWalletBlockedState extends DriverStates {
  final String message;
  final double balance;
  DriverWalletBlockedState(this.message, {this.balance = 0});
}

// بعد انتهاء الرحلة: تحمل تفاصيل الدفع والمحفظة
class DriverTripCompletedState extends DriverStates {
  final String paymentMethod;   // cash | online
  final double finalFare;
  final double commission;
  final double driverEarnings;
  final double? newBalance;
  DriverTripCompletedState({
    required this.paymentMethod,
    required this.finalFare,
    required this.commission,
    required this.driverEarnings,
    this.newBalance,
  });
}

// keep for backward compat but map to wallet
class DriverDebtBlockedState extends DriverWalletBlockedState {
  DriverDebtBlockedState(String message) : super(message);
}

/// الزبون دفع أونلاين - أبلغ السائق
class DriverUserPaidOnlineState extends DriverStates {}

class DriverMapUpdatedState extends DriverStates {}
class DriverPendingUpdatedState extends DriverStates {}


class DriverOrderLoadingState extends DriverStates {}
class DriverOrderSuccessState extends DriverStates {}
class DriverOrderErrorState extends DriverStates {}

class WalletSettingsLoadingState extends DriverStates {}
class WalletSettingsSuccessState extends DriverStates {}
class WalletSettingsErrorState extends DriverStates {}

class DeleteProfileLoadingState extends DriverStates {}
class DeleteProfileSuccessState extends DriverStates {}
class DeleteProfileErrorState extends DriverStates {}


class DriverCheckActiveTripLoadingState extends DriverStates {}
class DriverCheckActiveTripSuccessState extends DriverStates {}
class DriverCheckActiveTripErrorState extends DriverStates {
  final String message;
  DriverCheckActiveTripErrorState(this.message);
}

class GetProfileLoadingState extends DriverStates {}
class GetProfileSuccessState extends DriverStates {}
class GetProfileErrorState extends DriverStates {}