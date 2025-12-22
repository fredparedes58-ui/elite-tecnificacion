import 'package:flutter/material.dart';
import 'package:myapp/widgets/methodology_tab.dart';
import 'package:myapp/widgets/planner_tab.dart';
import 'package:myapp/widgets/tactical_board.dart';

class CoachSuiteScreen extends StatefulWidget {
  const CoachSuiteScreen({super.key});

  @override
  State<CoachSuiteScreen> createState() => _CoachSuiteScreenState();
}

class _CoachSuiteScreenState extends State<CoachSuiteScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("Área Técnica"),
        backgroundColor: Theme.of(context).colorScheme.surface,
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          tabs: const [
            Tab(text: "PIZARRA"),
            Tab(text: "PLANIFICADOR"),
            Tab(text: "METODOLOGÍA"),
            Tab(text: "REPORTES"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          const TacticalTab(),
          const PlannerTab(),
          const MethodologyTab(),
          const _ReportsTab(),
        ],
      ),
    );
  }
}

class _ReportsTab extends StatelessWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      "Informes Técnicos",
      style: Theme.of(context).textTheme.titleLarge,
    ),
  );
}
