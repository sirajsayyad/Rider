import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Feature 6: Referral System

class ReferralInfo {
  final String code;
  final int totalInvites;
  final int completedRides;
  final double totalEarned;
  final List<ReferralRecord> history;

  const ReferralInfo({
    required this.code,
    this.totalInvites = 0,
    this.completedRides = 0,
    this.totalEarned = 0,
    this.history = const [],
  });

  ReferralInfo copyWith({
    int? totalInvites,
    int? completedRides,
    double? totalEarned,
    List<ReferralRecord>? history,
  }) {
    return ReferralInfo(
      code: code,
      totalInvites: totalInvites ?? this.totalInvites,
      completedRides: completedRides ?? this.completedRides,
      totalEarned: totalEarned ?? this.totalEarned,
      history: history ?? this.history,
    );
  }
}

class ReferralRecord {
  final String id;
  final String referredName;
  final String referredPhone;
  final bool hasCompletedFirstRide;
  final double rewardAmount;
  final DateTime referredAt;

  const ReferralRecord({
    required this.id,
    required this.referredName,
    required this.referredPhone,
    this.hasCompletedFirstRide = false,
    this.rewardAmount = 0,
    required this.referredAt,
  });
}

class ReferralState {
  final ReferralInfo? info;
  final bool isLoading;
  final String? error;

  const ReferralState({this.info, this.isLoading = false, this.error});

  ReferralState copyWith({
    ReferralInfo? info,
    bool? isLoading,
    String? error,
  }) {
    return ReferralState(
      info: info ?? this.info,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ReferralController extends StateNotifier<ReferralState> {
  ReferralController() : super(const ReferralState()) {
    _loadDemoData();
  }

  void _loadDemoData() {
    state = state.copyWith(
      info: ReferralInfo(
        code: 'SERENE${Random().nextInt(9000) + 1000}',
        totalInvites: 8,
        completedRides: 5,
        totalEarned: 500,
        history: [
          ReferralRecord(
            id: '1',
            referredName: 'Amit Sharma',
            referredPhone: '+91 98XXXX1234',
            hasCompletedFirstRide: true,
            rewardAmount: 100,
            referredAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
          ReferralRecord(
            id: '2',
            referredName: 'Priya Patel',
            referredPhone: '+91 87XXXX5678',
            hasCompletedFirstRide: true,
            rewardAmount: 100,
            referredAt: DateTime.now().subtract(const Duration(days: 12)),
          ),
          ReferralRecord(
            id: '3',
            referredName: 'Rahul Singh',
            referredPhone: '+91 99XXXX9876',
            hasCompletedFirstRide: false,
            rewardAmount: 0,
            referredAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ],
      ),
    );
  }

  Future<bool> applyReferralCode(String code) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (code.toUpperCase().startsWith('SERENE')) {
      state = state.copyWith(isLoading: false);
      return true;
    }
    state = state.copyWith(isLoading: false, error: 'Invalid referral code');
    return false;
  }
}

final referralControllerProvider =
    StateNotifierProvider<ReferralController, ReferralState>((ref) {
  return ReferralController();
});
