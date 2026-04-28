/// API Constants
library;

class ApiConstants {
  // Base paths
  static const String apiVersion = '/api/v1';
  
  // Auth endpoints
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String refreshToken = '/auth/refresh-token';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  
  // Passenger endpoints
  static const String passengerProfile = '/passenger/profile';
  static const String passengerRides = '/passenger/rides';
  static const String savedLocations = '/passenger/saved-locations';
  static const String sos = '/passenger/sos';
  static const String wallet = '/passenger/wallet';
  static const String walletAdd = '/passenger/wallet/add';
  
  // Driver endpoints
  static const String driverRegister = '/driver/register';
  static const String driverProfile = '/driver/profile';
  static const String driverStatus = '/driver/status';
  static const String driverLocation = '/driver/location';
  static const String driverPendingRides = '/driver/rides/pending';
  static const String driverEarnings = '/driver/earnings';
  static const String driverDocuments = '/driver/documents';
  static const String driverVehicles = '/driver/vehicles';
  
  // Ride endpoints
  static const String rideEstimate = '/rides/estimate';
  static const String rideTrack = '/rides/{id}/track';
  static const String rideRoute = '/rides/{id}/route';
  static const String rideInvoice = '/rides/{id}/invoice';
  static const String rideChat = '/rides/{id}/chat';
  static const String rideSchedule = '/rides/schedule';
  static const String rideScheduleCancel = '/rides/schedule/{id}/cancel';
  static const String rideMultiStop = '/rides/{id}/stops';
  static const String ridePool = '/rides/pool';
  static const String ridePoolMatch = '/rides/pool/{id}/match';
  
  // Payment endpoints
  static const String paymentInitiate = '/payments/initiate';
  static const String paymentVerify = '/payments/verify';
  static const String paymentMethods = '/payments/methods';
  
  // Rating endpoints
  static const String rideRating = '/rides/{id}/rating';
  static const String driverRatings = '/drivers/{id}/ratings';
  static const String driverRatingSummary = '/drivers/{id}/rating-summary';
  
  // Referral endpoints
  static const String referralCode = '/referral/code';
  static const String referralApply = '/referral/apply';
  static const String referralHistory = '/referral/history';
  
  // Corporate endpoints
  static const String corporateAccount = '/corporate/account';
  static const String corporateEmployees = '/corporate/employees';
  static const String corporateInvoices = '/corporate/invoices';
  static const String corporateBudget = '/corporate/budget';
  
  // Subscription endpoints
  static const String subscriptionPlans = '/subscriptions/plans';
  static const String subscriptionActive = '/subscriptions/active';
  static const String subscriptionSubscribe = '/subscriptions/subscribe';
  static const String subscriptionCancel = '/subscriptions/cancel';
  
  // Lost & Found endpoints
  static const String lostFoundReport = '/lost-found/report';
  static const String lostFoundItems = '/lost-found/items';
  static const String lostFoundStatus = '/lost-found/{id}/status';
  static const String lostFoundReturn = '/lost-found/{id}/return';
  
  // Admin endpoints
  static const String adminLogin = '/admin/auth/login';
  static const String adminDashboard = '/admin/dashboard/stats';
  static const String adminUsers = '/admin/users';
  static const String adminDrivers = '/admin/drivers';
  static const String adminRides = '/admin/rides';
  static const String adminPromoCodes = '/admin/promo-codes';
  static const String adminDisputes = '/admin/disputes';
  static const String adminEarnings = '/admin/earnings';
  static const String adminSurgePricing = '/admin/surge-pricing';
  static const String adminBroadcast = '/admin/notifications/broadcast';
  static const String adminLostFound = '/admin/lost-found';
  static const String adminCorporate = '/admin/corporate';
  static const String adminSubscriptions = '/admin/subscriptions';
}

/// WebSocket Events
class WsEvents {
  // Driver events
  static const String driverLocation = 'driver:location';
  static const String driverStatusChange = 'driver:status';
  
  // Ride events
  static const String rideRequest = 'ride:request';
  static const String rideAccepted = 'ride:accepted';
  static const String rideRejected = 'ride:rejected';
  static const String rideStarted = 'ride:started';
  static const String rideTracking = 'ride:tracking';
  static const String rideCompleted = 'ride:completed';
  static const String rideCancelled = 'ride:cancelled';
  
  // Chat events
  static const String chatMessage = 'chat:message';
  static const String chatTyping = 'chat:typing';
  static const String chatRead = 'chat:read';
  
  // Pool events
  static const String poolMatch = 'pool:match';
  static const String poolUpdate = 'pool:update';
  
  // Call events
  static const String callInitiate = 'call:initiate';
  static const String callAnswer = 'call:answer';
  static const String callEnd = 'call:end';
  
  // SOS events
  static const String sosAlert = 'sos:alert';
  static const String sosResolved = 'sos:resolved';
  
  // Schedule events
  static const String scheduleReminder = 'schedule:reminder';
  static const String scheduleDriverAssigned = 'schedule:driver_assigned';
}
