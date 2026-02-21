import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: const Center(
          child: Text('Profile Screen'),
        ),
      ),
    );
  }
}
