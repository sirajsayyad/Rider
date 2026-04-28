import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Feature 12: Lost & Found Module

enum LostFoundStatus { reported, searching, matched, contactInitiated, returned, closed }

enum ItemCategory { phone, wallet, bag, keys, clothing, documents, electronics, other }

class LostFoundItem {
  final String id;
  final String description;
  final ItemCategory category;
  final String? rideId;
  final String? rideDate;
  final String reporterName;
  final String reporterPhone;
  final LostFoundStatus status;
  final bool isLost; // true = passenger lost, false = driver found
  final String? matchedWithId;
  final String? matchedDriverName;
  final DateTime reportedAt;
  final DateTime? resolvedAt;
  final List<LostFoundUpdate> updates;

  const LostFoundItem({
    required this.id,
    required this.description,
    required this.category,
    this.rideId,
    this.rideDate,
    required this.reporterName,
    required this.reporterPhone,
    this.status = LostFoundStatus.reported,
    required this.isLost,
    this.matchedWithId,
    this.matchedDriverName,
    required this.reportedAt,
    this.resolvedAt,
    this.updates = const [],
  });

  LostFoundItem copyWith({
    LostFoundStatus? status,
    String? matchedWithId,
    String? matchedDriverName,
    DateTime? resolvedAt,
    List<LostFoundUpdate>? updates,
  }) {
    return LostFoundItem(
      id: id,
      description: description,
      category: category,
      rideId: rideId,
      rideDate: rideDate,
      reporterName: reporterName,
      reporterPhone: reporterPhone,
      status: status ?? this.status,
      isLost: isLost,
      matchedWithId: matchedWithId ?? this.matchedWithId,
      matchedDriverName: matchedDriverName ?? this.matchedDriverName,
      reportedAt: reportedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      updates: updates ?? this.updates,
    );
  }
}

class LostFoundUpdate {
  final String title;
  final String description;
  final DateTime timestamp;
  final LostFoundStatus status;

  const LostFoundUpdate({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.status,
  });
}

class LostFoundState {
  final List<LostFoundItem> items;
  final bool isLoading;
  final String? error;

  const LostFoundState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  LostFoundState copyWith({
    List<LostFoundItem>? items,
    bool? isLoading,
    String? error,
  }) {
    return LostFoundState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<LostFoundItem> get activeItems =>
      items.where((i) => i.status != LostFoundStatus.closed && i.status != LostFoundStatus.returned).toList();

  List<LostFoundItem> get resolvedItems =>
      items.where((i) => i.status == LostFoundStatus.closed || i.status == LostFoundStatus.returned).toList();
}

class LostFoundController extends StateNotifier<LostFoundState> {
  LostFoundController() : super(const LostFoundState()) {
    _loadDemoData();
  }

  final _random = Random();

  void _loadDemoData() {
    state = state.copyWith(
      items: [
        LostFoundItem(
          id: 'lf_1',
          description: 'Black leather wallet with ID cards',
          category: ItemCategory.wallet,
          rideId: 'ride_089',
          rideDate: 'Apr 22, 2026',
          reporterName: 'You',
          reporterPhone: '+91 98XXXX1234',
          status: LostFoundStatus.matched,
          isLost: true,
          matchedDriverName: 'Ravi Kumar',
          reportedAt: DateTime.now().subtract(const Duration(days: 1)),
          updates: [
            LostFoundUpdate(
              title: 'Item Reported',
              description: 'You reported a lost wallet from ride #089.',
              timestamp: DateTime.now().subtract(const Duration(days: 1)),
              status: LostFoundStatus.reported,
            ),
            LostFoundUpdate(
              title: 'Driver Contacted',
              description: 'Driver Ravi Kumar has been contacted and confirmed finding your wallet.',
              timestamp: DateTime.now().subtract(const Duration(hours: 20)),
              status: LostFoundStatus.matched,
            ),
          ],
        ),
        LostFoundItem(
          id: 'lf_2',
          description: 'Blue umbrella left in backseat',
          category: ItemCategory.other,
          rideId: 'ride_075',
          rideDate: 'Apr 18, 2026',
          reporterName: 'You',
          reporterPhone: '+91 98XXXX1234',
          status: LostFoundStatus.returned,
          isLost: true,
          matchedDriverName: 'Amit Singh',
          reportedAt: DateTime.now().subtract(const Duration(days: 5)),
          resolvedAt: DateTime.now().subtract(const Duration(days: 3)),
          updates: [
            LostFoundUpdate(
              title: 'Item Reported', description: 'You reported a lost umbrella.',
              timestamp: DateTime.now().subtract(const Duration(days: 5)),
              status: LostFoundStatus.reported,
            ),
            LostFoundUpdate(
              title: 'Item Found', description: 'Driver Amit Singh found your umbrella.',
              timestamp: DateTime.now().subtract(const Duration(days: 4)),
              status: LostFoundStatus.matched,
            ),
            LostFoundUpdate(
              title: 'Item Returned', description: 'Your umbrella was successfully returned.',
              timestamp: DateTime.now().subtract(const Duration(days: 3)),
              status: LostFoundStatus.returned,
            ),
          ],
        ),
      ],
    );
  }

  Future<LostFoundItem?> reportLostItem({
    required String description,
    required ItemCategory category,
    String? rideId,
    String? rideDate,
  }) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 600));

    final item = LostFoundItem(
      id: 'lf_${DateTime.now().millisecondsSinceEpoch}',
      description: description,
      category: category,
      rideId: rideId,
      rideDate: rideDate,
      reporterName: 'You',
      reporterPhone: '+91 98XXXX1234',
      isLost: true,
      reportedAt: DateTime.now(),
      updates: [
        LostFoundUpdate(
          title: 'Item Reported',
          description: 'Your lost item report has been submitted. We\'ll contact the driver.',
          timestamp: DateTime.now(),
          status: LostFoundStatus.reported,
        ),
      ],
    );

    state = state.copyWith(
      items: [item, ...state.items],
      isLoading: false,
    );

    // Simulate driver found match after delay
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      final driverNames = ['Ravi Kumar', 'Suresh Reddy', 'Vikram Patel'];
      final matched = item.copyWith(
        status: LostFoundStatus.matched,
        matchedDriverName: driverNames[_random.nextInt(driverNames.length)],
        updates: [
          ...item.updates,
          LostFoundUpdate(
            title: 'Item Found by Driver',
            description: 'Good news! The driver has confirmed finding your item.',
            timestamp: DateTime.now(),
            status: LostFoundStatus.matched,
          ),
        ],
      );
      state = state.copyWith(
        items: state.items.map((i) => i.id == item.id ? matched : i).toList(),
      );
    });

    return item;
  }

  void markAsReturned(String itemId) {
    state = state.copyWith(
      items: state.items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(
            status: LostFoundStatus.returned,
            resolvedAt: DateTime.now(),
            updates: [
              ...item.updates,
              LostFoundUpdate(
                title: 'Item Returned',
                description: 'Item has been successfully returned.',
                timestamp: DateTime.now(),
                status: LostFoundStatus.returned,
              ),
            ],
          );
        }
        return item;
      }).toList(),
    );
  }

  void closeReport(String itemId) {
    state = state.copyWith(
      items: state.items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(status: LostFoundStatus.closed, resolvedAt: DateTime.now());
        }
        return item;
      }).toList(),
    );
  }
}

final lostFoundControllerProvider =
    StateNotifierProvider<LostFoundController, LostFoundState>((ref) {
  return LostFoundController();
});
