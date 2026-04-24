import 'package:flutter/material.dart';
import 'groups_screen.dart';
import 'servers_screen.dart';
import 'search_screen.dart';
import '../Grupo/chat_overlay.dart';
import '../Registro/profile_screen.dart';
import '../../services/api_service.dart';
import '../../services/websocket_service.dart';
import 'dart:async';
import 'ranking_screen.dart';

class MainScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const MainScreen({super.key, required this.user});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? _userParticipant;
  final _groupsKey = GlobalKey<GroupsScreenState>();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadUserGroup();
    WebSocketService.instance.connect();
    WebSocketService.instance.addGroupListener(_onGroupEvent);
  }

  void _onGroupEvent(Map<String, dynamic> event) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _loadUserGroup();
      _groupsKey.currentState?.reload();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    WebSocketService.instance.removeGroupListener(_onGroupEvent);
    super.dispose();
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
    if (_currentIndex == 1) {
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
          if (_currentIndex == 1 || _currentIndex == 2)
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
      // FAB solo en Servidores
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: _openCreate,
              backgroundColor: const Color(0xFF7C3AED),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Crear servidor',
                style: TextStyle(color: Colors.white),
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
            label: 'Mi grupo',
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
          NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined, color: Colors.white54),
            selectedIcon: Icon(Icons.leaderboard, color: Color(0xFF7C3AED)),
            label: 'Ranking',
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          GroupsScreen(
            key: _groupsKey,
            user: widget.user,
            onGroupChanged: () {
              _loadUserGroup();
              setState(() => _currentIndex = 2);
            },
          ),
          ServersScreen(user: widget.user),
          SearchScreen(
            user: widget.user,
            onJoinedGroup: () {
              // NUEVO
              _groupsKey.currentState?.reload();
              _loadUserGroup();
            },
          ),
          RankingScreen(user: widget.user),
        ],
      ),
    );
  }
}
