import 'package:flutter/material.dart';
import 'package:myapp/widgets/app_bar_back.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/widgets/elite_player_card.dart';
import 'package:myapp/widgets/player_stats_card.dart';
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
  String? _category;
  String? _initialNotes;
  bool _isLoading = true;

  bool get _isCoach => ['coach', 'admin'].contains(widget.userRole);

  @override
  void initState() {
    super.initState();
    _fetchPlayerData();
  }

  Future<void> _fetchPlayerData() async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('*, team_members(team_id, teams(category))')
          .eq('id', widget.playerId)
          .single();

      final reportsResponse = await Supabase.instance.client
          .from('quarterly_reports')
          .select()
          .eq('player_id', widget.playerId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      PlayerStats stats = reportsResponse != null
          ? PlayerStats.fromMap(reportsResponse)
          : PlayerStats();

      String? initialNotes;
      try {
        final statsRow = await Supabase.instance.client
            .from('stats')
            .select('pac, sho, pas, dri, def, phy, notes')
            .eq('player_id', widget.playerId)
            .maybeSingle();
        if (statsRow != null) {
          final fifa = <String, double>{
            'PAC': ((statsRow['pac'] as int?) ?? 0).toDouble(),
            'SHO': ((statsRow['sho'] as int?) ?? 0).toDouble(),
            'PAS': ((statsRow['pas'] as int?) ?? 0).toDouble(),
            'DRI': ((statsRow['dri'] as int?) ?? 0).toDouble(),
            'DEF': ((statsRow['def'] as int?) ?? 0).toDouble(),
            'PHY': ((statsRow['phy'] as int?) ?? 0).toDouble(),
          };
          final mergedSkills = Map<String, double>.from(stats.skills)..addAll(fifa);
          stats = stats.copyWith(skills: mergedSkills);
          if (statsRow['notes'] != null) initialNotes = statsRow['notes'] as String?;
        }
      } catch (_) {}

      String? category;
      final tm = response['team_members'];
      if (tm is List && tm.isNotEmpty) {
        final teams = tm[0]['teams'];
        if (teams is Map) category = teams['category'] as String?;
      }
      if (category == null && tm is List && tm.isNotEmpty && tm[0]['team_id'] != null) {
        final teamRes = await Supabase.instance.client
            .from('teams')
            .select('category')
            .eq('id', tm[0]['team_id'])
            .maybeSingle();
        if (teamRes != null) category = teamRes['category'] as String?;
      }

      setState(() {
        _category = category;
        _initialNotes = initialNotes;
        _player = Player(
          name: response['full_name'] ?? 'No Name',
          role: response['position'] ?? response['team_members'][0]['role'] ?? 'Unknown',
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

  Future<void> _saveSkills(Map<String, double> skills) async {
    try {
      final coachId = Supabase.instance.client.auth.currentUser?.id;
      await Supabase.instance.client.from('stats').upsert({
        'player_id': widget.playerId,
        'pac': (skills['PAC'] ?? 0).round(),
        'sho': (skills['SHO'] ?? 0).round(),
        'pas': (skills['PAS'] ?? 0).round(),
        'dri': (skills['DRI'] ?? 0).round(),
        'def': (skills['DEF'] ?? 0).round(),
        'phy': (skills['PHY'] ?? 0).round(),
        'updated_by_coach_id': coachId,
      }, onConflict: 'player_id');
    } catch (_) {}
  }

  Future<void> _saveNotes(String notes) async {
    try {
      final coachId = Supabase.instance.client.auth.currentUser?.id;
      await Supabase.instance.client.from('stats').upsert({
        'player_id': widget.playerId,
        'notes': notes,
        'updated_by_coach_id': coachId,
      }, onConflict: 'player_id');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBarWithBack(
        context,
        title: Text(widget.playerName),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Container(
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
                        ElitePlayerCard(
                          player: _player!,
                          category: _category,
                          playerId: widget.playerId,
                          isCoach: _isCoach,
                          canEditPhoto: true,
                          initialNotes: _initialNotes,
                          onPhotoUpdated: _fetchPlayerData,
                          onSkillsSaved: _isCoach ? _saveSkills : null,
                          onNotesSaved: _isCoach ? _saveNotes : null,
                        ),
                        const SizedBox(height: 20),
                        PlayerStatsCard(stats: _player!.stats),
                      ],
                    ),
                  ),
      ),
      ),
    );
  }
}
