import 'package:flutter/material.dart';
import 'package:myapp/data/drill_data.dart';
import 'package:myapp/models/drill_model.dart';
import 'package:myapp/widgets/drill_card.dart';

class MethodologyScreen extends StatelessWidget {
  const MethodologyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Methodology Hub'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'DEFENSA'),
              Tab(text: 'ATAQUE'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {},
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildDrillList(defensiveDrills),
            _buildDrillList(offensiveDrills),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildDrillList(List<Drill> drills) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: drills.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: DrillCard(drill: drills[index], isFeatured: index == 0),
        );
      },
    );
  }
}
