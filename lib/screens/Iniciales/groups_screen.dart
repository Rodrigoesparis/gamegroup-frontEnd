import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../Grupo/group_detail_screen.dart';
import '../Grupo/create_group_screen.dart';
import '../Grupo/chat_overlay.dart';
import '../Grupo/group_members_screen.dart';
import 'package:http/http.dart' as http;
import '../Grupo/voice_channel_overlay.dart';

class GroupsScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback? onGroupChanged;

  const GroupsScreen({super.key, required this.user, this.onGroupChanged});

  @override
  State<GroupsScreen> createState() => GroupsScreenState();
}

class GroupsScreenState extends State<GroupsScreen> {
  Map<String, dynamic>? _participant;
  bool _loading = true;

  void reload() => _loadUserGroup();

  @override
  void initState() {
    super.initState();
    _loadUserGroup();
  }

  Future<void> _loadUserGroup() async {
    setState(() => _loading = true);
    final result = await ApiService.getUserGroup(widget.user['idUser']);
    setState(() {
      _participant = result;
      _loading = false;
    });
    widget.onGroupChanged?.call();
  }

  void _openChat() {
    if (_participant == null || _participant!['group'] == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, controller) => ChatOverlay(
          groupName: _participant!['group']['name'],
          groupId: _participant!['group']['idGroup'],
          username: widget.user['username'],
          currentUserId: widget.user['idUser'],
        ),
      ),
    );
  }

  void _openMembers() {
    if (_participant == null || _participant!['group'] == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, __) => GroupMembersScreen(
          groupId: _participant!['group']['idGroup'],
          currentUserId: widget.user['idUser'],
        ),
      ),
    );
  }

  void _openDetail() {
    if (_participant == null || _participant!['group'] == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            GroupDetailScreen(group: _participant!['group'], user: widget.user),
      ),
    ).then((_) => _loadUserGroup());
  }

  Future<void> _leaveGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          '¿Salir del grupo?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Perderás el acceso al chat y a los miembros.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final response = await http.delete(
      Uri.parse(
        '${ApiService.baseUrl}/participants/leave?userId=${widget.user['idUser']}&groupId=${_participant!['group']['idGroup']}',
      ),
    );

    if (response.statusCode == 200) {
      await _loadUserGroup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Has salido del grupo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'LIDER':
        return 'Líder';
      case 'ADMIN':
        return 'Admin';
      default:
        return 'Miembro';
    }
  }

  Widget _roleIcon(String role) {
    switch (role) {
      case 'LIDER':
        return const Icon(Icons.emoji_events, color: Colors.amber, size: 16);
      case 'ADMIN':
        return const Icon(Icons.shield, color: Color(0xFF7C3AED), size: 16);
      default:
        return const Icon(Icons.person, color: Colors.grey, size: 16);
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'LIDER':
        return Colors.amber;
      case 'ADMIN':
        return const Color(0xFF7C3AED);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
      );
    }

    if (_participant == null || _participant!['group'] == null) {
      return _buildNoGroup();
    }

    return _buildMyGroup();
  }

  Widget _buildNoGroup() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.groups_outlined,
                size: 80,
                color: Color(0xFF7C3AED),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '¡Únete a un grupo!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Encuentra tu equipo, juega con otros y chatea con tus compañeros.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateGroupScreen(user: widget.user),
                    ),
                  );
                  if (result == true) _loadUserGroup();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Crear grupo',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => widget.onGroupChanged?.call(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFF7C3AED)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.search, color: Color(0xFF7C3AED)),
                label: const Text(
                  'Explorar grupos',
                  style: TextStyle(color: Color(0xFF7C3AED), fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyGroup() {
    final group = _participant!['group'] as Map<String, dynamic>;
    final role = (_participant!['role'] ?? 'MIEMBRO').toString();
    final maxPlayers = group['maxPlayers'] ?? 1;

    return RefreshIndicator(
      color: const Color(0xFF7C3AED),
      onRefresh: _loadUserGroup,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cabecera del grupo ─────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.sports_esports,
                          color: Color(0xFF7C3AED),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group['name'] ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              group['game'] ?? '',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Modo y rol
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          group['mode'] ?? '',
                          style: const TextStyle(
                            color: Color(0xFF7C3AED),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _roleColor(role).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _roleColor(role).withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _roleIcon(role),
                            const SizedBox(width: 4),
                            Text(
                              _roleLabel(role),
                              style: TextStyle(
                                color: _roleColor(role),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Acciones rápidas ───────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    icon: Icons.chat,
                    label: 'Chat',
                    color: const Color(0xFF7C3AED),
                    onTap: _openChat,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionButton(
                    icon: Icons.call,
                    label: 'Llamada',
                    color: Colors.blueAccent,
                    onTap: () {
                      // obtener miembros ya cargados del FutureBuilder
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => DraggableScrollableSheet(
                          initialChildSize: 0.6,
                          minChildSize: 0.4,
                          maxChildSize: 0.85,
                          builder: (_, __) => VoiceChannelOverlay(
                            groupId: _participant!['group']['idGroup'],
                            groupName: _participant!['group']['name'],
                            userId: widget.user['idUser'].toString(),
                            members: [], // se carga dentro del overlay
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionButton(
                    icon: Icons.info_outline,
                    label: 'Detalle',
                    color: Colors.teal,
                    onTap: _openDetail,
                  ),
                ),
              ],
            ),

            // Después del Row de acciones rápidas
            if (role == 'LIDER') ...[
              const SizedBox(height: 12),
              _PendingRequestsButton(
                groupId: group['idGroup'],
                currentUserId: widget.user['idUser'],
                onRequestHandled: _loadUserGroup,
              ),
            ],

            const SizedBox(height: 16),

            // ── Miembros + barra de progreso desde datos reales ────────────
            FutureBuilder<List<dynamic>>(
              future: ApiService.getGroupMembers(group['idGroup']),
              builder: (context, snapshot) {
                final members = snapshot.data ?? [];
                final currentPlayers = members.length;
                final progress = maxPlayers > 0
                    ? (currentPlayers / maxPlayers).clamp(0.0, 1.0)
                    : 0.0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barra de jugadores con datos reales
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Jugadores',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        Text(
                          '$currentPlayers / $maxPlayers',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white12,
                        color: const Color(0xFF7C3AED),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Miembros',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (!snapshot.hasData)
                      const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF7C3AED),
                        ),
                      )
                    else
                      ...members.map((m) {
                        final u = m['user'] ?? {};
                        final r = (m['role'] ?? 'MIEMBRO').toString();
                        final isMe = u['idUser'] == widget.user['idUser'];
                        final isLeader = r == 'LIDER';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A2E),
                            borderRadius: BorderRadius.circular(12),
                            border: isMe
                                ? Border.all(
                                    color: const Color(
                                      0xFF7C3AED,
                                    ).withOpacity(0.5),
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(
                                      0xFF7C3AED,
                                    ).withOpacity(0.3),
                                    child: Text(
                                      (u['username'] ?? '?')
                                          .toString()
                                          .substring(0, 1)
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (isLeader)
                                    const Positioned(
                                      top: -6,
                                      right: -4,
                                      child: Icon(
                                        Icons.emoji_events,
                                        color: Colors.amber,
                                        size: 14,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(
                                      u['username'] ?? 'Desconocido',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (isMe) ...[
                                      const SizedBox(width: 6),
                                      const Text(
                                        '(tú)',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _roleIcon(r),
                                  const SizedBox(width: 4),
                                  Text(
                                    _roleLabel(r),
                                    style: TextStyle(
                                      color: _roleColor(r),
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (!isMe) ...[
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () async {
                                        final result =
                                            await ApiService.voteKarma(
                                              voterId: widget.user['idUser'],
                                              targetId: u['idUser'],
                                              voteType: 'UP',
                                            );
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              result['success']
                                                  ? '👍 +2 karma otorgado'
                                                  : result['message'] ??
                                                        'Ya votaste a este usuario',
                                            ),
                                            backgroundColor: result['success']
                                                ? const Color(0xFF1A1A2E)
                                                : Colors.red,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                      child: const Icon(
                                        Icons.thumb_up_outlined,
                                        color: Colors.green,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () async {
                                        final result =
                                            await ApiService.voteKarma(
                                              voterId: widget.user['idUser'],
                                              targetId: u['idUser'],
                                              voteType: 'DOWN',
                                            );
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              result['success']
                                                  ? '👎 -1 karma aplicado'
                                                  : result['message'] ??
                                                        'Ya votaste a este usuario',
                                            ),
                                            backgroundColor: result['success']
                                                ? const Color(0xFF1A1A2E)
                                                : Colors.red,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                      child: const Icon(
                                        Icons.thumb_down_outlined,
                                        color: Colors.red,
                                        size: 18,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),

            // ── Botón salir ────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _leaveGroup,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.exit_to_app, color: Colors.red),
                label: const Text(
                  'Salir del grupo',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingRequestsButton extends StatefulWidget {
  final int groupId;
  final int currentUserId;
  final VoidCallback onRequestHandled;

  const _PendingRequestsButton({
    required this.groupId,
    required this.currentUserId,
    required this.onRequestHandled,
  });

  @override
  State<_PendingRequestsButton> createState() => _PendingRequestsButtonState();
}

class _PendingRequestsButtonState extends State<_PendingRequestsButton> {
  List<dynamic> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    final requests = await ApiService.getGroupRequests(widget.groupId);
    setState(() {
      _requests = requests;
      _loading = false;
    });
  }

  Future<void> _handleRequest(int requestId, bool accept) async {
    final ok = accept
        ? await ApiService.acceptRequest(
            requestId: requestId,
            leaderId: widget.currentUserId,
          )
        : await ApiService.rejectRequest(
            requestId: requestId,
            leaderId: widget.currentUserId,
          );

    if (ok) {
      await _loadRequests();
      widget.onRequestHandled();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    if (_requests.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_add, color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              Text(
                'Solicitudes pendientes (${_requests.length})',
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._requests.map((r) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF7C3AED).withOpacity(0.3),
                    radius: 18,
                    child: Text(
                      (r['username'] ?? '?')
                          .toString()
                          .substring(0, 1)
                          .toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      r['username'] ?? '',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  // Aceptar
                  IconButton(
                    icon: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 28,
                    ),
                    onPressed: () => _handleRequest(r['id'], true),
                    tooltip: 'Aceptar',
                  ),
                  // Rechazar
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red, size: 28),
                    onPressed: () => _handleRequest(r['id'], false),
                    tooltip: 'Rechazar',
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
