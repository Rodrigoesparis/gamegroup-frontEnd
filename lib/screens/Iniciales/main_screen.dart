import 'package:flutter/material.dart';
import 'groups_screen.dart';
import 'servers_screen.dart';
import 'search_screen.dart';
import '../chat_overlay.dart';
import '../Grupo/create_group_screen.dart';
import '../Registro/profile_screen.dart';
import '../../services/api_service.dart';

class MainScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const MainScreen({super.key, required this.user});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? _userParticipant;

  @override
  void initState() {
    super.initState();
    _loadUserGroup();
  }

  void _loadUserGroup() async {
    final result = await ApiService.getUserGroup(widget.user['idUser']);
    setState(() => _userParticipant = result);
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
            currentUserId: widget.user['idUser'],
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

  void _openCreate() async {
    if (_currentIndex == 0) {
      // Crear grupo
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CreateGroupScreen(user: widget.user)),
      );
      if (result == true) _loadUserGroup();
    } else if (_currentIndex == 1) {
      // Crear servidor — de momento placeholder
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text(
            'Próximamente',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'La creación de servidores estará disponible pronto.',
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

  String get _fabLabel {
    switch (_currentIndex) {
      case 0:
        return 'Crear grupo';
      case 1:
        return 'Crear servidor';
      default:
        return '';
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
          // Botón chat solo en grupos y servidores
          if (_currentIndex != 2)
            IconButton(
              icon: Icon(
                _userParticipant != null && _userParticipant!['group'] != null
                    ? Icons.chat
                    : Icons.chat_bubble_outline,
                color: Colors.white,
              ),
              onPressed: _openChat,
            ),
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
      // FAB solo en grupos y servidores, no en búsqueda
      floatingActionButton: _currentIndex != 2
          ? FloatingActionButton.extended(
              onPressed: _openCreate,
              backgroundColor: const Color(0xFF7C3AED),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                _fabLabel,
                style: const TextStyle(color: Colors.white),
              ),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF1A1A2E),
        indicatorColor: const Color(0xFF7C3AED).withOpacity(0.3),
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.groups_outlined, color: Colors.white54),
            selectedIcon: Icon(Icons.groups, color: Color(0xFF7C3AED)),
            label: 'Grupos',
          ),
          NavigationDestination(
            icon: Icon(Icons.dns_outlined, color: Colors.white54),
            selectedIcon: Icon(Icons.dns, color: Color(0xFF7C3AED)),
            label: 'Servidores',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined, color: Colors.white54),
            selectedIcon: Icon(Icons.search, color: Color(0xFF7C3AED)),
            label: 'Buscar',
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          GroupsScreen(user: widget.user, onGroupChanged: _loadUserGroup),
          ServersScreen(user: widget.user),
          SearchScreen(user: widget.user),
        ],
      ),
    );
  }
}
