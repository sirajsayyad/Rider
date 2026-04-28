/// Schedule models for Feature 2: Ride Scheduling

enum ScheduleStatus { upcoming, confirmed, completed, cancelled }

class ScheduledRide {
  final String id;
  final DateTime scheduledAt;
  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final String destinationAddress;
  final double destLat;
  final double destLng;
  final String rideType;
  final double estimatedFare;
  final ScheduleStatus status;
  final String? assignedDriverId;
  final String? assignedDriverName;
  final bool reminderSent;
  final DateTime createdAt;

  const ScheduledRide({
    required this.id,
    required this.scheduledAt,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.destinationAddress,
    required this.destLat,
    required this.destLng,
    required this.rideType,
    required this.estimatedFare,
    this.status = ScheduleStatus.upcoming,
    this.assignedDriverId,
    this.assignedDriverName,
    this.reminderSent = false,
    required this.createdAt,
  });

  ScheduledRide copyWith({
    ScheduleStatus? status,
    String? assignedDriverId,
    String? assignedDriverName,
    bool? reminderSent,
  }) {
    return ScheduledRide(
      id: id,
      scheduledAt: scheduledAt,
      pickupAddress: pickupAddress,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      destinationAddress: destinationAddress,
      destLat: destLat,
      destLng: destLng,
      rideType: rideType,
      estimatedFare: estimatedFare,
      status: status ?? this.status,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      assignedDriverName: assignedDriverName ?? this.assignedDriverName,
      reminderSent: reminderSent ?? this.reminderSent,
      createdAt: createdAt,
    );
  }

  bool get isPast => DateTime.now().isAfter(scheduledAt);
  Duration get timeUntilPickup => scheduledAt.difference(DateTime.now());
}

class TimeSlot {
  final DateTime time;
  final bool isAvailable;
  final int availableDrivers;

  const TimeSlot({
    required this.time,
    this.isAvailable = true,
    this.availableDrivers = 0,
  });
}
