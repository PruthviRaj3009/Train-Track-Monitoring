import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:train_track_monitoring/config/websocket_config.dart';
import 'package:train_track_monitoring/models/robot_control_message.dart';
import 'package:train_track_monitoring/models/robot_status_message.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:loginpage/models/robot_control_message.dart';
// import 'package:loginpage/models/robot_status_message.dart';
// import 'package:loginpage/config/websocket_config.dart';

/// WebSocket service for robot communication.
///
/// Handles connection management, message sending/receiving, and auto-reconnect.
/// Uses a stream-based approach for incoming messages that pages can listen to.
///
/// **SINGLETON PATTERN**: Only one instance exists across the entire app.
/// Use `WebSocketService.instance` to access the shared instance.
class WebSocketService {
  /// Singleton instance (shared across all pages)
  static final WebSocketService _instance = WebSocketService._internal();

  /// Factory constructor returns the singleton instance
  factory WebSocketService() => _instance;

  /// Access the singleton instance directly
  static WebSocketService get instance => _instance;

  /// Private constructor for singleton pattern
  WebSocketService._internal() {
    print('[WS_SINGLETON] WebSocketService singleton created');
  }

  /// WebSocket connection URL (configured in websocket_config.dart)
  static String get defaultUrl =>
      'ws://${NetworkConfig.defaultRobotIp}:${NetworkConfig.webSocketPort}';

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  String _url = defaultUrl;
  bool _isConnecting = false;
  bool _shouldReconnect = false;

  /// Current connection status
  bool get isConnected => _channel != null && _isConnecting == false;

  /// Stream controller for incoming status messages
  final _messageController = StreamController<RobotStatusMessage>.broadcast();

  /// Stream controller for connection status changes
  final _connectionController = StreamController<bool>.broadcast();

  /// Stream of incoming robot status messages
  Stream<RobotStatusMessage> get messageStream => _messageController.stream;

  /// Stream of connection status (true = connected, false = disconnected)
  Stream<bool> get connectionStream => _connectionController.stream;

  /// Connects to the WebSocket server.
  ///
  /// [url] - Optional custom WebSocket URL (defaults to saved IP or defaultUrl)
  ///
  /// Example:
  /// ```dart
  /// await websocketService.connect();
  /// // or with custom URL:
  /// await websocketService.connect(url: 'ws://192.168.1.100:81');
  /// ```
  Future<void> connect({String? url}) async {
    if (_isConnecting || isConnected) {
      print('[WS_CONNECT] Already connected or connecting - skipping');
      return;
    }

    // Load saved IP if no URL provided
    if (url == null && _url == defaultUrl) {
      _url = await NetworkConfig.getWebSocketUrl();
      print('[WS_CONNECT] Using saved IP from SharedPreferences: $_url');
    } else if (url != null) {
      _url = url;
    }

    _isConnecting = true;
    _shouldReconnect = true;

    try {
      print('[WS_CONNECT] Attempting to connect to $_url');

      _channel = WebSocketChannel.connect(Uri.parse(_url));

      // Wait for connection to establish
      await _channel!.ready;

      _isConnecting = false;
      _connectionController.add(true);
      print('[WS_CONNECTED] WebSocket connected successfully to $_url');

      // Listen to incoming messages
      _channel!.stream.listen(
        _handleIncomingMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );
    } catch (e) {
      _isConnecting = false;
      _channel = null;
      _connectionController.add(false);
      print('[WS_ERROR] Connection failed: $e');
      print('[WS_ERROR] URL: $_url');
      print(
        '[WS_ERROR] Check: 1) Robot is powered on, 2) Same WiFi network, 3) Correct IP address',
      );

      // Attempt auto-reconnect
      if (_shouldReconnect) {
        _scheduleReconnect();
      }
    }
  }

  /// Disconnects from the WebSocket server.
  ///
  /// Stops auto-reconnect attempts.
  Future<void> disconnect() async {
    print('[WS_DISCONNECTED] Disconnecting from $_url');
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    await _channel?.sink.close();
    _channel = null;
    _isConnecting = false;
    _connectionController.add(false);
    print('[WS_DISCONNECTED] Connection closed');
  }

  /// Sends a control message to the robot.
  ///
  /// Example:
  /// ```dart
  /// final message = RobotControlMessage.control(
  ///   grip: 90, wristPitch: 45, wristRoll: 120,
  ///   elbow: 60, shoulder: 75, waist: 90, speed: 150,
  /// );
  /// websocketService.sendMessage(message);
  /// ```
  void sendMessage(RobotControlMessage message) {
    print(
      '[WS_SEND] Connection status: isConnected=$isConnected, channel=${_channel != null ? "active" : "null"}',
    );

    if (!isConnected) {
      print('[WS_SEND] ERROR - Cannot send message - not connected');
      print(
        '[WS_SEND] Make sure connect() was called and connection is established',
      );
      return;
    }

    try {
      final jsonData = message.toJson();
      final jsonString = jsonEncode(jsonData);
      print('[WS_SEND] Sending message type: ${message.messageType}');
      print('[WS_SEND] Payload: $jsonString');
      _channel!.sink.add(jsonString);
      print('[WS_SEND] Message sent successfully');
    } catch (e) {
      print('[WS_ERROR] Send error: $e');
    }
  }

  /// Handles incoming WebSocket messages.
  void _handleIncomingMessage(dynamic data) {
    try {
      print('[WS_RECEIVE] Raw message: $data');
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      print('[WS_RECEIVE] Parsed JSON: $json');

      final message = RobotStatusMessage.tryFromJson(json);

      if (message != null) {
        print('[WS_RECEIVE] messageType: ${message.messageType}');
        print('[WS_RECEIVE] timestamp: ${message.timestamp}');
        print('[WS_RECEIVE] data fields: ${message.data.keys.toList()}');
        _messageController.add(message);
      } else {
        print(
          '[WS_RECEIVE] ERROR - Failed to parse message into RobotStatusMessage',
        );
        print('[WS_RECEIVE] Raw data: $data');
      }
    } catch (e) {
      print('[WS_ERROR] Message parsing error: $e');
      print('[WS_ERROR] Raw data: $data');
    }
  }

  /// Handles WebSocket errors.
  void _handleError(dynamic error) {
    print('[WS_ERROR] WebSocket error occurred: $error');
    print('[WS_ERROR] Error type: ${error.runtimeType}');
    _connectionController.add(false);
  }

  /// Handles WebSocket disconnection.
  void _handleDisconnect() {
    print('[WS_DISCONNECTED] Connection closed by remote or network issue');
    _channel = null;
    _isConnecting = false;
    _connectionController.add(false);

    // Attempt auto-reconnect if enabled
    if (_shouldReconnect) {
      _scheduleReconnect();
    }
  }

  /// Schedules an auto-reconnect attempt after 3 seconds.
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      print('[WS_CONNECT] Auto-reconnecting after 3 seconds...');
      connect();
    });
  }

  /// Reference counter to track how many pages are using the service
  int _referenceCount = 0;

  /// Increments reference count when a page starts using the service
  void retain() {
    _referenceCount++;
    print('[WS_SINGLETON] Reference count increased: $_referenceCount');

    // Auto-connect when first page uses the service
    if (_referenceCount == 1 && !isConnected && !_isConnecting) {
      print('[WS_SINGLETON] First page using service - auto-connecting');
      connect();
    }
  }

  /// Decrements reference count when a page stops using the service
  void release() {
    _referenceCount--;
    print('[WS_SINGLETON] Reference count decreased: $_referenceCount');

    // Only disconnect if no pages are using the service
    if (_referenceCount <= 0) {
      print('[WS_SINGLETON] No pages using service - disconnecting');
      _referenceCount = 0; // Prevent negative count
      disconnect();
    }
  }

  /// Disposes the service and cleans up resources.
  ///
  /// NOTE: With singleton pattern, this should rarely be called.
  /// Use retain()/release() instead for proper reference counting.
  void dispose() {
    print('[WS_SINGLETON] WARNING - dispose() called on singleton');
    print('[WS_SINGLETON] Consider using release() instead');

    // Only actually dispose if reference count is 0
    if (_referenceCount <= 0) {
      disconnect();
      _messageController.close();
      _connectionController.close();
    }
  }
}
