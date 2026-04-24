import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class RankingScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const RankingScreen({super.key, required this.user});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  List<dynamic> _ranking = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRanking();
  }

  Future<void> _loadRanking() async {
    setState(() => _loading = true);
    final data = await ApiService.getKarmaRanking();
    setState(() {
      _ranking = data;
      _loading = false;
    });
  }

  Future<void> _vote(int targetId, String voteType) async {
    final result = await ApiService.voteKarma(
      voterId: widget.user['idUser'],
      targetId: targetId,
      voteType: voteType,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['success']
              ? voteType == 'UP'
                    ? '👍 +2 karma otorgado'
                    : '👎 -1 karma aplicado'
              : result['message'] ?? 'No se pudo votar',
        ),
        backgroundColor: result['success']
            ? const Color(0xFF1A1A2E)
            : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (result['success']) _loadRanking();
  }

  Color _karmaColor(int karma) {
    if (karma >= 1500) return Colors.amber;
    if (karma >= 1100) return Colors.green;
    if (karma >= 900) return Colors.white;
    return Colors.red;
  }

  Widget _medalWidget(int position) {
    switch (position) {
      case 0:
        return const Text('🥇', style: TextStyle(fontSize: 22));
      case 1:
        return const Text('🥈', style: TextStyle(fontSize: 22));
      case 2:
        return const Text('🥉', style: TextStyle(fontSize: 22));
      default:
        return Text(
          '#${position + 1}',
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(0xFF7C3AED),
      onRefresh: _loadRanking,
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: _ranking.length,
              itemBuilder: (context, index) {
                final u = _ranking[index];
                final isMe = u['idUser'] == widget.user['idUser'];
                final karma = u['karma'] ?? 1000;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(14),
                    border: isMe
                        ? Border.all(
                            color: const Color(0xFF7C3AED).withOpacity(0.6),
                          )
                        : index < 3
                        ? Border.all(color: Colors.amber.withOpacity(0.3))
                        : null,
                  ),
                  child: Row(
                    children: [
                      // Posición
                      SizedBox(
                        width: 36,
                        child: Center(child: _medalWidget(index)),
                      ),
                      const SizedBox(width: 12),

                      // Avatar
                      CircleAvatar(
                        backgroundColor: const Color(
                          0xFF7C3AED,
                        ).withOpacity(0.3),
                        child: Text(
                          (u['username'] ?? '?')
                              .toString()
                              .substring(0, 1)
                              .toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Nombre y karma
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  u['username'] ?? 'Desconocido',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 6),
                                  const Text(
                                    '(tú)',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.bolt,
                                  color: Colors.amber,
                                  size: 14,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '$karma karma',
                                  style: TextStyle(
                                    color: _karmaColor(karma),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
