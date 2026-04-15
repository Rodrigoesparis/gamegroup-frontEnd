import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'api_service.dart'; // ya lo tienes

class VoiceChannelService {
  StompClient? _stompClient;
  MediaStream? _localStream;
  final Map<String, RTCPeerConnection> _peers = {};

  final String userId;
  final int channelId;
  final Function(String userId, bool joined)? onParticipantChanged;

  VoiceChannelService({
    required this.userId,
    required this.channelId,
    this.onParticipantChanged,
  });

  // STUN gratuito de Google — sin servidor propio
  final Map<String, dynamic> _rtcConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
  };

  Future<void> join() async {
    // Capturar micrófono
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });

    _stompClient = StompClient(
      config: StompConfig(
        url: '${ApiService.baseUrl.replaceFirst('http', 'ws')}/ws/websocket',
        onConnect: _onConnected,
        onWebSocketError: (e) => print('WS Error: $e'),
        reconnectDelay: const Duration(seconds: 3),
      ),
    );
    _stompClient!.activate();
  }

  void _onConnected(StompFrame frame) {
    // Escuchar eventos del canal (entradas/salidas)
    _stompClient!.subscribe(
      destination: '/topic/voice/$channelId',
      callback: _onChannelEvent,
    );

    // Escuchar señales WebRTC dirigidas a mí
    _stompClient!.subscribe(
      destination: '/topic/voice/signal/$userId',
      callback: _onSignalReceived,
    );

    // Avisar que entré
    _stompClient!.send(
      destination: '/app/voice/join',
      body: jsonEncode({'channelId': channelId, 'userId': userId}),
    );
  }

  void _onChannelEvent(StompFrame frame) {
    final data = jsonDecode(frame.body!);
    final type = data['type'];
    final peerId = data['userId'].toString();

    if (peerId == userId) return; // ignorar mis propios eventos

    if (type == 'USER_JOINED') {
      // El que ya estaba crea la oferta al nuevo
      _createOffer(peerId);
      onParticipantChanged?.call(peerId, true);
    } else if (type == 'USER_LEFT') {
      _removePeer(peerId);
      onParticipantChanged?.call(peerId, false);
    }
  }

  void _onSignalReceived(StompFrame frame) {
    final data = jsonDecode(frame.body!);
    final peerId = data['fromUserId'].toString();
    final type = data['type'];

    switch (type) {
      case 'offer':
        _handleOffer(peerId, data['sdp']);
        break;
      case 'answer':
        _handleAnswer(peerId, data['sdp']);
        break;
      case 'ice':
        _handleIce(peerId, data);
        break;
    }
  }

  Future<RTCPeerConnection> _getOrCreatePeer(String peerId) async {
    if (_peers.containsKey(peerId)) return _peers[peerId]!;

    final pc = await createPeerConnection(_rtcConfig);
    _peers[peerId] = pc;

    // Añadir audio local
    _localStream?.getTracks().forEach((t) => pc.addTrack(t, _localStream!));

    // Enviar ICE candidates al peer
    pc.onIceCandidate = (candidate) {
      if (candidate.candidate == null) return;
      _stompClient!.send(
        destination: '/app/voice/signal',
        body: jsonEncode({
          'targetUserId': peerId,
          'fromUserId': userId,
          'type': 'ice',
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        }),
      );
    };

    // Audio remoto — se reproduce automáticamente
    pc.onTrack = (event) {
      print('Audio recibido de $peerId');
    };

    return pc;
  }

  Future<void> _createOffer(String peerId) async {
    final pc = await _getOrCreatePeer(peerId);
    final offer = await pc.createOffer({'offerToReceiveAudio': true});
    await pc.setLocalDescription(offer);

    _stompClient!.send(
      destination: '/app/voice/signal',
      body: jsonEncode({
        'targetUserId': peerId,
        'fromUserId': userId,
        'type': 'offer',
        'sdp': offer.sdp,
      }),
    );
  }

  Future<void> _handleOffer(String peerId, String sdp) async {
    final pc = await _getOrCreatePeer(peerId);
    await pc.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));
    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);

    _stompClient!.send(
      destination: '/app/voice/signal',
      body: jsonEncode({
        'targetUserId': peerId,
        'fromUserId': userId,
        'type': 'answer',
        'sdp': answer.sdp,
      }),
    );
  }

  Future<void> _handleAnswer(String peerId, String sdp) async {
    await _peers[peerId]?.setRemoteDescription(
      RTCSessionDescription(sdp, 'answer'),
    );
  }

  Future<void> _handleIce(String peerId, Map data) async {
    await _peers[peerId]?.addCandidate(
      RTCIceCandidate(data['candidate'], data['sdpMid'], data['sdpMLineIndex']),
    );
  }

  void toggleMute(bool muted) {
    _localStream?.getAudioTracks().forEach((t) => t.enabled = !muted);
  }

  void _removePeer(String peerId) {
    _peers[peerId]?.close();
    _peers.remove(peerId);
  }

  Future<void> leave() async {
    _stompClient?.send(
      destination: '/app/voice/leave',
      body: jsonEncode({'channelId': channelId, 'userId': userId}),
    );
    for (final pc in _peers.values) await pc.close();
    _peers.clear();
    _localStream?.dispose();
    _stompClient?.deactivate();
  }
}
