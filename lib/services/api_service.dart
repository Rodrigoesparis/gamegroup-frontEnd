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
  static Future<List<dynamic>> getGroups(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/groups?userId=$userId'),
    );
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
    String? password, // NUEVO
  }) async {
    final body = {
      'creatorId': creatorId,
      'name': name,
      'game': game,
      'mode': mode,
      'privacy': privacy,
      'maxPlayers': maxPlayers,
      if (password != null && password.isNotEmpty)
        'password': password, // NUEVO
    };

    final response = await http.post(
      Uri.parse('$baseUrl/groups'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
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

  // Listar miembros de un grupo
  static Future<List<dynamic>> getGroupMembers(int groupId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/participants/$groupId'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Expulsar miembro
  static Future<bool> kickMember({
    required int requesterId,
    required int targetId,
    required int groupId,
  }) async {
    final response = await http.delete(
      Uri.parse(
        '$baseUrl/participants/kick?requesterId=$requesterId&targetId=$targetId&groupId=$groupId',
      ),
    );
    return response.statusCode == 200;
  }

  // Ascender a admin
  static Future<bool> promoteToAdmin({
    required int leaderId,
    required int targetId,
    required int groupId,
  }) async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/groups/$groupId/promote?liderActualId=$leaderId&targetUserId=$targetId',
      ),
    );
    return response.statusCode == 200;
  }

  // Transferir liderazgo (el actual líder pasa a ADMIN)
  static Future<bool> transferLeader({
    required int currentLeaderId,
    required int newLeaderId,
    required int groupId,
  }) async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/groups/$groupId/transfer-leader?liderActualId=$currentLeaderId&nuevoLiderId=$newLeaderId',
      ),
    );
    return response.statusCode == 200;
  }

  // Degradar ADMIN → MIEMBRO
  static Future<bool> demoteToMember({
    required int leaderId,
    required int targetId,
    required int groupId,
  }) async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/groups/$groupId/demote?liderActualId=$leaderId&targetUserId=$targetId',
      ),
    );
    return response.statusCode == 200;
  }

  static Future<List<dynamic>> getChatHistory(int groupId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat/$groupId/history'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Enviar solicitud para unirse
  static Future<Map<String, dynamic>> sendJoinRequest({
    required int userId,
    required int groupId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/requests/send?userId=$userId&groupId=$groupId'),
    );
    return {'success': response.statusCode == 200, 'message': response.body};
  }

  // Obtener solicitudes pendientes del grupo
  static Future<List<dynamic>> getGroupRequests(int groupId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/requests/group/$groupId'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Aceptar solicitud
  static Future<bool> acceptRequest({
    required int requestId,
    required int leaderId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/requests/$requestId/accept?leaderId=$leaderId'),
    );
    return response.statusCode == 200;
  }

  // Rechazar solicitud
  static Future<bool> rejectRequest({
    required int requestId,
    required int leaderId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/requests/$requestId/reject?leaderId=$leaderId'),
    );
    return response.statusCode == 200;
  }

  // Obtener ranking de karma
  static Future<List<dynamic>> getKarmaRanking() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/karma/ranking'));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  // Votar a un usuario
  static Future<Map<String, dynamic>> voteKarma({
    required int voterId,
    required int targetId,
    required String voteType, // 'UP' o 'DOWN'
  }) async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/karma/vote?voterId=$voterId&targetId=$targetId&voteType=$voteType',
      ),
    );
    return {'success': response.statusCode == 200, 'message': response.body};
  }
}
