import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/voice_channel_service.dart';

class VoiceChannelOverlay extends StatefulWidget {
  final int groupId;
  final String groupName;
  final String userId;
  final List<dynamic> members; // los miembros que ya tienes cargados

  const VoiceChannelOverlay({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.userId,
    required this.members,
  });

  @override
  State<VoiceChannelOverlay> createState() => _VoiceChannelOverlayState();
}

class _VoiceChannelOverlayState extends State<VoiceChannelOverlay> {
  VoiceChannelService? _service;
  bool _connected = false;
  bool _muted = false;
  bool _connecting = false;
  final Set<String> _activeParticipants = {};

  @override
  void dispose() {
    _service?.leave();
    super.dispose();
  }

  Future<void> _join() async {
    // Pedir permiso de micrófono
    final status = await Permission.microphone.request();
    if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Necesitas permitir el micrófono')),
      );
      return;
    }

    setState(() => _connecting = true);

    _service = VoiceChannelService(
      userId: widget.userId,
      channelId: widget.groupId,
      onParticipantChanged: (uid, joined) {
        setState(() {
          if (joined)
            _activeParticipants.add(uid);
          else
            _activeParticipants.remove(uid);
        });
      },
    );

    await _service!.join();
    setState(() {
      _connected = true;
      _connecting = false;
      _activeParticipants.add(widget.userId);
    });
  }

  Future<void> _leave() async {
    await _service?.leave();
    setState(() {
      _connected = false;
      _activeParticipants.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Título
          Row(
            children: [
              const Icon(Icons.volume_up, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.groupName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_connected)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: Colors.green, size: 8),
                      SizedBox(width: 4),
                      Text(
                        'En vivo',
                        style: TextStyle(color: Colors.green, fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Participantes
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: widget.members.map((m) {
              final u = m['user'] ?? {};
              final uid = u['idUser'].toString();
              final username = u['username'] ?? '?';
              final isActive = _activeParticipants.contains(uid);
              final isMe = uid == widget.userId;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isActive ? Colors.green : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(
                            0xFF7C3AED,
                          ).withOpacity(isActive ? 0.6 : 0.2),
                          child: Text(
                            username.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      if (isMe && _muted)
                        const Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.red,
                            child: Icon(
                              Icons.mic_off,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isMe ? 'Tú' : username,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          // Controles
          if (!_connected)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _connecting ? null : _join,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _connecting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.call, color: Colors.white),
                label: Text(
                  _connecting ? 'Conectando...' : 'Unirse al canal de voz',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            )
          else
            Row(
              children: [
                // Mutear
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _muted = !_muted);
                      _service?.toggleMute(_muted);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: _muted ? Colors.red : Colors.grey,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(
                      _muted ? Icons.mic_off : Icons.mic,
                      color: _muted ? Colors.red : Colors.grey,
                    ),
                    label: Text(
                      _muted ? 'Silenciado' : 'Micrófono',
                      style: TextStyle(
                        color: _muted ? Colors.red : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Salir de la llamada
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _leave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.call_end, color: Colors.white),
                    label: const Text(
                      'Salir',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
