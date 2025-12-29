import 'package:flutter/material.dart';
import 'package:myapp/screens/delegate_screen.dart';
import 'package:myapp/screens/drills_screen.dart';
import 'package:myapp/widgets/ai_prediction_card.dart';
import 'package:myapp/widgets/live_standings_card.dart';
import 'package:myapp/widgets/squad_status_card.dart';
import 'package:myapp/widgets/upcoming_match_card.dart';

class CommandCenterScreen extends StatefulWidget {
  const CommandCenterScreen({super.key});

  @override
  State<CommandCenterScreen> createState() => _CommandCenterScreenState();
}

class _CommandCenterScreenState extends State<CommandCenterScreen> {
  int _selectedIndex = 0; // Para manejar el estado de la barra de navegación

  // Lista de widgets para las diferentes pantallas
  static const List<Widget> _widgetOptions = <Widget>[
    CommandCenterContent(),
    DrillsScreen(), // Pantalla de Ejercicios
    Text('Chat'), // Placeholder
    Text('Evolution'), // Placeholder
    Text('Profile'), // Placeholder
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('COMMAND-CENTER', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              // La funcionalidad de notificaciones se implementará en el futuro.
            },
          ),
        ],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.shield_outlined),
            label: 'Center',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center_outlined),
            label: 'Ejercicios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Evolution',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

// Contenido principal del Command Center para mantener el código organizado
class CommandCenterContent extends StatelessWidget {
  const CommandCenterContent({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const UpcomingMatchCard(),
        const SizedBox(height: 24),
        const LiveStandingsCard(),
        const SizedBox(height: 24),
        const SquadStatusCard(),
        const SizedBox(height: 24),
        const AIPredictionCard(),
        const SizedBox(height: 24),
        // Botón temporal para navegar a la pantalla del delegado
        ElevatedButton(
          onPressed: () {
            // NOTA: Se utiliza un partidoId codificado para la demostración.
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DelegateScreen(partidoId: 'a7b1c9d3-9e2b-4f6c-8a1d-5b9c2a3b4e5f')), // UUID de ejemplo
            );
          },
          child: const Text('Ir al Panel del Delegado'),
        ),
      ],
    );
  }
}
