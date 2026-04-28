/// Chat models for Feature 1: Live Chat (Driver ↔ Passenger)

enum MessageType { text, image, quickReply, system }

enum MessageStatus { sending, sent, delivered, read }

class LiveChatMessage {
  final String id;
  final String rideId;
  final String senderId;
  final String senderName;
  final String text;
  final MessageType type;
  final MessageStatus status;
  final bool isFromPassenger;
  final DateTime timestamp;

  const LiveChatMessage({
    required this.id,
    required this.rideId,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    required this.isFromPassenger,
    required this.timestamp,
  });

  LiveChatMessage copyWith({MessageStatus? status}) {
    return LiveChatMessage(
      id: id,
      rideId: rideId,
      senderId: senderId,
      senderName: senderName,
      text: text,
      type: type,
      status: status ?? this.status,
      isFromPassenger: isFromPassenger,
      timestamp: timestamp,
    );
  }
}

class ChatRoom {
  final String rideId;
  final String passengerId;
  final String driverId;
  final String passengerName;
  final String driverName;
  final List<LiveChatMessage> messages;
  final bool isDriverTyping;
  final bool isPassengerTyping;
  final DateTime createdAt;

  const ChatRoom({
    required this.rideId,
    required this.passengerId,
    required this.driverId,
    required this.passengerName,
    required this.driverName,
    this.messages = const [],
    this.isDriverTyping = false,
    this.isPassengerTyping = false,
    required this.createdAt,
  });

  ChatRoom copyWith({
    List<LiveChatMessage>? messages,
    bool? isDriverTyping,
    bool? isPassengerTyping,
  }) {
    return ChatRoom(
      rideId: rideId,
      passengerId: passengerId,
      driverId: driverId,
      passengerName: passengerName,
      driverName: driverName,
      messages: messages ?? this.messages,
      isDriverTyping: isDriverTyping ?? this.isDriverTyping,
      isPassengerTyping: isPassengerTyping ?? this.isPassengerTyping,
      createdAt: createdAt,
    );
  }
}
