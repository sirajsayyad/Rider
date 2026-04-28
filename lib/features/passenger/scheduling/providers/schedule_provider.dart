import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/schedule_models.dart';

class ScheduleState {
  final List<ScheduledRide> scheduledRides;
  final DateTime selectedDate;
  final TimeSlot? selectedSlot;
  final List<TimeSlot> availableSlots;
  final bool isLoading;
  final String? error;

  const ScheduleState({
    this.scheduledRides = const [],
    required this.selectedDate,
    this.selectedSlot,
    this.availableSlots = const [],
    this.isLoading = false,
    this.error,
  });

  ScheduleState copyWith({
    List<ScheduledRide>? scheduledRides,
    DateTime? selectedDate,
    TimeSlot? selectedSlot,
    List<TimeSlot>? availableSlots,
    bool? isLoading,
    String? error,
    bool clearSlot = false,
  }) {
    return ScheduleState(
      scheduledRides: scheduledRides ?? this.scheduledRides,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedSlot: clearSlot ? null : (selectedSlot ?? this.selectedSlot),
      availableSlots: availableSlots ?? this.availableSlots,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<ScheduledRide> get upcomingRides =>
      scheduledRides.where((r) => r.status == ScheduleStatus.upcoming || r.status == ScheduleStatus.confirmed).toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
}

class ScheduleController extends StateNotifier<ScheduleState> {
  ScheduleController()
      : super(ScheduleState(
          selectedDate: DateTime.now().add(const Duration(days: 1)),
        )) {
    _generateSlots(state.selectedDate);
    _startReminderChecker();
  }

  final _uuid = const Uuid();
  final _random = Random();
  Timer? _reminderTimer;

  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: date, clearSlot: true);
    _generateSlots(date);
  }

  void selectSlot(TimeSlot slot) {
    state = state.copyWith(selectedSlot: slot);
  }

  void _generateSlots(DateTime date) {
    final slots = <TimeSlot>[];
    final startHour = date.day == DateTime.now().day ? DateTime.now().hour + 1 : 6;
    for (int h = startHour; h <= 22; h++) {
      for (int m = 0; m < 60; m += 30) {
        final time = DateTime(date.year, date.month, date.day, h, m);
        slots.add(TimeSlot(
          time: time,
          isAvailable: _random.nextBool() || _random.nextBool(),
          availableDrivers: _random.nextInt(8) + 1,
        ));
      }
    }
    state = state.copyWith(availableSlots: slots);
  }

  Future<ScheduledRide?> scheduleRide({
    required String pickupAddress,
    required double pickupLat,
    required double pickupLng,
    required String destinationAddress,
    required double destLat,
    required double destLng,
    required String rideType,
    required double estimatedFare,
  }) async {
    final slot = state.selectedSlot;
    if (slot == null) return null;

    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 800));

    final ride = ScheduledRide(
      id: _uuid.v4(),
      scheduledAt: slot.time,
      pickupAddress: pickupAddress,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      destinationAddress: destinationAddress,
      destLat: destLat,
      destLng: destLng,
      rideType: rideType,
      estimatedFare: estimatedFare,
      status: ScheduleStatus.upcoming,
      createdAt: DateTime.now(),
    );

    // Simulate auto-assignment after a delay
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      final driverNames = ['Ravi Kumar', 'Vikram Singh', 'Amit Patel', 'Suresh Reddy'];
      final assigned = ride.copyWith(
        status: ScheduleStatus.confirmed,
        assignedDriverName: driverNames[_random.nextInt(driverNames.length)],
        assignedDriverId: 'driver_${_random.nextInt(100)}',
      );
      state = state.copyWith(
        scheduledRides: state.scheduledRides
            .map((r) => r.id == ride.id ? assigned : r)
            .toList(),
      );
    });

    state = state.copyWith(
      scheduledRides: [...state.scheduledRides, ride],
      isLoading: false,
      clearSlot: true,
    );

    return ride;
  }

  void cancelScheduledRide(String rideId) {
    state = state.copyWith(
      scheduledRides: state.scheduledRides
          .map((r) => r.id == rideId
              ? r.copyWith(status: ScheduleStatus.cancelled)
              : r)
          .toList(),
    );
  }

  void _startReminderChecker() {
    _reminderTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      final updated = state.scheduledRides.map((ride) {
        if (!ride.reminderSent &&
            ride.status == ScheduleStatus.confirmed &&
            ride.timeUntilPickup.inMinutes <= 15 &&
            ride.timeUntilPickup.inMinutes > 0) {
          return ride.copyWith(reminderSent: true);
        }
        return ride;
      }).toList();
      state = state.copyWith(scheduledRides: updated);
    });
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    super.dispose();
  }
}

final scheduleControllerProvider =
    StateNotifierProvider<ScheduleController, ScheduleState>((ref) {
  return ScheduleController();
});
