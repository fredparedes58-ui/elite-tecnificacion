import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = Supabase.instance.client
        .from('matches')
        .stream(primaryKey: ['id'])
        .order('match_date');
    return StreamBuilder(
      stream: s,
      builder: (c, s) {
        if (!s.hasData) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }
        final m = s.data as List<dynamic>;
        return ListView.builder(
          itemCount: m.length,
          itemBuilder: (c, i) => Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Text(
                  m[i]['status'] == 'FINISHED' ? "FINAL" : "PEND",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    "${m[i]['team_home']} vs ${m[i]['team_away']}",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                Text(
                  "${m[i]['goals_home']}-${m[i]['goals_away']}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
