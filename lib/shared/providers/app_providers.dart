import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_models.dart';

/// Global app state that persists across all features.
class AppState {
  final bool isOnboarded;
  final ThemeModeSetting themeMode;
  final List<LoyaltyReward> availableRewards;
  final List<PromoCode> promoCodes;
  final List<FrequentRoute> frequentRoutes;
  final List<ChatMessage> chatMessages;
  final bool isChatOpen;
  final String? activeChatDriverId;

  const AppState({
    this.isOnboarded = false,
    this.themeMode = ThemeModeSetting.system,
    this.availableRewards = const [],
    this.promoCodes = const [],
    this.frequentRoutes = const [],
    this.chatMessages = const [],
    this.isChatOpen = false,
    this.activeChatDriverId,
  });

  AppState copyWith({
    bool? isOnboarded,
    ThemeModeSetting? themeMode,
    List<LoyaltyReward>? availableRewards,
    List<PromoCode>? promoCodes,
    List<FrequentRoute>? frequentRoutes,
    List<ChatMessage>? chatMessages,
    bool? isChatOpen,
    String? activeChatDriverId,
    bool clearChatDriver = false,
  }) {
    return AppState(
      isOnboarded: isOnboarded ?? this.isOnboarded,
      themeMode: themeMode ?? this.themeMode,
      availableRewards: availableRewards ?? this.availableRewards,
      promoCodes: promoCodes ?? this.promoCodes,
      frequentRoutes: frequentRoutes ?? this.frequentRoutes,
      chatMessages: chatMessages ?? this.chatMessages,
      isChatOpen: isChatOpen ?? this.isChatOpen,
      activeChatDriverId: clearChatDriver
          ? null
          : (activeChatDriverId ?? this.activeChatDriverId),
    );
  }
}

enum ThemeModeSetting { light, dark, system }

class AppController extends StateNotifier<AppState> {
  AppController() : super(_initialState());

  static AppState _initialState() {
    return AppState(
      availableRewards: const [
        LoyaltyReward(
          id: 'r1',
          title: '10% Off Next Ride',
          description: 'Get 10% off on your next bike ride. Max Rs 50 discount.',
          pointsRequired: 50,
          discountAmount: 50,
          type: RewardType.discount,
        ),
        LoyaltyReward(
          id: 'r2',
          title: 'Free Auto Ride',
          description: 'Get a free auto ride up to Rs 100.',
          pointsRequired: 200,
          discountAmount: 100,
          type: RewardType.freeRide,
        ),
        LoyaltyReward(
          id: 'r3',
          title: '20% Cashback',
          description: '20% cashback on car rides this week. Max Rs 120.',
          pointsRequired: 100,
          discountAmount: 120,
          type: RewardType.cashback,
        ),
        LoyaltyReward(
          id: 'r4',
          title: 'Premium Upgrade',
          description: 'Upgrade your next economy ride to premium for free.',
          pointsRequired: 150,
          discountAmount: 0,
          type: RewardType.upgrade,
        ),
      ],
      promoCodes: [
        PromoCode(
          code: 'RIDE50',
          description: '50% off your first ride',
          discountPercent: 50,
          maxDiscount: 100,
          expiresAt: DateTime(2026, 5, 10),
        ),
        PromoCode(
          code: 'WELCOME25',
          description: '25% off for new users',
          discountPercent: 25,
          maxDiscount: 75,
          expiresAt: DateTime(2026, 4, 24),
        ),
      ],
      frequentRoutes: [
        FrequentRoute(
          id: 'fr1',
          fromAddress: 'Dwarka Sector 6, New Delhi',
          fromLat: 28.5562,
          fromLng: 77.1000,
          toAddress: 'Cyber Hub, Gurugram',
          toLat: 28.5002,
          toLng: 77.0896,
          tripCount: 12,
          lastUsed: DateTime(2026, 4, 9),
        ),
        FrequentRoute(
          id: 'fr2',
          fromAddress: 'Dwarka Sector 6, New Delhi',
          fromLat: 28.5562,
          fromLng: 77.1000,
          toAddress: 'Connaught Place, New Delhi',
          toLat: 28.6315,
          toLng: 77.2167,
          tripCount: 8,
          lastUsed: DateTime(2026, 4, 8),
        ),
      ],
    );
  }

  void setOnboarded() {
    state = state.copyWith(isOnboarded: true);
  }

  void setThemeMode(ThemeModeSetting mode) {
    state = state.copyWith(themeMode: mode);
  }

  void openChat(String driverId) {
    state = state.copyWith(isChatOpen: true, activeChatDriverId: driverId);
  }

  void closeChat() {
    state = state.copyWith(isChatOpen: false, clearChatDriver: true);
  }

  void sendChatMessage(String text, {required String senderName}) {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'user',
      senderName: senderName,
      text: text,
      isFromUser: true,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      chatMessages: [...state.chatMessages, message],
    );
    _simulateDriverReply(text);
  }

  void _simulateDriverReply(String userMessage) {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      final replies = [
        'OK, I am on my way!',
        'Noted, I will be there shortly.',
        'Sure, I will follow the route.',
        'Thank you, reaching in 2 minutes.',
        'I am near the pickup point.',
      ];
      final reply = replies[DateTime.now().second % replies.length];
      final message = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: state.activeChatDriverId ?? 'driver',
        senderName: 'Driver',
        text: reply,
        isFromUser: false,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        chatMessages: [...state.chatMessages, message],
      );
    });
  }

  void clearChat() {
    state = state.copyWith(
      chatMessages: [],
      isChatOpen: false,
      clearChatDriver: true,
    );
  }
}

final appControllerProvider =
    StateNotifierProvider<AppController, AppState>((ref) {
  return AppController();
});

final availableRewardsProvider = Provider<List<LoyaltyReward>>((ref) {
  return ref.watch(appControllerProvider).availableRewards;
});

final frequentRoutesProvider = Provider<List<FrequentRoute>>((ref) {
  return ref.watch(appControllerProvider).frequentRoutes;
});

final chatMessagesProvider = Provider<List<ChatMessage>>((ref) {
  return ref.watch(appControllerProvider).chatMessages;
});
