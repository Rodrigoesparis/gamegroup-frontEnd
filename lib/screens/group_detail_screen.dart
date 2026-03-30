import 'package:flutter/material.dart';

class GroupDetailScreen extends StatelessWidget {
  final Map<String, dynamic> group;
  final Map<String, dynamic> user;

  const GroupDetailScreen({super.key, required this.group, required this.user});

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
                          group['name'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
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
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.people, color: Colors.grey, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${group['currentPlayers']}/${group['maxPlayers']} jugadores',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Unirse al grupo',
                          style: TextStyle(color: Colors.white),
                        ),
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
