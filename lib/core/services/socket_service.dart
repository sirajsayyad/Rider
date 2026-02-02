import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/app_config.dart';
import '../constants/api_constants.dart';

/// WebSocket Service for real-time communication
class SocketService {
  IO.Socket? _socket;
  final Map<String, List<Function(dynamic)>> _eventListeners = {};
  bool _isConnected = false;
  String? _authToken;
  
  bool get isConnected => _isConnected;
  
  /// Initialize socket connection
  void connect(String token) {
    _authToken = token;
    
    _socket = IO.io(
      AppConfig.wsUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000)
          .build(),
    );
    
    _setupListeners();
  }
  
  void _setupListeners() {
    _socket?.onConnect((_) {
      _isConnected = true;
      print('Socket connected');
    });
    
    _socket?.onDisconnect((_) {
      _isConnected = false;
      print('Socket disconnected');
    });
    
    _socket?.onConnectError((error) {
      print('Socket connection error: $error');
    });
    
    _socket?.onError((error) {
      print('Socket error: $error');
    });
    
    // Listen for all registered events
    for (final event in _eventListeners.keys) {
      _socket?.on(event, (data) {
        for (final listener in _eventListeners[event] ?? []) {
          listener(data);
        }
      });
    }
  }
  
  /// Subscribe to an event
  void on(String event, Function(dynamic) callback) {
    if (!_eventListeners.containsKey(event)) {
      _eventListeners[event] = [];
      _socket?.on(event, (data) {
        for (final listener in _eventListeners[event] ?? []) {
          listener(data);
        }
      });
    }
    _eventListeners[event]!.add(callback);
  }
  
  /// Unsubscribe from an event
  void off(String event, [Function(dynamic)? callback]) {
    if (callback != null) {
      _eventListeners[event]?.remove(callback);
    } else {
      _eventListeners.remove(event);
      _socket?.off(event);
    }
  }
  
  /// Emit an event
  void emit(String event, [dynamic data]) {
    if (_isConnected) {
      _socket?.emit(event, data);
    } else {
      print('Socket not connected, cannot emit $event');
    }
  }
  
  /// Update driver location
  void updateDriverLocation(double lat, double lng) {
    emit(WsEvents.driverLocation, {
      'latitude': lat,
      'longitude': lng,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// Join a ride room for tracking
  void joinRideRoom(String rideId) {
    emit('join:ride', {'ride_id': rideId});
  }
  
  /// Leave a ride room
  void leaveRideRoom(String rideId) {
    emit('leave:ride', {'ride_id': rideId});
  }
  
  /// Send chat message
  void sendChatMessage(String rideId, String message) {
    emit(WsEvents.chatMessage, {
      'ride_id': rideId,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// Disconnect socket
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _eventListeners.clear();
  }
  
  /// Reconnect socket
  void reconnect() {
    if (_authToken != null && !_isConnected) {
      connect(_authToken!);
    }
  }
}

/// Provider for SocketService
final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService();
});

/// Stream provider for ride tracking updates
final rideTrackingProvider = StreamProvider.family<Map<String, dynamic>, String>((ref, rideId) {
  final socket = ref.watch(socketServiceProvider);
  final controller = StreamController<Map<String, dynamic>>();
  
  void onTracking(dynamic data) {
    controller.add(Map<String, dynamic>.from(data));
  }
  
  socket.joinRideRoom(rideId);
  socket.on(WsEvents.rideTracking, onTracking);
  
  ref.onDispose(() {
    socket.leaveRideRoom(rideId);
    socket.off(WsEvents.rideTracking, onTracking);
    controller.close();
  });
  
  return controller.stream;
});
