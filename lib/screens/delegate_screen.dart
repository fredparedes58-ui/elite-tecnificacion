
import 'package:flutter/material.dart';
import 'package:myapp/widgets/app_bar_back.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/live_match_header.dart'; // Reutilizamos el header para feedback visual

class DelegateScreen extends StatefulWidget {
  final String partidoId;

  const DelegateScreen({super.key, required this.partidoId});

  @override
  State<DelegateScreen> createState() => _DelegateScreenState();
}

class _DelegateScreenState extends State<DelegateScreen> {
  final supabase = Supabase.instance.client;
  final _minuteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCurrentMinute();
  }

  Future<void> _fetchCurrentMinute() async {
    try {
      final partidoData = await supabase
          .from('partidos')
          .select('minuto_actual')
          .eq('id', widget.partidoId)
          .single();
      _minuteController.text = (partidoData['minuto_actual'] ?? 0).toString();
    } catch (e) {
      // Manejar error si no se puede obtener el minuto
    }
  }

  Future<void> _updateScore(String team, {required String localName, required String visitorName}) async {
    if (_minuteController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, introduce el minuto del gol.'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      final partidoData = await supabase
          .from('partidos')
          .select('goles_local, goles_visitante')
          .eq('id', widget.partidoId)
          .single();

      int newGolesLocal = partidoData['goles_local'];
      int newGolesVisitante = partidoData['goles_visitante'];

      if (team == 'local') {
        newGolesLocal++;
      } else {
        newGolesVisitante++;
      }

      await supabase.from('partidos').update({
        'goles_local': newGolesLocal,
        'goles_visitante': newGolesVisitante,
      }).eq('id', widget.partidoId);

      await supabase.from('eventos_partido').insert({
        'partido_id': widget.partidoId,
        'minuto': int.tryParse(_minuteController.text) ?? 0,
        'tipo': 'GOL',
        'jugador_nombre': 'Jugador Anónimo', // Placeholder
        'equipo_nombre': team == 'local' ? localName : visitorName
      });
    } catch(e) {
       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar el gol: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _updateMatchStatus(String newStatus) async {
    try {
      await supabase.from('partidos').update({
        'estado': newStatus,
      }).eq('id', widget.partidoId);
    } catch(e) {
       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar estado: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _updateMinute() async {
    final minute = int.tryParse(_minuteController.text);
    if (minute != null) {
      try {
        await supabase.from('partidos').update({
          'minuto_actual': minute,
        }).eq('id', widget.partidoId);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Minuto actualizado.'), backgroundColor: Colors.green),
        );

      } catch (e) {
         if (!mounted) return;
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar minuto: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBarWithBack(
        context,
        title: const Text('Panel del Delegado'),
        backgroundColor: Colors.black,
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
        future: supabase.from('partidos').select('local_nombre, visitante_nombre').eq('id', widget.partidoId).single(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final teamNames = snapshot.data!;
          final localName = teamNames['local_nombre'] ?? 'Local';
          final visitorName = teamNames['visitante_nombre'] ?? 'Visitante';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("Vista Previa en Tiempo Real", style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                LiveMatchHeader(partidoId: widget.partidoId),
                const SizedBox(height: 32),

                _buildSectionTitle(context, "Control del Partido"),
                TextField(
                  controller: _minuteController,
                  decoration: InputDecoration(
                    labelText: 'Minuto Actual',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.check_circle_outline),
                      onPressed: _updateMinute,
                      tooltip: 'Actualizar Minuto',
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8.0,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton.icon(icon: const Icon(Icons.play_arrow), onPressed: () => _updateMatchStatus('EN_JUEGO'), label: const Text("Iniciar")),
                    FilledButton.icon(icon: const Icon(Icons.pause), onPressed: () => _updateMatchStatus('DESCANSO'), label: const Text("Descanso")),
                    FilledButton.icon(icon: const Icon(Icons.stop), onPressed: () => _updateMatchStatus('FINALIZADO'), label: const Text("Finalizar")),
                  ],
                ),
                const SizedBox(height: 32),

                _buildSectionTitle(context, "Control del Marcador"),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: Text('Gol $localName'),
                      onPressed: () => _updateScore('local', localName: localName, visitorName: visitorName),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        textStyle: const TextStyle(fontSize: 16)
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: Text('Gol $visitorName'),
                      onPressed: () => _updateScore('visitante', localName: localName, visitorName: visitorName),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        textStyle: const TextStyle(fontSize: 16)
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                 _buildSectionTitle(context, "Añadir Evento"),
                 Card(
                   elevation: 2,
                   child: Padding(
                     padding: const EdgeInsets.all(16.0),
                     child: Column(
                       children: [
                         // Aquí iría un formulario más complejo para tarjetas, cambios, etc.
                         Text("Más opciones próximamente", style: Theme.of(context).textTheme.bodyMedium),
                         const SizedBox(height: 8),
                         const Icon(Icons.construction, color: Colors.grey, size: 40),
                       ],
                     ),
                   ),
                 )
              ],
            ),
          );
        },
      ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }
}
