import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Feature 9: Subscription Plans

enum SubscriptionTier { basic, pro, premium }

class SubscriptionPlan {
  final String id;
  final SubscriptionTier tier;
  final String name;
  final String description;
  final double monthlyPrice;
  final int freeRidesPerMonth;
  final double discountPercent;
  final bool priorityPickup;
  final bool noSurgeGuarantee;
  final bool loungeAccess;
  final List<String> perks;

  const SubscriptionPlan({
    required this.id,
    required this.tier,
    required this.name,
    required this.description,
    required this.monthlyPrice,
    required this.freeRidesPerMonth,
    required this.discountPercent,
    this.priorityPickup = false,
    this.noSurgeGuarantee = false,
    this.loungeAccess = false,
    this.perks = const [],
  });
}

class UserSubscription {
  final String id;
  final SubscriptionPlan plan;
  final DateTime startDate;
  final DateTime endDate;
  final int freeRidesUsed;
  final int totalRidesTaken;
  final double totalSaved;
  final bool isActive;

  const UserSubscription({
    required this.id,
    required this.plan,
    required this.startDate,
    required this.endDate,
    this.freeRidesUsed = 0,
    this.totalRidesTaken = 0,
    this.totalSaved = 0,
    required this.isActive,
  });

  int get freeRidesRemaining => plan.freeRidesPerMonth - freeRidesUsed;
  int get daysRemaining => endDate.difference(DateTime.now()).inDays;

  UserSubscription copyWith({
    int? freeRidesUsed,
    int? totalRidesTaken,
    double? totalSaved,
    bool? isActive,
  }) {
    return UserSubscription(
      id: id,
      plan: plan,
      startDate: startDate,
      endDate: endDate,
      freeRidesUsed: freeRidesUsed ?? this.freeRidesUsed,
      totalRidesTaken: totalRidesTaken ?? this.totalRidesTaken,
      totalSaved: totalSaved ?? this.totalSaved,
      isActive: isActive ?? this.isActive,
    );
  }
}

class SubscriptionState {
  final List<SubscriptionPlan> availablePlans;
  final UserSubscription? activeSubscription;
  final bool isLoading;

  const SubscriptionState({
    this.availablePlans = const [],
    this.activeSubscription,
    this.isLoading = false,
  });

  SubscriptionState copyWith({
    List<SubscriptionPlan>? availablePlans,
    UserSubscription? activeSubscription,
    bool? isLoading,
    bool clearSubscription = false,
  }) {
    return SubscriptionState(
      availablePlans: availablePlans ?? this.availablePlans,
      activeSubscription: clearSubscription
          ? null
          : (activeSubscription ?? this.activeSubscription),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SubscriptionController extends StateNotifier<SubscriptionState> {
  SubscriptionController() : super(const SubscriptionState()) {
    _loadPlans();
  }

  void _loadPlans() {
    state = state.copyWith(
      availablePlans: const [
        SubscriptionPlan(
          id: 'basic',
          tier: SubscriptionTier.basic,
          name: 'Serene Basic',
          description: 'Great for occasional riders',
          monthlyPrice: 149,
          freeRidesPerMonth: 3,
          discountPercent: 10,
          perks: ['3 free rides/month', '10% off all rides', 'Priority support'],
        ),
        SubscriptionPlan(
          id: 'pro',
          tier: SubscriptionTier.pro,
          name: 'Serene Pro',
          description: 'Best for daily commuters',
          monthlyPrice: 399,
          freeRidesPerMonth: 10,
          discountPercent: 20,
          priorityPickup: true,
          perks: ['10 free rides/month', '20% off all rides', 'Priority pickup', 'No surge pricing'],
          noSurgeGuarantee: true,
        ),
        SubscriptionPlan(
          id: 'premium',
          tier: SubscriptionTier.premium,
          name: 'Serene Premium',
          description: 'The ultimate ride experience',
          monthlyPrice: 799,
          freeRidesPerMonth: 25,
          discountPercent: 30,
          priorityPickup: true,
          noSurgeGuarantee: true,
          loungeAccess: true,
          perks: [
            '25 free rides/month',
            '30% off all rides',
            'Priority pickup',
            'No surge pricing',
            'Airport lounge access',
            'Dedicated support line',
          ],
        ),
      ],
    );
  }

  Future<void> subscribeToPlan(SubscriptionPlan plan) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 800));

    final subscription = UserSubscription(
      id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
      plan: plan,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 30)),
      isActive: true,
    );

    state = state.copyWith(
      activeSubscription: subscription,
      isLoading: false,
    );
  }

  void cancelSubscription() {
    final sub = state.activeSubscription;
    if (sub == null) return;
    state = state.copyWith(
      activeSubscription: sub.copyWith(isActive: false),
    );
  }

  void useFreeeRide() {
    final sub = state.activeSubscription;
    if (sub == null || sub.freeRidesRemaining <= 0) return;
    state = state.copyWith(
      activeSubscription: sub.copyWith(
        freeRidesUsed: sub.freeRidesUsed + 1,
        totalRidesTaken: sub.totalRidesTaken + 1,
      ),
    );
  }

  double applyDiscount(double fare) {
    final sub = state.activeSubscription;
    if (sub == null || !sub.isActive) return fare;
    if (sub.freeRidesRemaining > 0) return 0;
    return fare * (1 - sub.plan.discountPercent / 100);
  }
}

final subscriptionControllerProvider =
    StateNotifierProvider<SubscriptionController, SubscriptionState>((ref) {
  return SubscriptionController();
});
