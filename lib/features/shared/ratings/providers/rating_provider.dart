import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Feature 5: Driver Ratings & Reviews

class RideRating {
  final String id;
  final String rideId;
  final String raterId;
  final String raterName;
  final String ratedId;
  final String ratedName;
  final double stars;
  final String? review;
  final List<String> badges;
  final bool isDriverRating;
  final DateTime createdAt;

  const RideRating({
    required this.id,
    required this.rideId,
    required this.raterId,
    required this.raterName,
    required this.ratedId,
    required this.ratedName,
    required this.stars,
    this.review,
    this.badges = const [],
    required this.isDriverRating,
    required this.createdAt,
  });
}

class RatingsSummary {
  final double averageRating;
  final int totalRatings;
  final Map<int, int> distribution;
  final List<RideRating> recentReviews;
  final bool isFlagged;

  const RatingsSummary({
    this.averageRating = 0,
    this.totalRatings = 0,
    this.distribution = const {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
    this.recentReviews = const [],
    this.isFlagged = false,
  });
}

class RatingState {
  final double selectedStars;
  final String reviewText;
  final List<String> selectedBadges;
  final bool isSubmitting;
  final bool isSubmitted;
  final RatingsSummary? driverSummary;
  final List<RideRating> allRatings;

  const RatingState({
    this.selectedStars = 0,
    this.reviewText = '',
    this.selectedBadges = const [],
    this.isSubmitting = false,
    this.isSubmitted = false,
    this.driverSummary,
    this.allRatings = const [],
  });

  RatingState copyWith({
    double? selectedStars,
    String? reviewText,
    List<String>? selectedBadges,
    bool? isSubmitting,
    bool? isSubmitted,
    RatingsSummary? driverSummary,
    List<RideRating>? allRatings,
  }) {
    return RatingState(
      selectedStars: selectedStars ?? this.selectedStars,
      reviewText: reviewText ?? this.reviewText,
      selectedBadges: selectedBadges ?? this.selectedBadges,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      driverSummary: driverSummary ?? this.driverSummary,
      allRatings: allRatings ?? this.allRatings,
    );
  }
}

class RatingController extends StateNotifier<RatingState> {
  RatingController() : super(const RatingState()) {
    _loadDemoSummary();
  }

  final _random = Random();

  void setStars(double stars) {
    state = state.copyWith(selectedStars: stars);
  }

  void setReview(String text) {
    state = state.copyWith(reviewText: text);
  }

  void toggleBadge(String badge) {
    final badges = [...state.selectedBadges];
    if (badges.contains(badge)) {
      badges.remove(badge);
    } else {
      badges.add(badge);
    }
    state = state.copyWith(selectedBadges: badges);
  }

  Future<bool> submitRating({
    required String rideId,
    required String driverId,
    required String driverName,
  }) async {
    if (state.selectedStars == 0) return false;

    state = state.copyWith(isSubmitting: true);
    await Future.delayed(const Duration(milliseconds: 800));

    final rating = RideRating(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      rideId: rideId,
      raterId: 'passenger_001',
      raterName: 'You',
      ratedId: driverId,
      ratedName: driverName,
      stars: state.selectedStars,
      review: state.reviewText.isNotEmpty ? state.reviewText : null,
      badges: state.selectedBadges,
      isDriverRating: true,
      createdAt: DateTime.now(),
    );

    // Update running average
    final summary = state.driverSummary;
    if (summary != null) {
      final newTotal = summary.totalRatings + 1;
      final newAvg = ((summary.averageRating * summary.totalRatings) +
              state.selectedStars) /
          newTotal;
      final newDist = Map<int, int>.from(summary.distribution);
      final starKey = state.selectedStars.round();
      newDist[starKey] = (newDist[starKey] ?? 0) + 1;

      state = state.copyWith(
        isSubmitting: false,
        isSubmitted: true,
        allRatings: [rating, ...state.allRatings],
        driverSummary: RatingsSummary(
          averageRating: newAvg,
          totalRatings: newTotal,
          distribution: newDist,
          recentReviews: [rating, ...summary.recentReviews].take(10).toList(),
          isFlagged: newAvg < 3.5,
        ),
      );
    }

    return true;
  }

  void resetRating() {
    state = state.copyWith(
      selectedStars: 0,
      reviewText: '',
      selectedBadges: [],
      isSubmitted: false,
    );
  }

  void _loadDemoSummary() {
    final demoRatings = List.generate(15, (i) {
      final stars = 3.0 + _random.nextInt(3);
      return RideRating(
        id: 'rating_$i',
        rideId: 'ride_$i',
        raterId: 'passenger_$i',
        raterName: ['Priya', 'Amit', 'Sakshi', 'Rahul', 'Sneha'][i % 5],
        ratedId: 'driver_001',
        ratedName: 'Ravi Kumar',
        stars: stars,
        review: i % 3 == 0
            ? ['Great driver!', 'Very punctual', 'Clean car', 'Safe driving'][i % 4]
            : null,
        badges: i % 2 == 0 ? ['Polite', 'Clean Car'] : [],
        isDriverRating: true,
        createdAt: DateTime.now().subtract(Duration(days: i)),
      );
    });

    state = state.copyWith(
      allRatings: demoRatings,
      driverSummary: RatingsSummary(
        averageRating: 4.52,
        totalRatings: 156,
        distribution: {5: 89, 4: 42, 3: 18, 2: 5, 1: 2},
        recentReviews: demoRatings.take(5).toList(),
      ),
    );
  }
}

final ratingControllerProvider =
    StateNotifierProvider<RatingController, RatingState>((ref) {
  return RatingController();
});
