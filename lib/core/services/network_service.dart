import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Network connection quality tiers
enum ConnectionQuality {
  excellent,
  good,
  slow,
  offline,
}

/// Current network state snapshot
class NetworkState {
  final ConnectionQuality quality;
  final bool isOnline;
  final bool isLowDataMode;
  final ConnectivityResult connectivityType;
  final DateTime lastCheckedAt;

  const NetworkState({
    this.quality = ConnectionQuality.good,
    this.isOnline = true,
    this.isLowDataMode = false,
    this.connectivityType = ConnectivityResult.wifi,
    required this.lastCheckedAt,
  });

  NetworkState copyWith({
    ConnectionQuality? quality,
    bool? isOnline,
    bool? isLowDataMode,
    ConnectivityResult? connectivityType,
    DateTime? lastCheckedAt,
  }) {
    return NetworkState(
      quality: quality ?? this.quality,
      isOnline: isOnline ?? this.isOnline,
      isLowDataMode: isLowDataMode ?? this.isLowDataMode,
      connectivityType: connectivityType ?? this.connectivityType,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
    );
  }

  /// Whether to use compressed / low-bandwidth payloads
  bool get shouldReduceData =>
      isLowDataMode || quality == ConnectionQuality.slow;

  /// Whether heavy assets (images, map tiles) should be deferred
  bool get shouldDeferHeavyAssets =>
      quality == ConnectionQuality.slow || !isOnline;
}

/// Adaptive network monitoring service
class NetworkService extends StateNotifier<NetworkState> {
  NetworkService()
      : super(NetworkState(lastCheckedAt: DateTime.now())) {
    _init();
  }

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _subscription;
  Timer? _qualityCheckTimer;

  /// Aggregate response-time samples for quality estimation
  final List<int> _latencySamples = [];
  static const int _maxSamples = 10;

  void _init() {
    // Listen for connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen(_onChanged);

    // Periodically re-evaluate connection quality
    _qualityCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _evaluateQuality(),
    );

    // Initial check
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _onChanged(result);
  }

  void _onChanged(ConnectivityResult result) {
    final primary = result;
    final online = primary != ConnectivityResult.none;

    state = state.copyWith(
      isOnline: online,
      connectivityType: primary,
      quality: online ? _inferQualityFromType(primary) : ConnectionQuality.offline,
      lastCheckedAt: DateTime.now(),
    );

    debugPrint('[NetworkService] connectivity=$primary  online=$online  quality=${state.quality}');
  }

  ConnectionQuality _inferQualityFromType(ConnectivityResult type) {
    // If we have latency samples, use them; otherwise infer from type
    if (_latencySamples.isNotEmpty) {
      return _qualityFromLatency(_averageLatency());
    }
    switch (type) {
      case ConnectivityResult.wifi:
      case ConnectivityResult.ethernet:
        return ConnectionQuality.excellent;
      case ConnectivityResult.mobile:
        return ConnectionQuality.good;
      default:
        return ConnectionQuality.slow;
    }
  }

  /// Record a request round-trip time in milliseconds
  void recordLatency(int milliseconds) {
    _latencySamples.add(milliseconds);
    if (_latencySamples.length > _maxSamples) {
      _latencySamples.removeAt(0);
    }
    _evaluateQuality();
  }

  void _evaluateQuality() {
    if (!state.isOnline) {
      state = state.copyWith(
        quality: ConnectionQuality.offline,
        lastCheckedAt: DateTime.now(),
      );
      return;
    }
    if (_latencySamples.isEmpty) return;

    final quality = _qualityFromLatency(_averageLatency());
    if (quality != state.quality) {
      state = state.copyWith(
        quality: quality,
        lastCheckedAt: DateTime.now(),
      );
      debugPrint('[NetworkService] quality updated → $quality');
    }
  }

  int _averageLatency() {
    if (_latencySamples.isEmpty) return 0;
    return (_latencySamples.reduce((a, b) => a + b) / _latencySamples.length)
        .round();
  }

  static ConnectionQuality _qualityFromLatency(int avgMs) {
    if (avgMs < 200) return ConnectionQuality.excellent;
    if (avgMs < 600) return ConnectionQuality.good;
    return ConnectionQuality.slow;
  }

  /// Toggle low-data mode (user-facing switch)
  void setLowDataMode(bool enabled) {
    state = state.copyWith(isLowDataMode: enabled);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _qualityCheckTimer?.cancel();
    super.dispose();
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final networkServiceProvider =
    StateNotifierProvider<NetworkService, NetworkState>((ref) {
  return NetworkService();
});

/// Convenience: is the device currently online?
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(networkServiceProvider).isOnline;
});

/// Convenience: current connection quality
final connectionQualityProvider = Provider<ConnectionQuality>((ref) {
  return ref.watch(networkServiceProvider).quality;
});
