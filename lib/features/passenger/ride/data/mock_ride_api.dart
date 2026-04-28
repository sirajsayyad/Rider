import 'dart:math';

import '../domain/ride_models.dart';

class MockRideApi {
  final Random _random = Random();

  final List<DriverInfo> _drivers = const [
    DriverInfo(
      id: 'd_112',
      name: 'Arjun Mehta',
      vehicleModel: 'Hyundai i20',
      vehicleNumber: 'DL04CR1231',
      rating: 4.9,
      maskedPhone: '+91 90XXX 11111',
      distanceFromPickupKm: 0.8,
      etaMinutes: 3,
      acceptanceRate: 0.96,
      cancellationRate: 0.02,
      cancellationCount: 1,
    ),
    DriverInfo(
      id: 'd_278',
      name: 'Nikhil Saini',
      vehicleModel: 'Honda City',
      vehicleNumber: 'HR26AZ7452',
      rating: 4.8,
      maskedPhone: '+91 90XXX 22222',
      distanceFromPickupKm: 1.3,
      etaMinutes: 4,
      acceptanceRate: 0.93,
      cancellationRate: 0.03,
      cancellationCount: 1,
    ),
    DriverInfo(
      id: 'd_392',
      name: 'Ravi Verma',
      vehicleModel: 'TVS NTorq',
      vehicleNumber: 'DL01BK8831',
      rating: 4.7,
      maskedPhone: '+91 90XXX 33333',
      distanceFromPickupKm: 0.6,
      etaMinutes: 2,
      acceptanceRate: 0.98,
      cancellationRate: 0.01,
      cancellationCount: 0,
    ),
    DriverInfo(
      id: 'd_420',
      name: 'Sakshi Rao',
      vehicleModel: 'Maruti Ertiga',
      vehicleNumber: 'DL03CW4501',
      rating: 4.9,
      maskedPhone: '+91 90XXX 44444',
      distanceFromPickupKm: 1.6,
      etaMinutes: 5,
      acceptanceRate: 0.95,
      cancellationRate: 0.02,
      cancellationCount: 1,
    ),
    DriverInfo(
      id: 'd_531',
      name: 'Vikas Khanna',
      vehicleModel: 'Toyota Innova',
      vehicleNumber: 'HR55BX8098',
      rating: 4.6,
      maskedPhone: '+91 90XXX 55555',
      distanceFromPickupKm: 2.1,
      etaMinutes: 6,
      acceptanceRate: 0.91,
      cancellationRate: 0.09,
      cancellationCount: 4,
    ),
  ];

  final Map<String, int> _driverCancellationOffences = {
    'd_531': 4,
  };

  Future<List<RideTypeQuote>> fetchQuotes({
    required double distanceKm,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      _buildQuote(
        type: RideType.economy,
        label: 'Economy',
        subtitle: 'Budget friendly with fast pickup',
        seats: 4,
        distanceKm: distanceKm,
        baseRate: 52,
        distanceRate: 10.5,
        timeRate: 2.4,
        surgeMultiplier: 1.10,
      ),
      _buildQuote(
        type: RideType.premium,
        label: 'Premium',
        subtitle: 'Top-rated drivers and quiet cabins',
        seats: 4,
        distanceKm: distanceKm,
        baseRate: 95,
        distanceRate: 17.0,
        timeRate: 3.4,
        surgeMultiplier: 1.12,
      ),
      _buildQuote(
        type: RideType.bike,
        label: 'Bike',
        subtitle: 'Fast solo commute in traffic',
        seats: 1,
        distanceKm: distanceKm,
        baseRate: 24,
        distanceRate: 7.0,
        timeRate: 1.7,
        surgeMultiplier: 1.06,
      ),
      _buildQuote(
        type: RideType.pool,
        label: 'Pool',
        subtitle: 'Share ride, save up to 40%',
        seats: 2,
        distanceKm: distanceKm,
        baseRate: 40,
        distanceRate: 8.0,
        timeRate: 1.8,
        surgeMultiplier: 1.0,
      ),
      _buildQuote(
        type: RideType.suv,
        label: 'SUV',
        subtitle: 'Extra luggage space and bigger cabin',
        seats: 6,
        distanceKm: distanceKm,
        baseRate: 120,
        distanceRate: 21.0,
        timeRate: 4.0,
        surgeMultiplier: 1.15,
      ),
    ];
  }

  List<String> suggestLandmarks(RidePoint pickup) {
    return [
      'Metro Gate 2, 120 m away',
      'City Mall Main Entrance, 180 m away',
      'Petrol Pump Corner, 220 m away',
    ];
  }

  List<NearbyDriverPreview> nearestDrivers(RideType rideType) {
    final eligible = _eligibleDriversFor(rideType).take(3).toList();
    return eligible
        .map(
          (driver) => NearbyDriverPreview(
            id: driver.id,
            name: driver.name,
            vehicleModel: driver.vehicleModel,
            rating: driver.rating,
            distanceKm: driver.distanceFromPickupKm,
            etaMinutes: driver.etaMinutes,
            acceptanceRate: driver.acceptanceRate,
          ),
        )
        .toList();
  }

  Future<DriverInfo> matchDriver(RideType rideType) async {
    await Future.delayed(const Duration(seconds: 2));

    final ranked = _eligibleDriversFor(rideType);
    ranked.sort((a, b) => _scoreDriver(b).compareTo(_scoreDriver(a)));
    return ranked.first;
  }

  DriverInfo? reassignDriver(RideType rideType, String previousDriverId) {
    final candidates = _eligibleDriversFor(rideType)
        .where((driver) => driver.id != previousDriverId)
        .toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => _scoreDriver(b).compareTo(_scoreDriver(a)));
    return candidates.first;
  }

  Compensation registerDriverCancellation(DriverInfo driver) {
    final offences = (_driverCancellationOffences[driver.id] ?? 0) + 1;
    _driverCancellationOffences[driver.id] = offences;

    final amount = offences >= 3 ? 90.0 : 45.0;
    return Compensation(
      type: CompensationType.walletCredit,
      amount: amount,
      reason: offences >= 3
          ? '${driver.name} exceeded the cancellation threshold and has been deprioritized.'
          : '${driver.name} cancelled after assignment.',
      createdAt: DateTime.now(),
    );
  }

  bool isDriverRestricted(String driverId) {
    return (_driverCancellationOffences[driverId] ?? 0) >= 3;
  }

  RideReceipt createReceipt({
    required String rideId,
    required FareBreakdown breakdown,
    required RiderPaymentMethod paymentMethod,
    required TransactionStatus paymentStatus,
    required double paidAmount,
    required double refundedAmount,
    required int rewardPointsEarned,
  }) {
    return RideReceipt(
      rideId: rideId,
      baseFare: breakdown.baseFare,
      distanceFare: breakdown.distanceFare,
      serviceFee: breakdown.platformFee,
      tax: breakdown.tax,
      total: breakdown.total,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      paidAmount: paidAmount,
      refundedAmount: refundedAmount,
      rewardPointsEarned: rewardPointsEarned,
      generatedAt: DateTime.now(),
    );
  }

  bool shouldDriverCancel(DriverInfo driver, {required int reassignmentCount}) {
    if (reassignmentCount > 0) return false;
    final risk = driver.cancellationRate + 0.04;
    return _random.nextDouble() < risk;
  }

  bool shouldFlagRouteDeviation() {
    return _random.nextDouble() < 0.25;
  }

  bool shouldPaymentFail(RiderPaymentMethod method) {
    if (method == RiderPaymentMethod.cash) return false;
    if (method == RiderPaymentMethod.wallet) return false;
    return _random.nextDouble() < 0.2;
  }

  RideTypeQuote _buildQuote({
    required RideType type,
    required String label,
    required String subtitle,
    required int seats,
    required double distanceKm,
    required double baseRate,
    required double distanceRate,
    required double timeRate,
    required double surgeMultiplier,
  }) {
    final tripMinutes = max(8, (distanceKm * 3.6).round());
    final baseFare = baseRate;
    final distanceFare = distanceKm * distanceRate;
    final timeFare = tripMinutes * timeRate;
    final preSurgeTotal = baseFare + distanceFare + timeFare;
    final surgeAmount = preSurgeTotal * (surgeMultiplier - 1);
    final platformFee = max(12.0, preSurgeTotal * 0.05);
    final taxable = preSurgeTotal + surgeAmount + platformFee;
    final tax = taxable * 0.05;
    final total = taxable + tax;

    return RideTypeQuote(
      type: type,
      label: label,
      subtitle: subtitle,
      seats: seats,
      fare: total,
      etaMinutes: max(2, 2 + _random.nextInt(5)),
      availableDrivers: _eligibleDriversFor(type).length,
      breakdown: FareBreakdown(
        baseFare: baseFare,
        distanceFare: distanceFare,
        timeFare: timeFare,
        surgeMultiplier: surgeMultiplier,
        surgeAmount: surgeAmount,
        platformFee: platformFee,
        tax: tax,
        total: total,
      ),
    );
  }

  List<DriverInfo> _eligibleDriversFor(RideType rideType) {
    final requiresBike = rideType == RideType.bike;
    return _drivers.where((driver) {
      if (isDriverRestricted(driver.id)) return false;
      final isBike = driver.vehicleModel.toLowerCase().contains('tvs');
      return requiresBike ? isBike : !isBike;
    }).toList();
  }

  double _scoreDriver(DriverInfo driver) {
    return (driver.rating * 50) +
        (driver.acceptanceRate * 30) +
        ((1 - driver.cancellationRate) * 15) +
        ((3 - min(driver.distanceFromPickupKm, 3.0)) * 5);
  }
}
