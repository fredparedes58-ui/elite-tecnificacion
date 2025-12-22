import 'package:flutter/material.dart';
import 'package:myapp/screens/gallery_screen.dart';
import 'package:myapp/screens/home_screen.dart';
import 'package:myapp/screens/notifications_screen.dart';
import 'package:myapp/screens/team_chat_screen.dart';
import 'package:myapp/widgets/methodology_tab.dart';

class DashboardScreen extends StatefulWidget {
  final String userRole;
  final String userName;
  const DashboardScreen({
    super.key,
    required this.userRole,
    required this.userName,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const MethodologyTab(),
      const NotificationsScreen(),
      TeamChatScreen(userRole: widget.userRole, userName: widget.userName),
      const GalleryScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Metodología',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notificaciones',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_album),
            label: 'Galería',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
