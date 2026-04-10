import 'dart:convert';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

class WebSocketService {
  static WebSocketService? _instance;
  static WebSocketService get instance => _instance ??= WebSocketService._();
  WebSocketService._();

  StompClient? _client;
  final List<Function(Map<String, dynamic>)> _groupListeners = [];
  bool _connected = false;

  void connect() {
    if (_connected) return;
    _client = StompClient(
      config: StompConfig(
        url: 'ws://10.0.2.2:8080/ws/websocket',
        onConnect: _onConnect,
        onDisconnect: (_) {
          _connected = false;
        },
        onStompError: (_) {
          _connected = false;
        },
        onWebSocketError: (_) {
          _connected = false;
        },
        reconnectDelay: const Duration(seconds: 5),
      ),
    );
    _client!.activate();
  }

  void _onConnect(StompFrame frame) {
    _connected = true;
    _client!.subscribe(
      destination: '/topic/groups',
      callback: (frame) {
        if (frame.body == null) return;
        try {
          final data = jsonDecode(frame.body!);
          for (final listener in _groupListeners) {
            listener(data);
          }
        } catch (_) {}
      },
    );
  }

  void addGroupListener(Function(Map<String, dynamic>) listener) {
    if (!_groupListeners.contains(listener)) {
      _groupListeners.add(listener);
    }
  }

  void removeGroupListener(Function(Map<String, dynamic>) listener) {
    _groupListeners.remove(listener);
  }

  void disconnect() {
    _client?.deactivate();
    _connected = false;
  }
}
