// ============================================================
// PANTALLA: SELECCIONAR DESTINATARIO DEL CHAT
// ============================================================
// Permite seleccionar con quién chatear (grupo o persona)
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SelectChatRecipientScreen extends StatefulWidget {
  final String teamId;
  final String currentUserId;

  const SelectChatRecipientScreen({
    super.key,
    required this.teamId,
    required this.currentUserId,
  });

  @override
  State<SelectChatRecipientScreen> createState() => _SelectChatRecipientScreenState();
}

class _SelectChatRecipientScreenState extends State<SelectChatRecipientScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allMembers = [];
  List<Map<String, dynamic>> _filteredMembers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTeamMembers();
    _searchController.addListener(_filterMembers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTeamMembers() async {
    setState(() => _loading = true);
    try {
      final response = await Supabase.instance.client
          .from('team_members')
          .select('''
            id,
            user_id,
            role,
            is_representative,
            represented_player_id,
            profiles!inner(id, full_name, avatar_url)
          ''')
          .eq('team_id', widget.teamId);

      final members = List<Map<String, dynamic>>.from(response);
      
      // Filtrar el usuario actual
      _allMembers = members
          .where((m) => m['user_id'] != widget.currentUserId)
          .toList();
      
      _filteredMembers = _allMembers;
    } catch (e) {
      debugPrint('Error cargando miembros: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _filterMembers() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      _filteredMembers = _allMembers;
    } else {
      _filteredMembers = _allMembers.where((member) {
        final profile = member['profiles'] as Map<String, dynamic>?;
        final name = profile?['full_name']?.toString().toLowerCase() ?? '';
        final role = member['role']?.toString().toLowerCase() ?? '';
        return name.contains(query) || role.contains(query);
      }).toList();
    }
    setState(() {});
  }

  String _getMemberDisplayName(Map<String, dynamic> member) {
    final profile = member['profiles'] as Map<String, dynamic>?;
    final name = profile?['full_name'] ?? 'Usuario';
    final isRepresentative = member['is_representative'] == true;
    
    if (isRepresentative) {
      return '$name (Representante)';
    }
    
    final role = member['role'];
    if (role == 'player') {
      return '$name (Jugador)';
    } else if (role == 'coach') {
      return '$name (Entrenador)';
    } else if (role == 'admin') {
      return '$name (Admin)';
    }
    
    return name;
  }

  String _getMemberSubtitle(Map<String, dynamic> member) {
    final role = member['role'];
    if (member['is_representative'] == true) {
      return 'Representante de jugador';
    }
    switch (role) {
      case 'player':
        return 'Jugador';
      case 'coach':
        return 'Entrenador';
      case 'admin':
        return 'Administrador';
      default:
        return 'Miembro del equipo';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Seleccionar Destinatario',
          style: GoogleFonts.oswald(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Buscador
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                
                // Opción: Grupo (todos)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: InkWell(
                    onTap: () => Navigator.pop(context, 'group'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.group,
                            color: theme.colorScheme.primary,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Grupo - Todos',
                                  style: GoogleFonts.oswald(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Enviar mensaje a todo el equipo',
                                  style: GoogleFonts.roboto(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.white54,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const Divider(),
                
                // Lista de miembros
                Expanded(
                  child: _filteredMembers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_off,
                                size: 64,
                                color: Colors.white24,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No se encontraron miembros',
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredMembers.length,
                          itemBuilder: (context, index) {
                            final member = _filteredMembers[index];
                            final profile = member['profiles'] as Map<String, dynamic>?;
                            final avatarUrl = profile?['avatar_url'] as String?;
                            final userId = member['user_id'] as String;
                            
                            return InkWell(
                              onTap: () => Navigator.pop(context, userId),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    // Avatar
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundImage: avatarUrl != null
                                          ? NetworkImage(avatarUrl)
                                          : null,
                                      child: avatarUrl == null
                                          ? Text(
                                              _getMemberDisplayName(member)
                                                  .substring(0, 1)
                                                  .toUpperCase(),
                                              style: GoogleFonts.roboto(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    // Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _getMemberDisplayName(member),
                                            style: GoogleFonts.roboto(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            _getMemberSubtitle(member),
                                            style: GoogleFonts.roboto(
                                              fontSize: 12,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Colors.white54,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
