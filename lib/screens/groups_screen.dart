import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'group_detail_screen.dart';
import 'create_group_screen.dart';
import 'chat_overlay.dart';
import 'profile_screen.dart';

class GroupsScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const GroupsScreen({super.key, required this.user});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  List<dynamic> _groups = [];
  bool _loading = true;
  Map<String, dynamic>? _userParticipant;

  @override
  void initState() {
    super.initState();
    _loadGroups();
    _loadUserGroup();
  }

  void _loadUserGroup() async {
    final result = await ApiService.getUserGroup(widget.user['idUser']);
    setState(() => _userParticipant = result);
  }

  void _loadGroups() async {
    final groups = await ApiService.getGroups();
    setState(() {
      _groups = groups;
      _loading = false;
    });
  }

  Color _privacyColor(String privacy) {
    switch (privacy) {
      case 'ABIERTO':
        return Colors.green;
      case 'SOLICITUD':
        return Colors.orange;
      case 'PRIVADO_PASSWORD':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _privacyLabel(String privacy) {
    switch (privacy) {
      case 'ABIERTO':
        return 'Abierto';
      case 'SOLICITUD':
        return 'Con solicitud';
      case 'PRIVADO_PASSWORD':
        return 'Privado';
      default:
        return privacy;
    }
  }

  void _openChat() {
    if (_userParticipant != null && _userParticipant!['group'] != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, controller) => ChatOverlay(
            groupName: _userParticipant!['group']['name'],
            groupId: _userParticipant!['group']['idGroup'],
            username: widget.user['username'],
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('Sin grupo', style: TextStyle(color: Colors.white)),
          content: const Text(
            '¡Únete o crea un grupo para chatear con tu equipo! 🎮',
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Entendido',
                style: TextStyle(color: Color(0xFF7C3AED)),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.sports_esports,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'GameReunion',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(
                  user: widget.user,
                  participant: _userParticipant,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF1A1A2E),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton(
              heroTag: 'chat',
              mini: true,
              backgroundColor: const Color(0xFF7C3AED),
              onPressed: _openChat,
              child: Icon(
                _userParticipant != null && _userParticipant!['group'] != null
                    ? Icons.chat
                    : Icons.chat_bubble_outline,
                color: Colors.white,
              ),
            ),
            FloatingActionButton.extended(
              heroTag: 'crear',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateGroupScreen(user: widget.user),
                  ),
                );
                if (result == true) {
                  _loadGroups();
                  _loadUserGroup();
                }
              },
              backgroundColor: const Color(0xFF7C3AED),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Crear', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _groups.length,
              itemBuilder: (context, index) {
                final group = _groups[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          group['name'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _privacyColor(
                              group['privacy'] ?? '',
                            ).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _privacyColor(group['privacy'] ?? ''),
                            ),
                          ),
                          child: Text(
                            _privacyLabel(group['privacy'] ?? ''),
                            style: TextStyle(
                              color: _privacyColor(group['privacy'] ?? ''),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          group['game'] ?? '',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
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
                            Text(
                              '${group['currentPlayers']}/${group['maxPlayers']}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GroupDetailScreen(
                            group: group,
                            user: widget.user,
                          ),
                        ),
                      );
                      await Future.delayed(const Duration(milliseconds: 300));
                      _loadUserGroup();
                      _loadGroups();
                    },
                  ),
                );
              },
            ),
    );
  }
}
