import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Feature 8: Ride Pooling / Carpool

class CoPassenger {
  final String id;
  final String name;
  final String pickupAddress;
  final String dropAddress;
  final int pickupSequence;
  final double rating;

  const CoPassenger({
    required this.id,
    required this.name,
    required this.pickupAddress,
    required this.dropAddress,
    required this.pickupSequence,
    required this.rating,
  });
}

class PoolRide {
  final String id;
  final int maxPassengers;
  final int currentPassengers;
  final List<CoPassenger> coPassengers;
  final double discountPercent;
  final double originalFare;
  final double poolFare;
  final bool isMatched;

  const PoolRide({
    required this.id,
    this.maxPassengers = 3,
    this.currentPassengers = 1,
    this.coPassengers = const [],
    this.discountPercent = 25,
    required this.originalFare,
    required this.poolFare,
    this.isMatched = false,
  });

  PoolRide copyWith({
    int? currentPassengers,
    List<CoPassenger>? coPassengers,
    bool? isMatched,
    double? poolFare,
  }) {
    return PoolRide(
      id: id,
      maxPassengers: maxPassengers,
      currentPassengers: currentPassengers ?? this.currentPassengers,
      coPassengers: coPassengers ?? this.coPassengers,
      discountPercent: discountPercent,
      originalFare: originalFare,
      poolFare: poolFare ?? this.poolFare,
      isMatched: isMatched ?? this.isMatched,
    );
  }

  double get savings => originalFare - poolFare;
}

class PoolState {
  final bool poolEnabled;
  final PoolRide? activePool;
  final bool isSearchingMatch;
  final List<PoolRide> poolHistory;

  const PoolState({
    this.poolEnabled = false,
    this.activePool,
    this.isSearchingMatch = false,
    this.poolHistory = const [],
  });

  PoolState copyWith({
    bool? poolEnabled,
    PoolRide? activePool,
    bool? isSearchingMatch,
    List<PoolRide>? poolHistory,
    bool clearPool = false,
  }) {
    return PoolState(
      poolEnabled: poolEnabled ?? this.poolEnabled,
      activePool: clearPool ? null : (activePool ?? this.activePool),
      isSearchingMatch: isSearchingMatch ?? this.isSearchingMatch,
      poolHistory: poolHistory ?? this.poolHistory,
    );
  }
}

class PoolController extends StateNotifier<PoolState> {
  PoolController() : super(const PoolState());

  final _random = Random();

  void togglePoolMode(bool enabled) {
    state = state.copyWith(poolEnabled: enabled);
  }

  double calculatePoolFare(double originalFare) {
    return originalFare * 0.75; // 25% discount
  }

  Future<void> findPoolMatch(double originalFare) async {
    state = state.copyWith(isSearchingMatch: true);

    // Create pool ride
    final pool = PoolRide(
      id: 'pool_${DateTime.now().millisecondsSinceEpoch}',
      originalFare: originalFare,
      poolFare: calculatePoolFare(originalFare),
    );
    state = state.copyWith(activePool: pool);

    // Simulate finding co-passengers
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final names = ['Anita K.', 'Suresh M.', 'Kavita R.', 'Deepak S.'];
    final pickups = ['Sector 18 Metro', 'Wave Mall', 'City Center', 'GIP Mall'];
    final drops = ['DLF Phase 3', 'Cyber Hub', 'IFFCO Chowk', 'Huda City'];

    final matchCount = _random.nextInt(2) + 1;
    final coPassengers = List.generate(matchCount, (i) {
      return CoPassenger(
        id: 'co_$i',
        name: names[_random.nextInt(names.length)],
        pickupAddress: pickups[_random.nextInt(pickups.length)],
        dropAddress: drops[_random.nextInt(drops.length)],
        pickupSequence: i + 1,
        rating: 4.0 + _random.nextDouble(),
      );
    });

    final matchedPool = pool.copyWith(
      coPassengers: coPassengers,
      currentPassengers: matchCount + 1,
      isMatched: true,
      poolFare: originalFare * (0.75 - matchCount * 0.05),
    );

    state = state.copyWith(
      activePool: matchedPool,
      isSearchingMatch: false,
    );
  }

  void cancelPool() {
    state = state.copyWith(clearPool: true, poolEnabled: false, isSearchingMatch: false);
  }
}

final poolControllerProvider =
    StateNotifierProvider<PoolController, PoolState>((ref) {
  return PoolController();
});
