import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class CreateGroupScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const CreateGroupScreen({super.key, required this.user});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _gameController = TextEditingController();
  final _maxPlayersController = TextEditingController(text: '5');
  final _passwordController = TextEditingController();
  String _mode = 'CASUAL';
  String _privacy = 'ABIERTO';
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _gameController.dispose();
    _maxPlayersController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _createGroup() async {
    // Validar que si es privado con contraseña, haya contraseña
    if (_privacy == 'PRIVADO_PASSWORD' &&
        _passwordController.text.trim().isEmpty) {
      setState(() => _error = 'Debes introducir una contraseña para el grupo');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await ApiService.createGroup(
      creatorId: widget.user['idUser'],
      name: _nameController.text,
      game: _gameController.text,
      mode: _mode,
      privacy: _privacy,
      maxPlayers: int.tryParse(_maxPlayersController.text) ?? 5,
      password: _privacy == 'PRIVADO_PASSWORD'
          ? _passwordController.text.trim()
          : null,
    );

    setState(() => _loading = false);

    if (result != null) {
      Navigator.pop(context, true);
    } else {
      setState(() => _error = 'Error al crear el grupo');
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
        title: const Text('Crear Grupo', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
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
              const Text(
                'Nombre del grupo',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Warriors Elite'),
              ),
              const SizedBox(height: 16),

              const Text('Juego', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              TextField(
                controller: _gameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Valorant, DBD...'),
              ),
              const SizedBox(height: 16),

              const Text(
                'Modo de juego',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _mode,
                dropdownColor: const Color(0xFF0F0F13),
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(''),
                items: ['CASUAL', 'COMPETITIVO', 'PERSONALIZADO']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) => setState(() => _mode = v!),
              ),
              const SizedBox(height: 16),

              const Text('Privacidad', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _privacy,
                dropdownColor: const Color(0xFF0F0F13),
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(''),
                items: [
                  DropdownMenuItem(
                    value: 'ABIERTO',
                    child: const Text('Abierto (cualquiera puede unirse)'),
                  ),
                  DropdownMenuItem(
                    value: 'SOLICITUD',
                    child: const Text('Con solicitud'),
                  ),
                  DropdownMenuItem(
                    value: 'PRIVADO_PASSWORD',
                    child: const Text('Privado con contraseña'),
                  ),
                ],
                onChanged: (v) => setState(() {
                  _privacy = v!;
                  // Limpiar contraseña si cambia a otro modo
                  if (_privacy != 'PRIVADO_PASSWORD') {
                    _passwordController.clear();
                  }
                }),
              ),

              // NUEVO — campo de contraseña visible solo si es PRIVADO_PASSWORD
              if (_privacy == 'PRIVADO_PASSWORD') ...[
                const SizedBox(height: 16),
                const Text(
                  'Contraseña del grupo',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Introduce una contraseña')
                      .copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Los jugadores necesitarán esta contraseña para unirse',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],

              const SizedBox(height: 16),
              const Text(
                'Número máximo de jugadores',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _maxPlayersController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('5'),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _createGroup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Crear Grupo',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFF0F0F13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    );
  }
}
