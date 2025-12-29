import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/widgets/player_info_card.dart';
import 'package:myapp/widgets/player_stats_card.dart';
import 'package:myapp/widgets/radar_chart.dart';
import 'package:myapp/models/player_model.dart';
import 'package:myapp/models/player_stats.dart';

class PlayerCardScreen extends StatefulWidget {
  final String playerId;
  final String playerName;
  final String userRole;

  const PlayerCardScreen({
    super.key,
    required this.playerId,
    required this.playerName,
    required this.userRole,
  });

  @override
  State<PlayerCardScreen> createState() => _PlayerCardScreenState();
}

class _PlayerCardScreenState extends State<PlayerCardScreen> {
  Player? _player;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPlayerData();
  }

  Future<void> _fetchPlayerData() async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('*, team_members(*)')
          .eq('id', widget.playerId)
          .single();

      final reportsResponse = await Supabase.instance.client
          .from('quarterly_reports')
          .select()
          .eq('player_id', widget.playerId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final stats = reportsResponse != null
          ? PlayerStats.fromMap(reportsResponse)
          : PlayerStats();

      setState(() {
        _player = Player(
          name: response['full_name'] ?? 'No Name',
          role: response['team_members'][0]['role'] ?? 'Unknown',
          isStarter: response['team_members'][0]['is_starter'] ?? false,
          image: response['avatar_url'] ?? 'assets/players/default.png',
          stats: stats,
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playerName),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _player == null
                ? const Center(child: Text('Error al cargar datos del jugador'))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 80),
                        PlayerInfoCard(player: _player!),
                        const SizedBox(height: 20),
                        PlayerStatsCard(stats: _player!.stats),
                        const SizedBox(height: 20),
                        if (_player!.stats.skills.isNotEmpty)
                          Card(
                            elevation: 8,
                            shadowColor: Colors.black54,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                children: [
                                  Text(
                                    'Habilidades del Jugador',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  PlayerRadarChart(skills: _player!.stats.skills),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
