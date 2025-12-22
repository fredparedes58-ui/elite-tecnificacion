
import 'package:flutter/material.dart';
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

  // Lista de widgets para las diferentes pantallas (por ahora solo el Command Center)
  static const List<Widget> _widgetOptions = <Widget>[
    CommandCenterContent(),
    Text('Tactics'), // Placeholder para la pantalla de Tácticas
    Text('Chat'), // Placeholder para la pantalla de Chat
    Text('Evolution'), // Placeholder para la pantalla de Evolución
    Text('Profile'), // Placeholder para la pantalla de Perfil
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
            icon: Icon(Icons.architecture_outlined),
            label: 'Tactics',
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
      children: const [
        UpcomingMatchCard(),
        SizedBox(height: 24),
        LiveStandingsCard(),
        SizedBox(height: 24),
        SquadStatusCard(),
        SizedBox(height: 24),
        AIPredictionCard(),
      ],
    );
  }
}
