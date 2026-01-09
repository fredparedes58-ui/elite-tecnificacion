// ============================================================
// PANTALLA: AGREGAR MIEMBRO AL EQUIPO
// ============================================================
// Permite a entrenadores/directivos agregar usuarios por email o nombre
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/services/supabase_service.dart';

class AddTeamMemberScreen extends StatefulWidget {
  const AddTeamMemberScreen({super.key});

  @override
  State<AddTeamMemberScreen> createState() => _AddTeamMemberScreenState();
}

class _AddTeamMemberScreenState extends State<AddTeamMemberScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _teams = [];
  bool _isSearching = false;
  bool _isLoadingTeams = true;
  bool _isAdding = false;
  String? _selectedTeamId;
  String _selectedRole = 'player';

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTeams() async {
    setState(() => _isLoadingTeams = true);
    try {
      final teams = await _supabaseService.getAllTeams();
      if (mounted) {
        setState(() {
          _teams = teams;
          _isLoadingTeams = false;
          // Seleccionar el primer equipo por defecto si existe
          if (_teams.isNotEmpty && _selectedTeamId == null) {
            _selectedTeamId = _teams.first['id'] as String;
          }
        });
      }
    } catch (e) {
      debugPrint('Error cargando equipos: $e');
      if (mounted) {
        setState(() => _isLoadingTeams = false);
      }
    }
  }

  Future<void> _searchUsers() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    try {
      final results = await _supabaseService.searchUsers(query: query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('Error buscando usuarios: $e');
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _addUserToTeam(Map<String, dynamic> user) async {
    if (_selectedTeamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un equipo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isAdding = true);
    try {
      await _supabaseService.addUserToTeam(
        userId: user['id'] as String,
        teamId: _selectedTeamId!,
        role: _selectedRole,
        userFullName: user['full_name'] as String?,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user['full_name'] ?? 'Usuario'} agregado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'AGREGAR MIEMBRO',
          style: GoogleFonts.oswald(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 1.5,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Selector de equipo
          Card(
            color: colorScheme.primary.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.group,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Seleccionar Equipo',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingTeams)
                    const Center(child: CircularProgressIndicator())
                  else if (_teams.isEmpty)
                    Text(
                      'No hay equipos disponibles',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.white54,
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: _selectedTeamId,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: colorScheme.surface,
                      ),
                      items: _teams.map((team) {
                        return DropdownMenuItem<String>(
                          value: team['id'] as String,
                          child: Text(
                            '${team['name']} (${team['category']})',
                            style: GoogleFonts.roboto(),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedTeamId = value);
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Selector de rol
          Card(
            color: colorScheme.secondary.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: colorScheme.secondary.withOpacity(0.3),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Rol del Miembro',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: colorScheme.surface,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'player',
                        child: Text('Jugador'),
                      ),
                      DropdownMenuItem(
                        value: 'coach',
                        child: Text('Entrenador'),
                      ),
                      DropdownMenuItem(
                        value: 'parent',
                        child: Text('Padre/Madre'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedRole = value ?? 'player');
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Buscador de usuarios
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Buscar por email o nombre',
              hintText: 'Ej: juan@email.com o Juan Pérez',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchResults = []);
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (_) => _searchUsers(),
            style: GoogleFonts.roboto(),
          ),
          const SizedBox(height: 16),

          // Resultados de búsqueda
          if (_isSearching)
            const Center(child: CircularProgressIndicator())
          else if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 48,
                      color: Colors.white54,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No se encontraron usuarios',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_searchResults.isNotEmpty)
            ..._searchResults.map((user) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primary.withOpacity(0.2),
                    child: Icon(
                      Icons.person,
                      color: colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    user['full_name'] ?? 'Sin nombre',
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    user['email'] ?? 'Usuario registrado',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  trailing: _isAdding
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.add_circle),
                          color: colorScheme.primary,
                          onPressed: () => _addUserToTeam(user),
                        ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
