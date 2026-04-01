import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8080';

  // Login
  static Future<Map<String, dynamic>?> login(
    String username,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  // Registro
  static Future<Map<String, dynamic>?> register(
    String name,
    String username,
    String email,
    String password,
    int age,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'username': username,
        'email': email,
        'password': password,
        'age': age,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  // Listar grupos
  static Future<List<dynamic>> getGroups() async {
    final response = await http.get(Uri.parse('$baseUrl/groups'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  static Future<Map<String, dynamic>?> createGroup({
    required int creatorId,
    required String name,
    required String game,
    required String mode,
    required String privacy,
    required int maxPlayers,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/groups'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'creatorId': creatorId,
        'name': name,
        'game': game,
        'mode': mode,
        'privacy': privacy,
        'maxPlayers': maxPlayers,
      }),
    );

    print('STATUS: ${response.statusCode}');
    print('BODY: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getUserGroup(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/participants/user/$userId'),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map) return body as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> joinGroup({
    required int userId,
    required int groupId,
    String? password,
  }) async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/participants/join?userId=$userId&groupId=$groupId${password != null ? '&password=$password' : ''}',
      ),
      headers: {'Content-Type': 'application/json'},
    );
    return response.statusCode == 200;
  }
}
