import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_models.dart';

class ChatState {
  final ChatRoom? activeRoom;
  final bool isLoading;
  final String? error;

  const ChatState({this.activeRoom, this.isLoading = false, this.error});

  ChatState copyWith({
    ChatRoom? activeRoom,
    bool? isLoading,
    String? error,
    bool clearRoom = false,
  }) {
    return ChatState(
      activeRoom: clearRoom ? null : (activeRoom ?? this.activeRoom),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<LiveChatMessage> get messages => activeRoom?.messages ?? [];
  bool get isDriverTyping => activeRoom?.isDriverTyping ?? false;
}

class ChatController extends StateNotifier<ChatState> {
  ChatController() : super(const ChatState());

  Timer? _typingTimer;
  Timer? _deliveryTimer;

  void openChatRoom({
    required String rideId,
    required String passengerId,
    required String driverId,
    required String passengerName,
    required String driverName,
  }) {
    state = state.copyWith(
      activeRoom: ChatRoom(
        rideId: rideId,
        passengerId: passengerId,
        driverId: driverId,
        passengerName: passengerName,
        driverName: driverName,
        createdAt: DateTime.now(),
      ),
    );
  }

  void sendMessage(String text, {required bool isFromPassenger}) {
    final room = state.activeRoom;
    if (room == null || text.trim().isEmpty) return;

    final message = LiveChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      rideId: room.rideId,
      senderId: isFromPassenger ? room.passengerId : room.driverId,
      senderName: isFromPassenger ? room.passengerName : room.driverName,
      text: text.trim(),
      isFromPassenger: isFromPassenger,
      status: MessageStatus.sent,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      activeRoom: room.copyWith(
        messages: [...room.messages, message],
      ),
    );

    // Simulate delivery after 500ms
    _deliveryTimer?.cancel();
    _deliveryTimer = Timer(const Duration(milliseconds: 500), () {
      _markDelivered(message.id);
    });

    // Simulate driver reply
    if (isFromPassenger) {
      _simulateDriverReply();
    }
  }

  void _markDelivered(String messageId) {
    final room = state.activeRoom;
    if (room == null) return;

    final updated = room.messages.map((m) {
      if (m.id == messageId && m.status == MessageStatus.sent) {
        return m.copyWith(status: MessageStatus.delivered);
      }
      return m;
    }).toList();

    state = state.copyWith(activeRoom: room.copyWith(messages: updated));
  }

  void _simulateDriverReply() {
    // Show typing indicator
    final room = state.activeRoom;
    if (room == null) return;

    _typingTimer?.cancel();

    // Driver starts typing after 1 second
    Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      final currentRoom = state.activeRoom;
      if (currentRoom == null) return;
      state = state.copyWith(
        activeRoom: currentRoom.copyWith(isDriverTyping: true),
      );
    });

    // Driver sends message after 2-3 seconds
    _typingTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      final currentRoom = state.activeRoom;
      if (currentRoom == null) return;

      final replies = [
        'On my way! Will reach in 2 minutes.',
        'Noted, following the route.',
        'Sure, I can see the location.',
        'Coming via the main road.',
        'Almost there, please wait.',
        'I am at the gate, please come.',
        'OK, understood!',
      ];
      final reply = replies[DateTime.now().second % replies.length];

      final message = LiveChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_driver',
        rideId: currentRoom.rideId,
        senderId: currentRoom.driverId,
        senderName: currentRoom.driverName,
        text: reply,
        isFromPassenger: false,
        status: MessageStatus.read,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        activeRoom: currentRoom.copyWith(
          messages: [...currentRoom.messages, message],
          isDriverTyping: false,
        ),
      );
    });
  }

  void clearChatOnRideEnd() {
    _typingTimer?.cancel();
    _deliveryTimer?.cancel();
    state = state.copyWith(clearRoom: true);
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _deliveryTimer?.cancel();
    super.dispose();
  }
}

final chatControllerProvider =
    StateNotifierProvider<ChatController, ChatState>((ref) {
  return ChatController();
});
