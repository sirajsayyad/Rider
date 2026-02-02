/// Application-wide constants
library;

class AppConstants {
  // User Roles
  static const String rolePassenger = 'passenger';
  static const String roleDriver = 'driver';
  static const String roleAdmin = 'admin';
  
  // Ride Status
  static const String rideStatusPending = 'pending';
  static const String rideStatusAccepted = 'accepted';
  static const String rideStatusArrived = 'arrived';
  static const String rideStatusStarted = 'started';
  static const String rideStatusCompleted = 'completed';
  static const String rideStatusCancelled = 'cancelled';
  
  // Driver Status
  static const String driverStatusOnline = 'online';
  static const String driverStatusOffline = 'offline';
  static const String driverStatusBusy = 'busy';
  
  // Document Types
  static const String docLicense = 'license';
  static const String docVehicleRC = 'vehicle_rc';
  static const String docInsurance = 'insurance';
  static const String docProfilePhoto = 'profile_photo';
  static const String docVehiclePhoto = 'vehicle_photo';
  
  // Document Status
  static const String docStatusPending = 'pending';
  static const String docStatusVerified = 'verified';
  static const String docStatusRejected = 'rejected';
  static const String docStatusExpired = 'expired';
  
  // Payment Methods
  static const String paymentCash = 'cash';
  static const String paymentUpi = 'upi';
  static const String paymentCard = 'card';
  static const String paymentWallet = 'wallet';
  
  // Payment Status
  static const String paymentPending = 'pending';
  static const String paymentCompleted = 'completed';
  static const String paymentFailed = 'failed';
  static const String paymentRefunded = 'refunded';
  
  // Vehicle Types
  static const String vehicleAuto = 'auto';
  static const String vehicleMini = 'mini';
  static const String vehicleSedan = 'sedan';
  static const String vehicleSuv = 'suv';
  static const String vehiclePremium = 'premium';
  static const String vehicleBike = 'bike';
  
  // Saved Location Labels
  static const String locationHome = 'Home';
  static const String locationWork = 'Work';
  static const String locationOther = 'Other';
  
  // Time periods for analytics
  static const String periodDaily = 'daily';
  static const String periodWeekly = 'weekly';
  static const String periodMonthly = 'monthly';
  
  // Dispute Types
  static const String disputeFareIssue = 'fare_issue';
  static const String disputeRouteIssue = 'route_issue';
  static const String disputeBehavior = 'behavior';
  static const String disputeSafety = 'safety';
  static const String disputePayment = 'payment';
  static const String disputeOther = 'other';
  
  // Dispute Status
  static const String disputeOpen = 'open';
  static const String disputeInProgress = 'in_progress';
  static const String disputeResolved = 'resolved';
  static const String disputeClosed = 'closed';
}
