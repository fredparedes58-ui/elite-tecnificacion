import 'package:flutter/material.dart';
import 'package:myapp/widgets/app_bar_back.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/screens/player_card_screen.dart';

class SquadScreen extends StatefulWidget {
  final String userRole;
  const SquadScreen({super.key, required this.userRole});

  @override
  State<SquadScreen> createState() => _SquadScreenState();
}

class _SquadScreenState extends State<SquadScreen> {
  List<dynamic> _p = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _l();
  }

  Future<void> _l() async {
    try {
      final t = await Supabase.instance.client
          .from('teams')
          .select()
          .limit(1)
          .single();
      final p = await Supabase.instance.client
          .from('team_members')
          .select('user_id, profiles(*)')
          .eq('team_id', t['id']);
      if (mounted) {
        setState(() {
          _p = p as List<dynamic>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBarWithBack(
        context,
        title: Text(
          widget.userRole == 'coach' ? "Gestión Plantilla" : "Mi Equipo",
        ),
      ),
      body: SafeArea(
        child: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.8,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: _p.length,
              itemBuilder: (c, i) {
                final prof = _p[i]['profiles'];
                bool isTitular = i < 11;
                return InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlayerCardScreen(
                        playerId: _p[i]['user_id'],
                        playerName: prof['full_name'] ?? 'J',
                        userRole: widget.userRole,
                      ),
                    ),
                  ),
                  child: Card(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundImage: prof['avatar_url'] != null
                                  ? NetworkImage(prof['avatar_url'])
                                  : null,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surface,
                            ),
                            Positioned(
                              right: -5,
                              bottom: -5,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isTitular
                                      ? Theme.of(context).colorScheme.secondary
                                      : Colors.grey,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  isTitular ? "TIT" : "SUP",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          prof['full_name'] ?? '',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      ),
    );
  }
}
