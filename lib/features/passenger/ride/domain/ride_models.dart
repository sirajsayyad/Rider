enum RideLifecycleStatus {
  idle,
  searching,
  driverAssigned,
  arriving,
  inProgress,
  completed,
  cancelled,
}

enum RideType {
  economy,
  premium,
  bike,
  suv,
  pool,
}

enum RiderPaymentMethod {
  cash,
  upi,
  card,
  wallet,
  corporate,
}

enum TransactionStatus {
  pending,
  success,
  failed,
  refunded,
}

enum CompensationType {
  walletCredit,
  discount,
}

class RidePoint {
  final double latitude;
  final double longitude;
  final String address;

  const RidePoint({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  bool sameAddressAs(RidePoint other) => address.toLowerCase() == other.address.toLowerCase();
}

class RideTypeQuote {
  final RideType type;
  final String label;
  final String subtitle;
  final int seats;
  final double fare;
  final int etaMinutes;
  final FareBreakdown breakdown;
  final int availableDrivers;

  const RideTypeQuote({
    required this.type,
    required this.label,
    required this.subtitle,
    required this.seats,
    required this.fare,
    required this.etaMinutes,
    required this.breakdown,
    required this.availableDrivers,
  });
}

class DriverInfo {
  final String id;
  final String name;
  final String vehicleModel;
  final String vehicleNumber;
  final double rating;
  final String maskedPhone;
  final double distanceFromPickupKm;
  final int etaMinutes;
  final double acceptanceRate;
  final double cancellationRate;
  final int cancellationCount;
  // New fields for features
  final String gender;
  final bool petFriendlyOptIn;
  final int totalRatings;
  final int totalTrips;

  const DriverInfo({
    required this.id,
    required this.name,
    required this.vehicleModel,
    required this.vehicleNumber,
    required this.rating,
    required this.maskedPhone,
    required this.distanceFromPickupKm,
    required this.etaMinutes,
    required this.acceptanceRate,
    required this.cancellationRate,
    required this.cancellationCount,
    this.gender = 'male',
    this.petFriendlyOptIn = false,
    this.totalRatings = 0,
    this.totalTrips = 0,
  });
}

class RideReceipt {
  final String rideId;
  final double baseFare;
  final double distanceFare;
  final double serviceFee;
  final double tax;
  final double total;
  final RiderPaymentMethod paymentMethod;
  final TransactionStatus paymentStatus;
  final double paidAmount;
  final double refundedAmount;
  final int rewardPointsEarned;
  final DateTime generatedAt;

  const RideReceipt({
    required this.rideId,
    required this.baseFare,
    required this.distanceFare,
    required this.serviceFee,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.paidAmount,
    required this.refundedAmount,
    required this.rewardPointsEarned,
    required this.generatedAt,
  });
}

class FareBreakdown {
  final double baseFare;
  final double distanceFare;
  final double timeFare;
  final double surgeMultiplier;
  final double surgeAmount;
  final double platformFee;
  final double tax;
  final double total;
  final double petSurcharge;
  final double poolDiscount;
  final double subscriptionDiscount;

  const FareBreakdown({
    required this.baseFare,
    required this.distanceFare,
    required this.timeFare,
    required this.surgeMultiplier,
    required this.surgeAmount,
    required this.platformFee,
    required this.tax,
    required this.total,
    this.petSurcharge = 0,
    this.poolDiscount = 0,
    this.subscriptionDiscount = 0,
  });
}

class FareLock {
  final double lockedFare;
  final DateTime lockedAt;
  final DateTime expiresAt;

  const FareLock({
    required this.lockedFare,
    required this.lockedAt,
    required this.expiresAt,
  });

  bool get isActive => DateTime.now().isBefore(expiresAt);
}

class RidePreferences {
  final bool acRide;
  final bool silentRide;
  final bool musicOn;
  final bool womenOnly;
  final bool petFriendly;

  const RidePreferences({
    this.acRide = true,
    this.silentRide = false,
    this.musicOn = false,
    this.womenOnly = false,
    this.petFriendly = false,
  });

  RidePreferences copyWith({
    bool? acRide,
    bool? silentRide,
    bool? musicOn,
    bool? womenOnly,
    bool? petFriendly,
  }) {
    return RidePreferences(
      acRide: acRide ?? this.acRide,
      silentRide: silentRide ?? this.silentRide,
      musicOn: musicOn ?? this.musicOn,
      womenOnly: womenOnly ?? this.womenOnly,
      petFriendly: petFriendly ?? this.petFriendly,
    );
  }
}

class NearbyDriverPreview {
  final String id;
  final String name;
  final String vehicleModel;
  final double rating;
  final double distanceKm;
  final int etaMinutes;
  final double acceptanceRate;
  final String gender;
  final bool petFriendlyOptIn;

  const NearbyDriverPreview({
    required this.id,
    required this.name,
    required this.vehicleModel,
    required this.rating,
    required this.distanceKm,
    required this.etaMinutes,
    required this.acceptanceRate,
    this.gender = 'male',
    this.petFriendlyOptIn = false,
  });
}

class Compensation {
  final CompensationType type;
  final double amount;
  final String reason;
  final DateTime createdAt;

  const Compensation({
    required this.type,
    required this.amount,
    required this.reason,
    required this.createdAt,
  });
}

class TransactionRecord {
  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final RiderPaymentMethod method;
  final TransactionStatus status;
  final DateTime createdAt;

  const TransactionRecord({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.method,
    required this.status,
    required this.createdAt,
  });
}

class SafetyState {
  final bool sosActive;
  final bool routeDeviationDetected;
  final bool liveTrackingEnabled;
  final bool gpsTrackingEnabled;
  final bool privacyModeEnabled;
  final bool preciseLocationSharingEnabled;
  final List<String> sharedContacts;
  final String? routeAlert;
  final DateTime? lastLocationUpdatedAt;

  const SafetyState({
    this.sosActive = false,
    this.routeDeviationDetected = false,
    this.liveTrackingEnabled = true,
    this.gpsTrackingEnabled = true,
    this.privacyModeEnabled = true,
    this.preciseLocationSharingEnabled = false,
    this.sharedContacts = const ['Mom', 'Alex'],
    this.routeAlert,
    this.lastLocationUpdatedAt,
  });

  SafetyState copyWith({
    bool? sosActive,
    bool? routeDeviationDetected,
    bool? liveTrackingEnabled,
    bool? gpsTrackingEnabled,
    bool? privacyModeEnabled,
    bool? preciseLocationSharingEnabled,
    List<String>? sharedContacts,
    String? routeAlert,
    DateTime? lastLocationUpdatedAt,
    bool clearRouteAlert = false,
  }) {
    return SafetyState(
      sosActive: sosActive ?? this.sosActive,
      routeDeviationDetected:
          routeDeviationDetected ?? this.routeDeviationDetected,
      liveTrackingEnabled: liveTrackingEnabled ?? this.liveTrackingEnabled,
      gpsTrackingEnabled: gpsTrackingEnabled ?? this.gpsTrackingEnabled,
      privacyModeEnabled: privacyModeEnabled ?? this.privacyModeEnabled,
      preciseLocationSharingEnabled:
          preciseLocationSharingEnabled ?? this.preciseLocationSharingEnabled,
      sharedContacts: sharedContacts ?? this.sharedContacts,
      routeAlert: clearRouteAlert ? null : (routeAlert ?? this.routeAlert),
      lastLocationUpdatedAt:
          lastLocationUpdatedAt ?? this.lastLocationUpdatedAt,
    );
  }
}

class RideTrip {
  final String id;
  final RidePoint pickup;
  final RidePoint destination;
  final RideType rideType;
  final RiderPaymentMethod paymentMethod;
  final double distanceKm;
  final int durationMinutes;
  final double fare;
  final FareBreakdown fareBreakdown;
  final RideLifecycleStatus status;
  final DriverInfo? driver;
  final FareLock? fareLock;
  final RidePreferences preferences;
  final List<Compensation> compensations;
  final int reassignmentCount;
  final int rewardPointsEarned;
  final List<String> sharedContacts;
  final bool routeDeviationDetected;
  final DateTime createdAt;
  final RideReceipt? receipt;
  // New feature fields
  final List<RidePoint> intermediateStops;
  final bool isScheduled;
  final DateTime? scheduledAt;
  final bool isPoolRide;
  final int poolPassengerCount;
  final bool isCorporateRide;
  final String? corporateAccountId;
  final bool isPetFriendly;
  final double petSurcharge;
  final bool isFemaleOnly;
  final String? subscriptionId;

  const RideTrip({
    required this.id,
    required this.pickup,
    required this.destination,
    required this.rideType,
    required this.paymentMethod,
    required this.distanceKm,
    required this.durationMinutes,
    required this.fare,
    required this.fareBreakdown,
    required this.status,
    required this.createdAt,
    required this.preferences,
    this.fareLock,
    this.driver,
    this.compensations = const [],
    this.reassignmentCount = 0,
    this.rewardPointsEarned = 0,
    this.sharedContacts = const [],
    this.routeDeviationDetected = false,
    this.receipt,
    this.intermediateStops = const [],
    this.isScheduled = false,
    this.scheduledAt,
    this.isPoolRide = false,
    this.poolPassengerCount = 1,
    this.isCorporateRide = false,
    this.corporateAccountId,
    this.isPetFriendly = false,
    this.petSurcharge = 0,
    this.isFemaleOnly = false,
    this.subscriptionId,
  });

  RideTrip copyWith({
    RidePoint? pickup,
    RidePoint? destination,
    RideType? rideType,
    RiderPaymentMethod? paymentMethod,
    double? distanceKm,
    int? durationMinutes,
    double? fare,
    FareBreakdown? fareBreakdown,
    RideLifecycleStatus? status,
    DriverInfo? driver,
    FareLock? fareLock,
    RidePreferences? preferences,
    List<Compensation>? compensations,
    int? reassignmentCount,
    int? rewardPointsEarned,
    List<String>? sharedContacts,
    bool? routeDeviationDetected,
    DateTime? createdAt,
    RideReceipt? receipt,
    List<RidePoint>? intermediateStops,
    bool? isScheduled,
    DateTime? scheduledAt,
    bool? isPoolRide,
    int? poolPassengerCount,
    bool? isCorporateRide,
    String? corporateAccountId,
    bool? isPetFriendly,
    double? petSurcharge,
    bool? isFemaleOnly,
    String? subscriptionId,
  }) {
    return RideTrip(
      id: id,
      pickup: pickup ?? this.pickup,
      destination: destination ?? this.destination,
      rideType: rideType ?? this.rideType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      distanceKm: distanceKm ?? this.distanceKm,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      fare: fare ?? this.fare,
      fareBreakdown: fareBreakdown ?? this.fareBreakdown,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      driver: driver ?? this.driver,
      fareLock: fareLock ?? this.fareLock,
      preferences: preferences ?? this.preferences,
      compensations: compensations ?? this.compensations,
      reassignmentCount: reassignmentCount ?? this.reassignmentCount,
      rewardPointsEarned: rewardPointsEarned ?? this.rewardPointsEarned,
      sharedContacts: sharedContacts ?? this.sharedContacts,
      routeDeviationDetected:
          routeDeviationDetected ?? this.routeDeviationDetected,
      receipt: receipt ?? this.receipt,
      intermediateStops: intermediateStops ?? this.intermediateStops,
      isScheduled: isScheduled ?? this.isScheduled,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      isPoolRide: isPoolRide ?? this.isPoolRide,
      poolPassengerCount: poolPassengerCount ?? this.poolPassengerCount,
      isCorporateRide: isCorporateRide ?? this.isCorporateRide,
      corporateAccountId: corporateAccountId ?? this.corporateAccountId,
      isPetFriendly: isPetFriendly ?? this.isPetFriendly,
      petSurcharge: petSurcharge ?? this.petSurcharge,
      isFemaleOnly: isFemaleOnly ?? this.isFemaleOnly,
      subscriptionId: subscriptionId ?? this.subscriptionId,
    );
  }
}

class RideNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;

  const RideNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
  });
}

class SavedPlace {
  final String label;
  final RidePoint point;

  const SavedPlace({
    required this.label,
    required this.point,
  });
}
