import 'package:flutter/material.dart';

class ServersScreen extends StatelessWidget {
  final Map<String, dynamic> user;
  const ServersScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.dns_outlined, size: 80, color: Colors.white24),
          const SizedBox(height: 16),
          const Text(
            'Servidores',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Próximamente', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
