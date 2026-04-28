import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State and controller for Feature 4: In-App Voice Calls (simulated/masked)

enum CallStatus { idle, ringing, connected, ended }

class CallState {
  final CallStatus status;
  final String? callerName;
  final String? maskedNumber;
  final Duration duration;
  final bool isMuted;
  final bool isSpeakerOn;
  final bool isFromPassenger;

  const CallState({
    this.status = CallStatus.idle,
    this.callerName,
    this.maskedNumber,
    this.duration = Duration.zero,
    this.isMuted = false,
    this.isSpeakerOn = false,
    this.isFromPassenger = true,
  });

  CallState copyWith({
    CallStatus? status,
    String? callerName,
    String? maskedNumber,
    Duration? duration,
    bool? isMuted,
    bool? isSpeakerOn,
    bool? isFromPassenger,
  }) {
    return CallState(
      status: status ?? this.status,
      callerName: callerName ?? this.callerName,
      maskedNumber: maskedNumber ?? this.maskedNumber,
      duration: duration ?? this.duration,
      isMuted: isMuted ?? this.isMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isFromPassenger: isFromPassenger ?? this.isFromPassenger,
    );
  }

  String get durationFormatted {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class CallController extends StateNotifier<CallState> {
  CallController() : super(const CallState());

  Timer? _durationTimer;
  Timer? _ringTimer;

  /// Mask a phone number for privacy (e.g. +91 XXXXXX1234)
  String _generateMaskedNumber() {
    return '+91 XXXXXX${DateTime.now().millisecondsSinceEpoch % 10000}';
  }

  void initiateCall({
    required String callerName,
    bool isFromPassenger = true,
  }) {
    state = state.copyWith(
      status: CallStatus.ringing,
      callerName: callerName,
      maskedNumber: _generateMaskedNumber(),
      isFromPassenger: isFromPassenger,
      duration: Duration.zero,
    );

    // Simulate auto-answer after 3 seconds
    _ringTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      if (state.status == CallStatus.ringing) {
        _connectCall();
      }
    });
  }

  void _connectCall() {
    state = state.copyWith(status: CallStatus.connected);
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      state = state.copyWith(
        duration: Duration(seconds: state.duration.inSeconds + 1),
      );
    });
  }

  void toggleMute() {
    state = state.copyWith(isMuted: !state.isMuted);
  }

  void toggleSpeaker() {
    state = state.copyWith(isSpeakerOn: !state.isSpeakerOn);
  }

  void endCall() {
    _durationTimer?.cancel();
    _ringTimer?.cancel();
    state = state.copyWith(status: CallStatus.ended);

    // Reset after a delay
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      state = const CallState();
    });
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _ringTimer?.cancel();
    super.dispose();
  }
}

final callControllerProvider =
    StateNotifierProvider<CallController, CallState>((ref) {
  return CallController();
});
