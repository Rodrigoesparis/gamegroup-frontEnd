import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../Grupo/group_detail_screen.dart';

class GroupsScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback? onGroupChanged;

  const GroupsScreen({super.key, required this.user, this.onGroupChanged});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  List<dynamic> _groups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
      );
    }

    if (_groups.isEmpty) {
      return const Center(
        child: Text(
          'No hay grupos disponibles',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF7C3AED),
      onRefresh: () async => _loadGroups(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
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
                    builder: (_) =>
                        GroupDetailScreen(group: group, user: widget.user),
                  ),
                );
                await Future.delayed(const Duration(milliseconds: 300));
                _loadGroups();
                widget.onGroupChanged?.call();
              },
            ),
          );
        },
      ),
    );
  }
}
