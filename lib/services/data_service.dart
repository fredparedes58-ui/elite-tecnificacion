
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:myapp/models/team_model.dart';

class DataService {
  // Caché para almacenar los equipos una vez cargados
  List<Team>? _teams;

  // Carga los equipos desde el archivo JSON
  Future<List<Team>> loadTeams() async {
    // Si los equipos ya están en caché, los devuelve directamente
    if (_teams != null) {
      return _teams!;
    }

    try {
      // Carga el contenido del archivo JSON como una cadena
      final jsonString = await rootBundle.loadString('assets/data/teams_data.json');
      
      // Decodifica la cadena JSON a un mapa
      final jsonResponse = json.decode(jsonString) as Map<String, dynamic>;
      
      // Extrae la lista de equipos del JSON
      final teamList = jsonResponse['teams'] as List;
      
      // Convierte cada elemento del JSON en un objeto Team
      _teams = teamList.map((json) => Team.fromJson(json)).toList();
      
      return _teams!;
    } catch (e) {
      // En un futuro, podríamos implementar un sistema de logging más robusto.
      return [];
    }
  }

  // Obtiene un equipo específico por su nombre
  Future<Team?> getTeamByName(String name) async {
    final teams = await loadTeams();
    try {
      return teams.firstWhere((team) => team.name == name);
    } catch (e) {
      return null; // Devuelve nulo si no se encuentra el equipo
    }
  }
}
