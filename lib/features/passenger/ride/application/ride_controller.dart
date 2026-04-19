import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/google_maps_service.dart';
import '../../../../core/services/location_service.dart';
import '../data/mock_ride_api.dart';
import '../domain/ride_models.dart';

class RideState {
  final RidePoint? pickup;
  final RidePoint? destination;
  final List<RideTypeQuote> quotes;
  final RideTypeQuote? selectedQuote;
  final RiderPaymentMethod paymentMethod;
  final RideTrip? activeTrip;
  final List<RideTrip> tripHistory;
  final List<RideNotification> notifications;
  final List<SavedPlace> savedPlaces;
  final List<RidePoint> recentSearches;
  final bool isLoadingQuotes;
  final bool isSearchingDriver;
  final int trackingEtaMinutes;
  final List<String> nearbyLandmarks;
  final List<NearbyDriverPreview> nearbyDrivers;
  final RidePreferences preferences;
  final FareLock? fareLock;
  final double walletBalance;
  final int rewardPoints;
  final List<Compensation> compensationHistory;
  final List<TransactionRecord> transactions;
  final SafetyState safetyState;
  final List<String> quickMessages;

  const RideState({
    this.pickup,
    this.destination,
    this.quotes = const [],
    this.selectedQuote,
    this.paymentMethod = RiderPaymentMethod.cash,
    this.activeTrip,
    this.tripHistory = const [],
    this.notifications = const [],
    this.savedPlaces = const [],
    this.recentSearches = const [],
    this.isLoadingQuotes = false,
    this.isSearchingDriver = false,
    this.trackingEtaMinutes = 0,
    this.nearbyLandmarks = const [],
    this.nearbyDrivers = const [],
    this.preferences = const RidePreferences(),
    this.fareLock,
    this.walletBalance = 220.0,
    this.rewardPoints = 160,
    this.compensationHistory = const [],
    this.transactions = const [],
    this.safetyState = const SafetyState(),
    this.quickMessages = const [
      'I am at the main gate.',
      'Please call when you arrive.',
      'I will be there in 2 minutes.',
      'Please follow the map route.',
    ],
  });

  RideState copyWith({
    RidePoint? pickup,
    RidePoint? destination,
    List<RideTypeQuote>? quotes,
    RideTypeQuote? selectedQuote,
    RiderPaymentMethod? paymentMethod,
    RideTrip? activeTrip,
    List<RideTrip>? tripHistory,
    List<RideNotification>? notifications,
    List<SavedPlace>? savedPlaces,
    List<RidePoint>? recentSearches,
    bool? isLoadingQuotes,
    bool? isSearchingDriver,
    int? trackingEtaMinutes,
    List<String>? nearbyLandmarks,
    List<NearbyDriverPreview>? nearbyDrivers,
    RidePreferences? preferences,
    FareLock? fareLock,
    double? walletBalance,
    int? rewardPoints,
    List<Compensation>? compensationHistory,
    List<TransactionRecord>? transactions,
    SafetyState? safetyState,
    List<String>? quickMessages,
    bool clearSelectedQuote = false,
    bool clearActiveTrip = false,
    bool clearFareLock = false,
  }) {
    return RideState(
      pickup: pickup ?? this.pickup,
      destination: destination ?? this.destination,
      quotes: quotes ?? this.quotes,
      selectedQuote:
          clearSelectedQuote ? null : (selectedQuote ?? this.selectedQuote),
      paymentMethod: paymentMethod ?? this.paymentMethod,
      activeTrip: clearActiveTrip ? null : (activeTrip ?? this.activeTrip),
      tripHistory: tripHistory ?? this.tripHistory,
      notifications: notifications ?? this.notifications,
      savedPlaces: savedPlaces ?? this.savedPlaces,
      recentSearches: recentSearches ?? this.recentSearches,
      isLoadingQuotes: isLoadingQuotes ?? this.isLoadingQuotes,
      isSearchingDriver: isSearchingDriver ?? this.isSearchingDriver,
      trackingEtaMinutes: trackingEtaMinutes ?? this.trackingEtaMinutes,
      nearbyLandmarks: nearbyLandmarks ?? this.nearbyLandmarks,
      nearbyDrivers: nearbyDrivers ?? this.nearbyDrivers,
      preferences: preferences ?? this.preferences,
      fareLock: clearFareLock ? null : (fareLock ?? this.fareLock),
      walletBalance: walletBalance ?? this.walletBalance,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      compensationHistory: compensationHistory ?? this.compensationHistory,
      transactions: transactions ?? this.transactions,
      safetyState: safetyState ?? this.safetyState,
      quickMessages: quickMessages ?? this.quickMessages,
    );
  }
}

class RideController extends StateNotifier<RideState> {
  RideController(this._api) : super(_initialState());

  final MockRideApi _api;
  final _uuid = const Uuid();
  final _random = Random();
  Timer? _trackingTimer;
  Timer? _fareLockTimer;
  StreamSubscription<LocationData>? _liveLocationSubscription;

  static RideState _initialState() {
    return const RideState(
      savedPlaces: [
        SavedPlace(
          label: 'Home',
          point: RidePoint(
            latitude: 28.5562,
            longitude: 77.1000,
            address: 'Dwarka Sector 6, New Delhi',
          ),
        ),
        SavedPlace(
          label: 'Work',
          point: RidePoint(
            latitude: 28.5002,
            longitude: 77.0896,
            address: 'Cyber Hub, Gurugram',
          ),
        ),
      ],
    );
  }

  void setPickup(RidePoint pickup) {
    state = state.copyWith(
      pickup: pickup,
      nearbyLandmarks: _api.suggestLandmarks(pickup),
      clearFareLock: true,
      clearSelectedQuote: true,
    );
  }

  void setDestination(RidePoint destination) {
    state = state.copyWith(
      destination: destination,
      clearSelectedQuote: true,
      clearFareLock: true,
    );
  }

  void selectQuote(RideTypeQuote quote) {
    state = state.copyWith(
      selectedQuote: quote,
      nearbyDrivers: _api.nearestDrivers(quote.type),
    );
  }

  void selectPaymentMethod(RiderPaymentMethod method) {
    state = state.copyWith(paymentMethod: method);
  }

  void setGpsTrackingEnabled(bool enabled) {
    state = state.copyWith(
      safetyState: state.safetyState.copyWith(gpsTrackingEnabled: enabled),
    );
    if (!enabled) {
      _liveLocationSubscription?.cancel();
      _liveLocationSubscription = null;
    }
  }

  void setPrivacyModeEnabled(bool enabled) {
    state = state.copyWith(
      safetyState: state.safetyState.copyWith(privacyModeEnabled: enabled),
    );
  }

  void setPreciseLocationSharingEnabled(bool enabled) {
    state = state.copyWith(
      safetyState: state.safetyState.copyWith(
        preciseLocationSharingEnabled: enabled,
      ),
    );
  }

  void updatePreferences({
    bool? acRide,
    bool? silentRide,
    bool? musicOn,
  }) {
    state = state.copyWith(
      preferences: state.preferences.copyWith(
        acRide: acRide,
        silentRide: silentRide,
        musicOn: musicOn,
      ),
    );
  }

  Future<void> setPickupFromCurrentLocation(
    LocationService locationService,
  ) async {
    final current = await locationService.getCurrentLocationWithAddress();
    if (current == null) return;

    setPickup(
      RidePoint(
        latitude: current.latitude,
        longitude: current.longitude,
        address: current.address ?? 'Current Location',
      ),
    );
  }

  Future<void> startLiveLocationTracking(LocationService locationService) async {
    if (!state.safetyState.gpsTrackingEnabled) return;
    _liveLocationSubscription?.cancel();
    locationService.startTracking(distanceFilter: 8);
    _liveLocationSubscription = locationService.locationStream.listen((current) {
      if (!mounted) return;
      final pickup = RidePoint(
        latitude: current.latitude,
        longitude: current.longitude,
        address: current.address ?? 'Current Location',
      );
      state = state.copyWith(
        pickup: pickup,
        nearbyLandmarks: _api.suggestLandmarks(pickup),
        safetyState: state.safetyState.copyWith(
          lastLocationUpdatedAt: DateTime.now(),
        ),
      );
    });
  }

  void stopLiveLocationTracking(LocationService locationService) {
    _liveLocationSubscription?.cancel();
    _liveLocationSubscription = null;
    locationService.stopTracking();
  }

  Future<RidePoint?> resolveDestination(
    String query,
    LocationService locationService, {
    GoogleMapsService? mapsService,
  }) async {
    // First try Google Geocoding if API key is available (works on web)
    if (mapsService != null && mapsService.hasApiKey) {
      final gResult = await mapsService.geocodeAddress(query.trim());
      if (gResult != null) {
        return RidePoint(
          latitude: gResult.latitude,
          longitude: gResult.longitude,
          address: gResult.formattedAddress,
        );
      }
    }

    // Try device-level geocoder (may fail on web)
    try {
      final result = await locationService.getCoordinatesFromAddress(query.trim());
      if (result != null) {
        return RidePoint(
          latitude: result.latitude,
          longitude: result.longitude,
          address: result.address ?? query.trim(),
        );
      }
    } catch (_) {
      // Device geocoder not available (e.g., on web)
    }

    // Demo / offline fallback: match against built-in location database
    return _demoGeocode(query.trim());
  }

  /// Matches user input against a built-in database of known locations.
  /// Used as a last resort when Google API and device geocoder are unavailable.
  RidePoint? _demoGeocode(String query) {
    final normalized = query.toLowerCase();
    for (final entry in _knownLocations.entries) {
      if (entry.key.toLowerCase().contains(normalized) ||
          normalized.contains(entry.key.toLowerCase())) {
        return RidePoint(
          latitude: entry.value[0],
          longitude: entry.value[1],
          address: entry.key,
        );
      }
    }
    // Partial match: check if any word in the query matches a location keyword
    final words = normalized.split(RegExp(r'[\s,]+'));
    for (final word in words) {
      if (word.length < 3) continue;
      for (final entry in _knownLocations.entries) {
        if (entry.key.toLowerCase().contains(word)) {
          return RidePoint(
            latitude: entry.value[0],
            longitude: entry.value[1],
            address: entry.key,
          );
        }
      }
    }
    return null;
  }

  static const _knownLocations = <String, List<double>>{
    // Major Indian cities
    'Mumbai, Maharashtra': [19.0760, 72.8777],
    'Delhi, India': [28.6139, 77.2090],
    'Bangalore, Karnataka': [12.9716, 77.5946],
    'Hyderabad, Telangana': [17.3850, 78.4867],
    'Ahmedabad, Gujarat': [23.0225, 72.5714],
    'Chennai, Tamil Nadu': [13.0827, 80.2707],
    'Kolkata, West Bengal': [22.5726, 88.3639],
    'Pune, Maharashtra': [18.5204, 73.8567],
    'Jaipur, Rajasthan': [26.9124, 75.7873],
    'Lucknow, Uttar Pradesh': [26.8467, 80.9462],
    'Kanpur, Uttar Pradesh': [26.4499, 80.3319],
    'Nagpur, Maharashtra': [21.1458, 79.0882],
    'Indore, Madhya Pradesh': [22.7196, 75.8577],
    'Thane, Maharashtra': [19.2183, 72.9781],
    'Bhopal, Madhya Pradesh': [23.2599, 77.4126],
    'Patna, Bihar': [25.6093, 85.1376],
    'Vadodara, Gujarat': [22.3072, 73.1812],
    'Goa, India': [15.2993, 74.1240],
    'Surat, Gujarat': [21.1702, 72.8311],
    'Coimbatore, Tamil Nadu': [11.0168, 76.9558],
    'Kochi, Kerala': [9.9312, 76.2673],
    'Chandigarh, India': [30.7333, 76.7794],
    'Noida, Uttar Pradesh': [28.5355, 77.3910],
    'Gurugram, Haryana': [28.4595, 77.0266],
    'Ghaziabad, Uttar Pradesh': [28.6692, 77.4538],
    // Maharashtra towns
    'Akluj, Maharashtra': [17.8844, 75.0227],
    'Solapur, Maharashtra': [17.6599, 75.9064],
    'Satara, Maharashtra': [17.6805, 74.0183],
    'Sangli, Maharashtra': [16.8524, 74.5815],
    'Kolhapur, Maharashtra': [16.7050, 74.2433],
    'Nashik, Maharashtra': [19.9975, 73.7898],
    'Aurangabad, Maharashtra': [19.8762, 75.3433],
    // Delhi NCR landmarks
    'India Gate, New Delhi': [28.6129, 77.2295],
    'Connaught Place, New Delhi': [28.6315, 77.2167],
    'Airport Terminal 3, New Delhi': [28.5562, 77.1000],
    'Cyber Hub, Gurugram': [28.4945, 77.0885],
    'Rajiv Chowk Metro Station, New Delhi': [28.6328, 77.2198],
    'New Delhi Railway Station': [28.6425, 77.2195],
    'Dwarka Sector 6, New Delhi': [28.5562, 77.1000],
    'Nehru Place, New Delhi': [28.5491, 77.2533],
    'Hauz Khas Village, New Delhi': [28.5494, 77.2001],
    'Saket Mall, New Delhi': [28.5244, 77.2167],
  };

  Future<RidePoint?> setPickupFromMapOffset({
    required double horizontalOffset,
    required double verticalOffset,
    required LocationService locationService,
  }) async {
    final anchor = state.pickup;
    if (anchor == null) return null;

    final adjustedLatitude = anchor.latitude - (verticalOffset * 0.04);
    final adjustedLongitude = anchor.longitude + (horizontalOffset * 0.04);
    final resolved = await locationService.getAddressFromCoordinates(
      adjustedLatitude,
      adjustedLongitude,
    );
    final pickup = RidePoint(
      latitude: resolved.latitude,
      longitude: resolved.longitude,
      address: resolved.address ?? anchor.address,
    );
    setPickup(pickup);
    return pickup;
  }

  Future<void> loadQuotes() async {
    if (state.pickup == null || state.destination == null) return;

    final distanceKm = _calcDistanceKm(state.pickup!, state.destination!);
    state = state.copyWith(
      isLoadingQuotes: true,
      clearSelectedQuote: true,
      clearFareLock: true,
    );
    final quotes = await _api.fetchQuotes(distanceKm: distanceKm);
    state = state.copyWith(
      isLoadingQuotes: false,
      quotes: quotes,
      nearbyDrivers: quotes.isEmpty ? [] : _api.nearestDrivers(quotes.first.type),
    );
  }

  void lockFare() {
    final quote = state.selectedQuote;
    if (quote == null) return;

    _fareLockTimer?.cancel();
    final lock = FareLock(
      lockedFare: quote.fare,
      lockedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
    );
    state = state.copyWith(fareLock: lock);
    _pushNotification(
      'Fare locked',
      'Your ${quote.label} fare is locked for 5 minutes.',
    );
    _fareLockTimer = Timer(const Duration(minutes: 5), () {
      if (!mounted) return;
      state = state.copyWith(clearFareLock: true);
      _pushNotification('Fare lock expired', 'Fare lock has expired.');
    });
  }

  Future<String?> requestRide({bool quickBook = false}) async {
    final quote = state.selectedQuote ?? (quickBook ? state.quotes.firstOrNull : null);
    final pickup = state.pickup;
    final destination = state.destination;
    if (quote == null || pickup == null || destination == null) {
      return null;
    }

    selectQuote(quote);
    _cancelTimers();
    state = state.copyWith(
      isSearchingDriver: true,
      safetyState: state.safetyState.copyWith(
        routeDeviationDetected: false,
        clearRouteAlert: true,
      ),
    );
    _pushNotification(
      'Searching for a driver',
      '${quote.label} request created. Choosing the best nearby driver.',
    );

    final driver = await _api.matchDriver(quote.type);
    if (!mounted) return null;

    final tripId = _uuid.v4();
    final distance = _calcDistanceKm(pickup, destination);
    final duration = max(8, (distance * 3.4).round());
    final arrivingEta = max(2, driver.etaMinutes);
    final effectiveFare = state.fareLock?.isActive == true
        ? state.fareLock!.lockedFare
        : quote.fare;
    final effectiveBreakdown = quote.breakdown.total == effectiveFare
        ? quote.breakdown
        : FareBreakdown(
            baseFare: quote.breakdown.baseFare,
            distanceFare: quote.breakdown.distanceFare,
            timeFare: quote.breakdown.timeFare,
            surgeMultiplier: quote.breakdown.surgeMultiplier,
            surgeAmount: quote.breakdown.surgeAmount,
            platformFee: quote.breakdown.platformFee,
            tax: max(0, effectiveFare - quote.breakdown.baseFare - quote.breakdown.distanceFare - quote.breakdown.timeFare - quote.breakdown.surgeAmount - quote.breakdown.platformFee),
            total: effectiveFare,
          );

    final trip = RideTrip(
      id: tripId,
      pickup: pickup,
      destination: destination,
      rideType: quote.type,
      paymentMethod: state.paymentMethod,
      distanceKm: distance,
      durationMinutes: duration,
      fare: effectiveFare,
      fareBreakdown: effectiveBreakdown,
      status: RideLifecycleStatus.arriving,
      driver: driver,
      fareLock: state.fareLock?.isActive == true ? state.fareLock : null,
      preferences: state.preferences,
      sharedContacts: state.safetyState.sharedContacts,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      activeTrip: trip,
      isSearchingDriver: false,
      trackingEtaMinutes: arrivingEta,
    );
    _pushNotification(
      'Driver assigned',
      '${driver.name} is arriving in $arrivingEta min.',
    );
    _startTrackingSimulation();

    return tripId;
  }

  void sendQuickMessage(String message) {
    final active = state.activeTrip;
    if (active == null) return;
    _pushNotification(
      'Message sent to ${active.driver?.name ?? 'driver'}',
      message,
    );
  }

  void shareTripWithContacts() {
    final active = state.activeTrip;
    if (active == null) return;
    _pushNotification(
      'Trip shared',
      'Live trip shared with ${active.sharedContacts.join(', ')}.',
    );
  }

  void triggerSos() {
    state = state.copyWith(
      safetyState: state.safetyState.copyWith(sosActive: true),
    );
    _pushNotification(
      'Emergency SOS activated',
      'Live trip and location shared with trusted contacts and support.',
    );
  }

  void clearSos() {
    state = state.copyWith(
      safetyState: state.safetyState.copyWith(sosActive: false),
    );
  }

  void clearRouteAlert() {
    state = state.copyWith(
      safetyState: state.safetyState.copyWith(
        routeDeviationDetected: false,
        clearRouteAlert: true,
      ),
    );
  }

  void cancelActiveRide() {
    final active = state.activeTrip;
    if (active == null) return;

    _cancelTimers();
    final cancelled = active.copyWith(status: RideLifecycleStatus.cancelled);
    state = state.copyWith(
      tripHistory: [cancelled, ...state.tripHistory],
      clearActiveTrip: true,
      trackingEtaMinutes: 0,
    );
    _pushNotification('Ride cancelled', 'Your ride was cancelled.');
  }

  void clearActiveRide() {
    _cancelTimers();
    state = state.copyWith(clearActiveTrip: true, trackingEtaMinutes: 0);
  }

  Future<void> quickBookSavedPlace(SavedPlace place) async {
    setDestination(place.point);
    addRecentSearch(place.point);
    await loadQuotes();
    if (state.quotes.isNotEmpty) {
      selectQuote(state.quotes.first);
    }
  }

  void addRecentSearch(RidePoint point) {
    final updated = [
      point,
      ...state.recentSearches.where((item) => !item.sameAddressAs(point)),
    ].take(5).toList();
    state = state.copyWith(recentSearches: updated);
  }

  void redeemRewardPoints() {
    if (state.rewardPoints < 100) return;
    state = state.copyWith(
      rewardPoints: state.rewardPoints - 100,
      walletBalance: state.walletBalance + 75,
    );
    final compensation = Compensation(
      type: CompensationType.discount,
      amount: 75,
      reason: 'Redeemed 100 reward points.',
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      compensationHistory: [compensation, ...state.compensationHistory],
    );
    _pushNotification(
      'Rewards redeemed',
      'Rs 75 ride credit added to your wallet.',
    );
  }

  void _startTrackingSimulation() {
    int elapsed = 0;
    _trackingTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      final active = state.activeTrip;
      if (active == null) {
        timer.cancel();
        return;
      }

      elapsed += 1;
      if (active.status == RideLifecycleStatus.arriving) {
        if (active.driver != null &&
            _api.shouldDriverCancel(
              active.driver!,
              reassignmentCount: active.reassignmentCount,
            )) {
          _reassignDriver(active);
          return;
        }

        final eta = max(1, state.trackingEtaMinutes - 1);
        state = state.copyWith(trackingEtaMinutes: eta);

        if (eta <= 1 || elapsed >= 3) {
          final updated = active.copyWith(
            status: RideLifecycleStatus.inProgress,
          );
          state = state.copyWith(
            activeTrip: updated,
            trackingEtaMinutes: active.durationMinutes,
          );
          _pushNotification('Trip started', 'Your ride is now in progress.');
        }
        return;
      }

      if (active.status == RideLifecycleStatus.inProgress) {
        final nextEta = max(0, state.trackingEtaMinutes - 2);
        state = state.copyWith(trackingEtaMinutes: nextEta);

        if (!active.routeDeviationDetected &&
            elapsed >= 5 &&
            _api.shouldFlagRouteDeviation()) {
          const alert =
              'Driver is off the suggested route. Review before continuing.';
          state = state.copyWith(
            activeTrip: active.copyWith(routeDeviationDetected: true),
            safetyState: state.safetyState.copyWith(
              routeDeviationDetected: true,
              routeAlert: alert,
            ),
          );
          _pushNotification('Route deviation detected', alert);
        }

        if (nextEta == 0 || elapsed >= 10) {
          _completeActiveRide();
          timer.cancel();
        }
      }
    });
  }

  void _reassignDriver(RideTrip active) {
    final currentDriver = active.driver;
    if (currentDriver == null) return;

    final compensation = _api.registerDriverCancellation(currentDriver);
    final replacement =
        _api.reassignDriver(active.rideType, currentDriver.id);
    if (replacement == null) {
      cancelActiveRide();
      return;
    }

    state = state.copyWith(
      walletBalance: state.walletBalance + compensation.amount,
      compensationHistory: [compensation, ...state.compensationHistory],
      activeTrip: active.copyWith(
        driver: replacement,
        reassignmentCount: active.reassignmentCount + 1,
        compensations: [compensation, ...active.compensations],
      ),
      trackingEtaMinutes: replacement.etaMinutes,
    );

    final restrictionNote = _api.isDriverRestricted(currentDriver.id)
        ? ' Frequent offender automatically restricted.'
        : '';
    _pushNotification(
      'Driver cancelled, reassigning',
      '${currentDriver.name} cancelled. ${replacement.name} is on the way. Rs ${compensation.amount.toStringAsFixed(0)} credited.$restrictionNote',
    );
  }

  void _completeActiveRide() {
    final active = state.activeTrip;
    if (active == null) return;

    final rewardPointsEarned = max(12, (active.fare / 18).round());
    final paymentFailed = _api.shouldPaymentFail(active.paymentMethod);
    final paidAmount = paymentFailed ? 0.0 : active.fare;
    final refundedAmount = paymentFailed ? active.fare : 0.0;
    final paymentStatus =
        paymentFailed ? TransactionStatus.refunded : TransactionStatus.success;

    final receipt = _api.createReceipt(
      rideId: active.id,
      breakdown: active.fareBreakdown,
      paymentMethod: active.paymentMethod,
      paymentStatus: paymentStatus,
      paidAmount: paidAmount,
      refundedAmount: refundedAmount,
      rewardPointsEarned: rewardPointsEarned,
    );

    final updatedTransactions = [
      TransactionRecord(
        id: _uuid.v4(),
        title: 'Ride payment',
        subtitle: active.destination.address,
        amount: active.fare,
        method: active.paymentMethod,
        status: paymentFailed ? TransactionStatus.failed : TransactionStatus.success,
        createdAt: DateTime.now(),
      ),
      if (paymentFailed)
        TransactionRecord(
          id: _uuid.v4(),
          title: 'Instant refund',
          subtitle: 'Refund for failed ${active.paymentMethod.name.toUpperCase()} payment',
          amount: active.fare,
          method: RiderPaymentMethod.wallet,
          status: TransactionStatus.refunded,
          createdAt: DateTime.now(),
        ),
      ...state.transactions,
    ];

    final completed = active.copyWith(
      status: RideLifecycleStatus.completed,
      rewardPointsEarned: rewardPointsEarned,
      receipt: receipt,
    );

    state = state.copyWith(
      activeTrip: completed,
      tripHistory: [completed, ...state.tripHistory],
      trackingEtaMinutes: 0,
      rewardPoints: state.rewardPoints + rewardPointsEarned,
      walletBalance:
          state.walletBalance + (paymentFailed ? active.fare : 0.0),
      transactions: updatedTransactions,
    );
    _pushNotification(
      paymentFailed ? 'Payment refunded' : 'Payment successful',
      paymentFailed
          ? 'Payment failed and an instant wallet refund was issued.'
          : 'Ride completed. $rewardPointsEarned loyalty points added.',
    );
  }

  void saveCustomPlace(String label, RidePoint point) {
    final updated = [...state.savedPlaces, SavedPlace(label: label, point: point)];
    state = state.copyWith(savedPlaces: updated);
  }

  void _pushNotification(String title, String body) {
    final notification = RideNotification(
      id: _uuid.v4(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(notifications: [notification, ...state.notifications]);
  }

  double _calcDistanceKm(RidePoint from, RidePoint to) {
    final latDiff = (to.latitude - from.latitude).abs();
    final lngDiff = (to.longitude - from.longitude).abs();
    final rough = sqrt((latDiff * latDiff) + (lngDiff * lngDiff)) * 111;
    final randomVariance = 0.92 + (_random.nextDouble() * 0.25);
    return max(1.2, rough * randomVariance);
  }

  void _cancelTimers() {
    _trackingTimer?.cancel();
    _trackingTimer = null;
  }

  @override
  void dispose() {
    _fareLockTimer?.cancel();
    _liveLocationSubscription?.cancel();
    _cancelTimers();
    super.dispose();
  }
}

final mockRideApiProvider = Provider<MockRideApi>((ref) {
  return MockRideApi();
});

final rideControllerProvider = StateNotifierProvider<RideController, RideState>(
  (ref) {
    final api = ref.watch(mockRideApiProvider);
    return RideController(api);
  },
);
