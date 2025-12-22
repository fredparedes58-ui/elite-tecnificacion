import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: ListView.builder(
        itemCount: 5,
        itemBuilder: (c, i) => ListTile(
          leading: CircleAvatar(
            backgroundColor: i.isEven
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.secondary,
            child: Icon(
              i.isEven ? Icons.info : Icons.warning,
              color: Colors.white,
            ),
          ),
          title: Text(
            "Notificación de prueba ${i + 1}",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          subtitle: Text(
            "Hace ${i * 5} minutos",
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: TextButton(onPressed: () {}, child: const Text("Ver")),
        ),
      ),
    );
  }
}
