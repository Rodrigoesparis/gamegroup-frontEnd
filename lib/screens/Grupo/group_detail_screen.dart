import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';
import 'group_members_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final Map<String, dynamic> group;
  final Map<String, dynamic> user;

  const GroupDetailScreen({super.key, required this.group, required this.user});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  bool _loading = false;
  bool _alreadyInGroup = false;
  bool _isThisGroup = false;

  @override
  void initState() {
    super.initState();
    _checkUserGroup();
  }

  void _checkUserGroup() async {
    final result = await ApiService.getUserGroup(widget.user['idUser']);
    if (result != null && result['group'] != null) {
      setState(() {
        _alreadyInGroup = true;
        _isThisGroup = result['group']['idGroup'] == widget.group['idGroup'];
      });
    }
  }

  void _joinGroup() async {
    if (widget.group['privacy'] == 'SOLICITUD') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text(
            'Solicitar unirse',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Se enviará una solicitud al líder del grupo. Tendrá que aceptarla para que puedas entrar.',
            style: TextStyle(color: Colors.grey),
          ),
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
                'Enviar solicitud',
                style: TextStyle(color: Color(0xFF7C3AED)),
              ),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      setState(() => _loading = true);
      final result = await ApiService.sendJoinRequest(
        userId: widget.user['idUser'],
        groupId: widget.group['idGroup'],
      );
      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? ''),
          backgroundColor: result['success'] == true
              ? const Color(0xFF7C3AED)
              : Colors.red,
        ),
      );
      return;
    }
    if (widget.group['privacy'] == 'PRIVADO_PASSWORD') {
      final passwordController = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text(
            'Grupo privado',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Contraseña del grupo',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF0F0F13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
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
                'Entrar',
                style: TextStyle(color: Color(0xFF7C3AED)),
              ),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      setState(() => _loading = true);
      final result = await ApiService.joinGroup(
        userId: widget.user['idUser'],
        groupId: widget.group['idGroup'],
        password: passwordController.text,
      );
      setState(() => _loading = false);

      if (result == true) {
        setState(() {
          _alreadyInGroup = true;
          _isThisGroup = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Te has unido al grupo!'),
            backgroundColor: Color(0xFF7C3AED),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contraseña incorrecta'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Grupo abierto o solicitud
    setState(() => _loading = true);
    final result = await ApiService.joinGroup(
      userId: widget.user['idUser'],
      groupId: widget.group['idGroup'],
    );
    setState(() => _loading = false);

    if (result == true) {
      setState(() {
        _alreadyInGroup = true;
        _isThisGroup = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Te has unido al grupo!'),
          backgroundColor: Color(0xFF7C3AED),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes unirte a este grupo'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _leaveGroup() async {
    setState(() => _loading = true);
    final response = await http.delete(
      Uri.parse(
        '${ApiService.baseUrl}/participants/leave?userId=${widget.user['idUser']}&groupId=${widget.group['idGroup']}',
      ),
    );
    setState(() => _loading = false);

    if (response.statusCode == 200) {
      setState(() {
        _alreadyInGroup = false;
        _isThisGroup = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Has salido del grupo'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
          groupId: widget.group['idGroup'],
          currentUserId: widget.user['idUser'],
        ),
      ),
    );
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
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detalle del Grupo',
          style: TextStyle(color: Colors.white),
        ),
        // NUEVO — icono de miembros en el AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.people, color: Colors.white),
            tooltip: 'Ver miembros',
            onPressed: _openMembers,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            Container(
              width: double.infinity,
              height: 180,
              color: const Color(0xFF1A1A2E),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(
                      Icons.sports_esports,
                      size: 80,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.group['name'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.group['game'] ?? '',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _privacyColor(
                              widget.group['privacy'] ?? '',
                            ).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _privacyColor(
                                widget.group['privacy'] ?? '',
                              ),
                            ),
                          ),
                          child: Text(
                            _privacyLabel(widget.group['privacy'] ?? ''),
                            style: TextStyle(
                              color: _privacyColor(
                                widget.group['privacy'] ?? '',
                              ),
                              fontSize: 12,
                            ),
                          ),
                        ),
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
                            widget.group['mode'] ?? '',
                            style: const TextStyle(
                              color: Color(0xFF7C3AED),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.people, color: Colors.grey, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.group['currentPlayers']}/${widget.group['maxPlayers']} jugadores',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Botones unirse/salir
                    if (_isThisGroup) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Ya eres miembro',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _loading ? null : _leaveGroup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _loading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Icon(
                                    Icons.exit_to_app,
                                    color: Colors.white,
                                  ),
                          ),
                        ],
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _alreadyInGroup ? null : _joinGroup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _alreadyInGroup
                                ? Colors.grey
                                : const Color(0xFF7C3AED),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  _alreadyInGroup
                                      ? 'Ya estás en otro grupo'
                                      : 'Unirse al grupo',
                                  style: const TextStyle(color: Colors.white),
                                ),
                        ),
                      ),
                    ],

                    // NUEVO — botón Ver miembros
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(
                          Icons.people_outline,
                          color: Colors.white70,
                        ),
                        label: const Text(
                          'Ver miembros',
                          style: TextStyle(color: Colors.white70),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _openMembers,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
