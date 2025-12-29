import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final stream = Supabase.instance.client
        .from('matches')
        .stream(primaryKey: ['id'])
        .order('match_date');
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }
        if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No hay partidos para esta selección.'));
        }
        
        final matches = snapshot.data!;
        
        return ListView.builder(
          itemCount: matches.length,
          itemBuilder: (context, index) {
             final match = matches[index];
             final status = match['status'];
             String displayStatus;
             Color statusColor;

             switch(status) {
                case 'FINISHED':
                    displayStatus = 'FINAL';
                    statusColor = Colors.red;
                    break;
                case 'LIVE':
                    displayStatus = 'VIVO';
                    statusColor = Colors.green;
                    break;
                case 'PENDING':
                    displayStatus = 'PEND';
                    statusColor = Colors.orange;
                    break;
                default:
                    displayStatus = status ?? 'N/A';
                    statusColor = Colors.grey;
             }


            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              ),
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  Text(
                    displayStatus,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                  child: Text(
                    "${matches[index]['team_home']} vs ${matches[index]['team_away']}",
                          style: TextStyle(
                             color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                  ),
                  Text(
                  "${matches[index]['goals_home']}-${matches[index]['goals_away']}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
          );
          },
        );
      },
    );
  }
}
