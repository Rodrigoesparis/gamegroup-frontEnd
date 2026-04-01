import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../Grupo/group_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const SearchScreen({super.key, required this.user});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<dynamic> _allGroups = [];
  List<dynamic> _results = [];
  bool _loading = false;
  String _filter = 'todos'; // todos, grupos, servidores

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  void _loadAll() async {
    setState(() => _loading = true);
    final groups = await ApiService.getGroups();
    setState(() {
      _allGroups = groups;
      _results = groups;
      _loading = false;
    });
  }

  void _search(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      if (q.isEmpty) {
        _results = _allGroups;
      } else {
        _results = _allGroups.where((g) {
          final name = (g['name'] ?? '').toString().toLowerCase();
          final game = (g['game'] ?? '').toString().toLowerCase();
          return name.contains(q) || game.contains(q);
        }).toList();
      }
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra de búsqueda
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            onChanged: _search,
            decoration: InputDecoration(
              hintText: 'Buscar grupos o servidores...',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        _search('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF1A1A2E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        // Filtros
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              _filterChip('todos', 'Todos'),
              const SizedBox(width: 8),
              _filterChip('grupos', 'Grupos'),
              const SizedBox(width: 8),
              _filterChip('servidores', 'Servidores'),
            ],
          ),
        ),
        // Resultados
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
                )
              : _results.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.search_off,
                        color: Colors.white24,
                        size: 60,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _searchController.text.isEmpty
                            ? 'Escribe para buscar'
                            : 'Sin resultados para "${_searchController.text}"',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final group = _results[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.groups,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                        title: Text(
                          group['name'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              group['game'] ?? '',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _privacyColor(
                                      group['privacy'] ?? '',
                                    ).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _privacyColor(
                                        group['privacy'] ?? '',
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    _privacyLabel(group['privacy'] ?? ''),
                                    style: TextStyle(
                                      color: _privacyColor(
                                        group['privacy'] ?? '',
                                      ),
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${group['currentPlayers']}/${group['maxPlayers']} jugadores',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GroupDetailScreen(
                              group: group,
                              user: widget.user,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String value, String label) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF7C3AED) : const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF7C3AED) : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white54,
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
