import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../passenger/ride/domain/ride_models.dart';

/// State and controller for Feature 3: Multi-Stop Rides

class MultiStopState {
  final List<RidePoint> stops;
  final Map<int, double> legFares;
  final Map<int, int> legEtaMinutes;
  final double totalFare;
  final int totalEtaMinutes;
  final double totalDistanceKm;
  final bool isCalculating;

  const MultiStopState({
    this.stops = const [],
    this.legFares = const {},
    this.legEtaMinutes = const {},
    this.totalFare = 0,
    this.totalEtaMinutes = 0,
    this.totalDistanceKm = 0,
    this.isCalculating = false,
  });

  MultiStopState copyWith({
    List<RidePoint>? stops,
    Map<int, double>? legFares,
    Map<int, int>? legEtaMinutes,
    double? totalFare,
    int? totalEtaMinutes,
    double? totalDistanceKm,
    bool? isCalculating,
  }) {
    return MultiStopState(
      stops: stops ?? this.stops,
      legFares: legFares ?? this.legFares,
      legEtaMinutes: legEtaMinutes ?? this.legEtaMinutes,
      totalFare: totalFare ?? this.totalFare,
      totalEtaMinutes: totalEtaMinutes ?? this.totalEtaMinutes,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      isCalculating: isCalculating ?? this.isCalculating,
    );
  }

  bool get canAddStop => stops.length < 3;
  int get stopCount => stops.length;
}

class MultiStopController extends StateNotifier<MultiStopState> {
  MultiStopController() : super(const MultiStopState());

  final _random = Random();

  void addStop(RidePoint stop) {
    if (!state.canAddStop) return;
    final updated = [...state.stops, stop];
    state = state.copyWith(stops: updated);
    _recalculateFares();
  }

  void removeStop(int index) {
    if (index < 0 || index >= state.stops.length) return;
    final updated = [...state.stops]..removeAt(index);
    state = state.copyWith(stops: updated);
    _recalculateFares();
  }

  void reorderStops(int oldIndex, int newIndex) {
    final stops = [...state.stops];
    if (newIndex > oldIndex) newIndex--;
    final item = stops.removeAt(oldIndex);
    stops.insert(newIndex, item);
    state = state.copyWith(stops: stops);
    _recalculateFares();
  }

  void updateStop(int index, RidePoint newStop) {
    if (index < 0 || index >= state.stops.length) return;
    final stops = [...state.stops];
    stops[index] = newStop;
    state = state.copyWith(stops: stops);
    _recalculateFares();
  }

  void clearStops() {
    state = const MultiStopState();
  }

  void _recalculateFares() {
    if (state.stops.isEmpty) {
      state = state.copyWith(
        legFares: {},
        legEtaMinutes: {},
        totalFare: 0,
        totalEtaMinutes: 0,
        totalDistanceKm: 0,
      );
      return;
    }

    state = state.copyWith(isCalculating: true);

    // Simulate per-leg fare calculation
    final legFares = <int, double>{};
    final legEtas = <int, int>{};
    double totalFare = 0;
    int totalEta = 0;
    double totalDistance = 0;

    for (int i = 0; i <= state.stops.length; i++) {
      final legDistance = 2.0 + _random.nextDouble() * 6;
      final legFare = 25 + legDistance * 12;
      final legEta = max(5, (legDistance * 3.2).round());
      legFares[i] = legFare;
      legEtas[i] = legEta;
      totalFare += legFare;
      totalEta += legEta;
      totalDistance += legDistance;
    }

    state = state.copyWith(
      legFares: legFares,
      legEtaMinutes: legEtas,
      totalFare: totalFare,
      totalEtaMinutes: totalEta,
      totalDistanceKm: totalDistance,
      isCalculating: false,
    );
  }
}

final multiStopControllerProvider =
    StateNotifierProvider<MultiStopController, MultiStopState>((ref) {
  return MultiStopController();
});
