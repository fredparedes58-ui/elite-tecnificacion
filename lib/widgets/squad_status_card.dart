import 'package:flutter/material.dart';

class SquadStatusCard extends StatelessWidget {
  const SquadStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 4,
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('SQUAD STATUS', style: textTheme.titleMedium?.copyWith(color: Colors.white)),
                TextButton(onPressed: () {}, child: const Text('VIEW ALL')),
              ],
            ),
            const SizedBox(height: 16),
            _buildPlayerList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerList() {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: const [
          _PlayerAvatar(name: 'Alex R.', imageUrl: 'https://randomuser.me/api/portraits/men/32.jpg', isInjured: true),
          _PlayerAvatar(name: 'Marcos', imageUrl: 'https://randomuser.me/api/portraits/men/33.jpg'),
          _PlayerAvatar(name: 'J. Stiven', imageUrl: 'https://randomuser.me/api/portraits/men/34.jpg'),
          _PlayerAvatar(name: 'Toni', imageUrl: 'https://randomuser.me/api/portraits/men/35.jpg', isSuspended: true),
          _PlayerAvatar(name: 'David', imageUrl: 'https://randomuser.me/api/portraits/men/36.jpg'),
        ],
      ),
    );
  }
}

class _PlayerAvatar extends StatelessWidget {
  final String name;
  final String imageUrl;
  final bool isInjured;
  final bool isSuspended;

  const _PlayerAvatar({
    required this.name,
    required this.imageUrl,
    this.isInjured = false,
    this.isSuspended = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(imageUrl),
              ),
              if (isInjured)
                Positioned(
                  top: 0,
                  right: 0,
                  child: CircleAvatar(radius: 8, backgroundColor: Colors.yellow, child: Icon(Icons.warning, size: 12, color: Colors.black)),
                ),
              if (isSuspended)
                Positioned(
                  top: 0,
                  right: 0,
                  child: CircleAvatar(radius: 8, backgroundColor: Colors.grey, child: Icon(Icons.block, size: 12, color: Colors.white)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
