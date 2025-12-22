
import 'package:flutter/material.dart';
import 'package:myapp/models/player_model.dart';

class PlayerProfileScreen extends StatelessWidget {
  final Player player;

  const PlayerProfileScreen({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(player.name),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar del jugador
              CircleAvatar(
                radius: 80,
                backgroundImage: AssetImage(player.image),
                backgroundColor: colorScheme.surface, // Color de fondo
              ),
              const SizedBox(height: 24),

              // Nombre del jugador
              Text(
                player.name,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Rol del jugador (si existe)
              if (player.role != null && player.role!.isNotEmpty)
                Chip(
                  label: Text(player.role!),
                  backgroundColor: colorScheme.secondary,
                  labelStyle: textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              
              const Spacer(), // Ocupa el espacio restante para centrar verticalmente
            ],
          ),
        ),
      ),
    );
  }
}
