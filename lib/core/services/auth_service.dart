import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';
import 'socket_service.dart';

/// User model
class User {
  final String id;
  final String phone;
  final String? email;
  final String? name;
  final String? avatarUrl;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  
  User({
    required this.id,
    required this.phone,
    this.email,
    this.name,
    this.avatarUrl,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      phone: json['phone'],
      email: json['email'],
      name: json['name'],
      avatarUrl: json['avatar_url'],
      role: json['role'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'email': email,
      'name': name,
      'avatar_url': avatarUrl,
      'role': role,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Auth state
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;
  
  AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
  });
  
  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }
}

/// Auth Service - Handles authentication logic
class AuthService extends StateNotifier<AuthState> {
  final ApiService _apiService;
  final SocketService _socketService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  AuthService(this._apiService, this._socketService) : super(AuthState());
  
  /// Check if user is authenticated on app start
  Future<void> checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading);
    
    try {
      final isAuth = await _apiService.isAuthenticated();
      
      if (isAuth) {
        final response = await _apiService.get(ApiConstants.me);
        final user = User.fromJson(response.data['user']);
        
        // Connect socket
        final token = await _storage.read(key: AppConfig.accessTokenKey);
        if (token != null) {
          _socketService.connect(token);
        }
        
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }
  
  /// Send OTP to phone number
  Future<bool> sendOtp(String phone) async {
    try {
      state = state.copyWith(status: AuthStatus.loading);
      
      // Demo mode - simulate sending OTP
      if (AppConfig.isDemoMode) {
        await Future.delayed(const Duration(milliseconds: 500));
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return true;
      }
      
      await _apiService.post(
        ApiConstants.sendOtp,
        data: {'phone': phone},
      );
      
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: 'Failed to send OTP: ${e.toString()}',
      );
      return false;
    }
  }
  
  /// Verify OTP and login
  Future<bool> verifyOtp(String phone, String otp) async {
    try {
      state = state.copyWith(status: AuthStatus.loading);
      
      // Demo mode - verify OTP is 123456
      if (AppConfig.isDemoMode) {
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (otp != AppConfig.demoOtp) {
          state = state.copyWith(
            status: AuthStatus.error,
            error: 'Invalid OTP. Use 123456 for demo.',
          );
          return false;
        }
        
        // Create a demo user
        final user = User(
          id: 'demo_user_${DateTime.now().millisecondsSinceEpoch}',
          phone: phone,
          name: 'Demo User',
          email: 'demo@rideconnect.com',
          role: 'passenger', // Can be changed to 'driver' or 'admin' for testing
          isActive: true,
          createdAt: DateTime.now(),
        );
        
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
        
        return true;
      }
      
      final response = await _apiService.post(
        ApiConstants.verifyOtp,
        data: {
          'phone': phone,
          'otp': otp,
        },
      );
      
      final data = response.data;
      
      // Save tokens
      await _apiService.saveTokens(
        data['access_token'],
        data['refresh_token'],
      );
      
      // Parse user
      final user = User.fromJson(data['user']);
      
      // Connect socket
      _socketService.connect(data['access_token']);
      
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: 'Invalid OTP. Please try again.',
      );
      return false;
    }
  }
  
  /// Update user profile
  Future<bool> updateProfile({
    String? name,
    String? email,
    String? avatarUrl,
  }) async {
    try {
      final response = await _apiService.put(
        ApiConstants.passengerProfile,
        data: {
          if (name != null) 'name': name,
          if (email != null) 'email': email,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
        },
      );
      
      final user = User.fromJson(response.data['user']);
      state = state.copyWith(user: user);
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Logout
  Future<void> logout() async {
    try {
      await _apiService.post(ApiConstants.logout);
    } catch (_) {}
    
    await _apiService.clearTokens();
    _socketService.disconnect();
    
    state = AuthState(status: AuthStatus.unauthenticated);
  }
  
  /// Get current user
  User? get currentUser => state.user;
  
  /// Check if authenticated
  bool get isAuthenticated => state.status == AuthStatus.authenticated;
}

/// Auth state provider
final authServiceProvider = StateNotifierProvider<AuthService, AuthState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final socketService = ref.watch(socketServiceProvider);
  return AuthService(apiService, socketService);
});

/// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authServiceProvider).user;
});

/// Is authenticated provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authServiceProvider).status == AuthStatus.authenticated;
});
