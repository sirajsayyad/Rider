// Shared application-wide models used across features.

class AppUser {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? avatarUrl;
  final String role;
  final double walletBalance;
  final int rewardPoints;
  final List<SavedAddress> savedAddresses;
  final UserPreferencesData preferences;
  final DateTime createdAt;
  // New feature fields
  final String? referralCode;
  final String? referredBy;
  final String gender;
  final String? corporateAccountId;
  final bool isCorporate;
  final String? activeSubscriptionId;

  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.avatarUrl,
    required this.role,
    this.walletBalance = 0,
    this.rewardPoints = 0,
    this.savedAddresses = const [],
    this.preferences = const UserPreferencesData(),
    required this.createdAt,
    this.referralCode,
    this.referredBy,
    this.gender = 'unspecified',
    this.corporateAccountId,
    this.isCorporate = false,
    this.activeSubscriptionId,
  });

  AppUser copyWith({
    String? name,
    String? phone,
    String? email,
    String? avatarUrl,
    String? role,
    double? walletBalance,
    int? rewardPoints,
    List<SavedAddress>? savedAddresses,
    UserPreferencesData? preferences,
    String? referralCode,
    String? referredBy,
    String? gender,
    String? corporateAccountId,
    bool? isCorporate,
    String? activeSubscriptionId,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      walletBalance: walletBalance ?? this.walletBalance,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      savedAddresses: savedAddresses ?? this.savedAddresses,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      gender: gender ?? this.gender,
      corporateAccountId: corporateAccountId ?? this.corporateAccountId,
      isCorporate: isCorporate ?? this.isCorporate,
      activeSubscriptionId: activeSubscriptionId ?? this.activeSubscriptionId,
    );
  }
}

class SavedAddress {
  final String id;
  final String label;
  final String address;
  final double latitude;
  final double longitude;
  final AddressType type;

  const SavedAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.type = AddressType.other,
  });
}

enum AddressType { home, work, other }

class UserPreferencesData {
  final bool darkMode;
  final bool pushNotifications;
  final bool smsAlerts;
  final bool emailReceipts;
  final String defaultPaymentMethod;
  final String language;

  const UserPreferencesData({
    this.darkMode = false,
    this.pushNotifications = true,
    this.smsAlerts = true,
    this.emailReceipts = true,
    this.defaultPaymentMethod = 'cash',
    this.language = 'en',
  });

  UserPreferencesData copyWith({
    bool? darkMode,
    bool? pushNotifications,
    bool? smsAlerts,
    bool? emailReceipts,
    String? defaultPaymentMethod,
    String? language,
  }) {
    return UserPreferencesData(
      darkMode: darkMode ?? this.darkMode,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      smsAlerts: smsAlerts ?? this.smsAlerts,
      emailReceipts: emailReceipts ?? this.emailReceipts,
      defaultPaymentMethod: defaultPaymentMethod ?? this.defaultPaymentMethod,
      language: language ?? this.language,
    );
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final bool isFromUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.isFromUser,
    required this.timestamp,
  });
}

class LoyaltyReward {
  final String id;
  final String title;
  final String description;
  final int pointsRequired;
  final double discountAmount;
  final RewardType type;
  final DateTime? expiresAt;
  final bool isRedeemed;

  const LoyaltyReward({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsRequired,
    required this.discountAmount,
    required this.type,
    this.expiresAt,
    this.isRedeemed = false,
  });
}

enum RewardType { discount, freeRide, cashback, upgrade }

class PromoCode {
  final String code;
  final String description;
  final double discountPercent;
  final double maxDiscount;
  final DateTime expiresAt;
  final bool isUsed;

  const PromoCode({
    required this.code,
    required this.description,
    required this.discountPercent,
    required this.maxDiscount,
    required this.expiresAt,
    this.isUsed = false,
  });

  bool get isValid => !isUsed && DateTime.now().isBefore(expiresAt);
}

class FrequentRoute {
  final String id;
  final String fromAddress;
  final double fromLat;
  final double fromLng;
  final String toAddress;
  final double toLat;
  final double toLng;
  final int tripCount;
  final DateTime lastUsed;

  const FrequentRoute({
    required this.id,
    required this.fromAddress,
    required this.fromLat,
    required this.fromLng,
    required this.toAddress,
    required this.toLat,
    required this.toLng,
    required this.tripCount,
    required this.lastUsed,
  });
}
