import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'dart:convert';
import 'group_members_screen.dart';
import 'package:GameReunion_app/services/api_service.dart';

class ChatOverlay extends StatefulWidget {
  final String groupName;
  final int groupId;
  final String username;
  final int currentUserId;

  const ChatOverlay({
    super.key,
    required this.groupName,
    required this.groupId,
    required this.username,
    required this.currentUserId,
  });

  @override
  State<ChatOverlay> createState() => _ChatOverlayState();
}

class _ChatOverlayState extends State<ChatOverlay> {
  final _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  late StompClient _stompClient;
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _connectWebSocket();
  }

  Future<void> _loadHistory() async {
    final history = await ApiService.getChatHistory(widget.groupId);
    setState(() {
      for (final msg in history) {
        _messages.add({
          'sender': msg['sender'],
          'text': msg['text'],
          'time': msg['time'],
          'isMe': msg['sender'] == widget.username,
        });
      }
    });
  }

  void _connectWebSocket() {
    _stompClient = StompClient(
      config: StompConfig(
        url: 'ws://10.0.2.2:8080/ws/websocket',
        onConnect: _onConnect,
        onDisconnect: (_) => setState(() => _connected = false),
        onWebSocketError: (error) => print('WebSocket ERROR: $error'),
        onStompError: (frame) => print('STOMP ERROR: ${frame.body}'),
        stompConnectHeaders: {'heart-beat': '0,0'},
        webSocketConnectHeaders: {'heart-beat': '0,0'},
      ),
    );
    _stompClient.activate();
  }

  void _onConnect(StompFrame frame) {
    setState(() => _connected = true);
    _stompClient.subscribe(
      destination: '/topic/chat/${widget.groupId}',
      callback: (frame) {
        if (frame.body != null) {
          final msg = jsonDecode(frame.body!);
          setState(() {
            _messages.add({
              'sender': msg['sender'],
              'text': msg['text'],
              'time': msg['time'],
              'isMe': msg['sender'] == widget.username,
            });
          });
        }
      },
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || !_connected) return;
    final now = DateTime.now();
    final time = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    _stompClient.send(
      destination: '/app/chat/${widget.groupId}',
      body: jsonEncode({
        'sender': widget.username,
        'text': _messageController.text,
        'time': time,
      }),
    );
    _messageController.clear();
  }

  // NUEVO — abre el bottom sheet de miembros
  void _openMembers() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) => GroupMembersScreen(
          groupId: widget.groupId,
          currentUserId: widget.currentUserId,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stompClient.deactivate();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F13),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header con nombre tappable
          GestureDetector(
            onTap: _openMembers, // NUEVO
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(color: Color(0xFF1A1A2E)),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.people,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.groupName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            // NUEVO — indicador visual de que es tappable
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.white54,
                              size: 16,
                            ),
                          ],
                        ),
                        Text(
                          _connected ? 'Conectado' : 'Conectando...',
                          style: TextStyle(
                            color: _connected ? Colors.green : Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
          // Mensajes
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'No hay mensajes aún',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['isMe'] as bool;
                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                Text(
                                  msg['sender'],
                                  style: const TextStyle(
                                    color: Color(0xFF7C3AED),
                                    fontSize: 12,
                                  ),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? const Color(0xFF7C3AED)
                                      : const Color(0xFF1A1A2E),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  msg['text'],
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              Text(
                                msg['time'],
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Input
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1A1A2E),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF0F0F13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF7C3AED),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
