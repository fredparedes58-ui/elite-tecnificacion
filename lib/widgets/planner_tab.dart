import 'package:flutter/material.dart';

class PlannerTab extends StatefulWidget {
  const PlannerTab({super.key});

  @override
  State<PlannerTab> createState() => _PlannerTabState();
}

class _PlannerTabState extends State<PlannerTab> {
  final _events = {
    DateTime.utc(2024, 7, 29): ['Entrenamiento', 'Técnica'],
    DateTime.utc(2024, 7, 30): ['Entrenamiento', 'Táctica'],
    DateTime.utc(2024, 7, 31): ['Partido vs Valencia'],
  };

  DateTime _selectedDay = DateTime.now();

  List<String> _getEventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final events = _getEventsForDay(_selectedDay);

    return Scaffold(
      appBar: AppBar(title: const Text("Planificador Semanal")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: CalendarDatePicker(
                initialDate: _selectedDay,
                firstDate: DateTime(2024),
                lastDate: DateTime(2025),
                onDateChanged: (d) => setState(() => _selectedDay = d),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Eventos del día",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            events.isEmpty
                ? Center(
                    child: Text(
                      "No hay eventos para este día",
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(153),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: events.length,
                    itemBuilder: (c, i) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          child: const Icon(Icons.event_note),
                        ),
                        title: Text(events[i]),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
