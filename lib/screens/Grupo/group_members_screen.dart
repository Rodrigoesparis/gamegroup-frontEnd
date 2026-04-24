import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class GroupMembersScreen extends StatefulWidget {
  final int groupId;
  final int currentUserId;

  const GroupMembersScreen({
    super.key,
    required this.groupId,
    required this.currentUserId,
  });

  @override
  State<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends State<GroupMembersScreen> {
  List<dynamic> _members = [];
  bool _loading = true;
  String? _myRole;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _loading = true);
    final members = await ApiService.getGroupMembers(widget.groupId);
    setState(() {
      _members = members;
      _loading = false;
      for (final m in members) {
        final userId = m['user']?['idUser'];
        if (userId == widget.currentUserId) {
          _myRole = m['role']?.toString();
          break;
        }
      }
    });
  }

  bool get _isLeader => _myRole == 'LIDER';

  // Expulsar — disponible para LIDER sobre cualquiera que no sea LIDER
  Future<void> _kickMember(int targetId) async {
    final confirm = await _showConfirmDialog('¿Expulsar a este jugador?');
    if (!confirm) return;

    final ok = await ApiService.kickMember(
      requesterId: widget.currentUserId,
      targetId: targetId,
      groupId: widget.groupId,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Jugador expulsado' : 'No se pudo expulsar'),
        backgroundColor: ok ? Colors.red : Colors.grey,
      ),
    );
    if (ok) _loadMembers();
  }

  // Ascender MIEMBRO → ADMIN
  Future<void> _promoteToAdmin(int targetId) async {
    final confirm = await _showConfirmDialog('¿Ascender a Admin?');
    if (!confirm) return;

    final ok = await ApiService.promoteToAdmin(
      leaderId: widget.currentUserId,
      targetId: targetId,
      groupId: widget.groupId,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Ascendido a Admin' : 'No se pudo ascender'),
        backgroundColor: ok ? const Color(0xFF7C3AED) : Colors.grey,
      ),
    );
    if (ok) _loadMembers();
  }

  // Degradar ADMIN → MIEMBRO
  Future<void> _demoteToMember(int targetId) async {
    final confirm = await _showConfirmDialog('¿Degradar a Miembro?');
    if (!confirm) return;

    final ok = await ApiService.demoteToMember(
      leaderId: widget.currentUserId,
      targetId: targetId,
      groupId: widget.groupId,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Degradado a Miembro' : 'No se pudo degradar'),
        backgroundColor: ok ? Colors.orange : Colors.grey,
      ),
    );
    if (ok) _loadMembers();
  }

  // Transferir liderazgo ADMIN → LIDER (el actual líder pasa a ADMIN)
  Future<void> _transferLeader(int targetId) async {
    final confirm = await _showConfirmDialog(
      '¿Hacer líder a este jugador? Tú pasarás a ser Admin.',
    );
    if (!confirm) return;

    final ok = await ApiService.transferLeader(
      currentLeaderId: widget.currentUserId,
      newLeaderId: targetId,
      groupId: widget.groupId,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Liderazgo transferido' : 'No se pudo transferir'),
        backgroundColor: ok ? Colors.amber : Colors.grey,
      ),
    );
    if (ok) _loadMembers();
  }

  Future<bool> _showConfirmDialog(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            title: Text(message, style: const TextStyle(color: Colors.white)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Confirmar',
                  style: TextStyle(color: Color(0xFF7C3AED)),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  // Muestra el menú de acciones al pulsar los 3 puntos
  void _showActionMenu(BuildContext context, int targetId, String targetRole) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // MIEMBRO → puede subir a Admin o ser expulsado
            if (targetRole == 'MIEMBRO') ...[
              ListTile(
                leading: const Icon(Icons.shield, color: Color(0xFF7C3AED)),
                title: const Text(
                  'Ascender a Admin',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _promoteToAdmin(targetId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_remove, color: Colors.red),
                title: const Text(
                  'Expulsar',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _kickMember(targetId);
                },
              ),
            ],
            // ADMIN → puede subir a Líder, bajar a Miembro o ser expulsado
            if (targetRole == 'ADMIN') ...[
              ListTile(
                leading: const Icon(Icons.emoji_events, color: Colors.amber),
                title: const Text(
                  'Transferir liderazgo',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _transferLeader(targetId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_downward, color: Colors.orange),
                title: const Text(
                  'Degradar a Miembro',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _demoteToMember(targetId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_remove, color: Colors.red),
                title: const Text(
                  'Expulsar',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _kickMember(targetId);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _roleIcon(String role) {
    switch (role) {
      case 'LIDER':
        return const Icon(Icons.emoji_events, color: Colors.amber, size: 18);
      case 'ADMIN':
        return const Icon(Icons.shield, color: Color(0xFF7C3AED), size: 18);
      default:
        return const Icon(Icons.person, color: Colors.grey, size: 18);
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
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.people, color: Colors.white),
                const SizedBox(width: 8),
                const Text(
                  'Miembros del grupo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (!_loading)
                  Text(
                    '${_members.length} jugadores',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
              ],
            ),
          ),
          const Divider(color: Colors.white12),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
                  )
                : ListView.builder(
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      final member = _members[index];
                      final user = member['user'] ?? {};
                      final role = (member['role'] ?? 'MIEMBRO').toString();
                      final memberId = user['idUser'];
                      final isMe = memberId == widget.currentUserId;
                      final isThisLeader = role == 'LIDER';

                      return ListTile(
                        leading: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(
                                0xFF7C3AED,
                              ).withOpacity(0.3),
                              child: Text(
                                (user['username'] ?? '?')
                                    .toString()
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isThisLeader)
                              const Positioned(
                                top: -8,
                                right: -4,
                                child: Icon(
                                  Icons.emoji_events,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                        title: Row(
                          children: [
                            Text(
                              user['username'] ?? 'Desconocido',
                              style: const TextStyle(color: Colors.white),
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
                        subtitle: Row(
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
                        // 3 puntos solo si soy líder y no es mi propio tile
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Botones de karma (a todos menos a uno mismo)
                            if (!isMe) ...[
                              IconButton(
                                icon: const Icon(
                                  Icons.thumb_up_outlined,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                tooltip: '+2 karma',
                                onPressed: () async {
                                  final result = await ApiService.voteKarma(
                                    voterId: widget.currentUserId,
                                    targetId: memberId,
                                    voteType: 'UP',
                                  );
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
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
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.thumb_down_outlined,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                tooltip: '-1 karma',
                                onPressed: () async {
                                  final result = await ApiService.voteKarma(
                                    voterId: widget.currentUserId,
                                    targetId: memberId,
                                    voteType: 'DOWN',
                                  );
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
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
                              ),
                            ],
                            // 3 puntos solo si soy líder y no es mi propio tile
                            if (_isLeader && !isMe)
                              IconButton(
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Colors.white54,
                                ),
                                onPressed: () =>
                                    _showActionMenu(context, memberId, role),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
