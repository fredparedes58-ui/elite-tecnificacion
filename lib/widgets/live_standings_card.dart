
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/data/league_data.dart';
// unused_import 'package:myapp/models/league_model.dart' se eliminará

class LiveStandingsCard extends StatelessWidget {
  const LiveStandingsCard({super.key});

  // Nombre del equipo a destacar
  static const String _highlightedTeam = "C.F. Fundació VCF 'A'";

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final topTeams = leagueTable.take(5).toList(); // Mostramos el top 5

    return Card(
      elevation: 8,
      shadowColor: Colors.black.withAlpha(102), // Corrección: withOpacity -> withAlpha
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [Colors.grey.shade900.withAlpha(230), Colors.black.withAlpha(204)]
                : [Colors.grey.shade100, Colors.white],
          ),
          image: const DecorationImage(
            image: AssetImage('assets/images/noise_texture.png'),
            fit: BoxFit.cover,
            opacity: 0.03,
          ),
        ),
        child: Column(
          children: [
            // -- ENCABEZADO --
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CLASIFICACIÓN',
                    style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: Text('VER TODO', style: GoogleFonts.robotoCondensed(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.onSurface,
                      side: BorderSide(color: colorScheme.onSurface.withAlpha(77)), // Corrección: withOpacity -> withAlpha
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // -- TABLA DE POSICIONES --
            _buildTableRow('#', 'Club', 'Pts', isHeader: true, context: context),
            const Divider(height: 1, thickness: 1, indent: 20, endIndent: 20),
            ...topTeams.map((team) {
              final isHighlighted = team.club == _highlightedTeam;
              return _buildTableRow(
                team.position.toString(),
                team.club,
                team.points.toString(),
                isHighlighted: isHighlighted,
                context: context,
              );
            }),
          ],
        ),
      ),
    );
  }

  // Widget reutilizable para construir cada fila de la tabla
  Widget _buildTableRow(String pos, String club, String pts, {
    bool isHeader = false,
    bool isHighlighted = false,
    required BuildContext context,
  }) {
    final textStyle = GoogleFonts.robotoCondensed(
      fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
      fontSize: isHeader ? 12 : 14,
      color: Theme.of(context).colorScheme.onSurface.withAlpha(isHeader ? 153 : 255), // Corrección: withOpacity -> withAlpha
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: isHighlighted ? Theme.of(context).colorScheme.primary.withAlpha(26) : Colors.transparent, // Corrección: withOpacity -> withAlpha
        border: isHighlighted
            ? Border(left: BorderSide(color: Theme.of(context).colorScheme.primary, width: 3))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text(pos, style: textStyle)),
          Expanded(flex: 3, child: Text(club, style: textStyle, overflow: TextOverflow.ellipsis)),
          SizedBox(width: 40, child: Text(pts, textAlign: TextAlign.right, style: textStyle.copyWith(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
