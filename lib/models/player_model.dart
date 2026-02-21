import 'package:myapp/models/player_stats.dart';

enum MatchStatus {
  starter, // Titular
  sub, // Suplente
  unselected, // Desconvocado
}

class Player {
  final String? id; // ID de Supabase (user_id)
  final String name;
  final String? role;
  final bool isStarter;
  final String image;
  final PlayerStats stats;
  final MatchStatus matchStatus;
  final String? statusNote;
  final String? nickname; // Apodo del jugador
  final int? number; // Número de camiseta

  Player({
    this.id,
    required this.name,
    this.role,
    required this.isStarter,
    required this.image,
    PlayerStats? stats,
    this.matchStatus = MatchStatus.sub,
    this.statusNote,
    this.nickname,
    this.number,
  }) : stats = stats ?? PlayerStats();

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String?,
      name: json['name'] as String,
      role: json['role'] as String?,
      isStarter: json['isStarter'] as bool,
      image: json['image'] as String,
      stats: json['stats'] != null
          ? PlayerStats.fromMap(json['stats'])
          : PlayerStats(),
      matchStatus: parseMatchStatus(json['match_status']),
      statusNote: json['status_note'] as String?,
      nickname: json['nickname'] as String?,
      number: json['number'] as int?,
    );
  }

  // Parse match_status desde string
  static MatchStatus parseMatchStatus(dynamic value) {
    if (value == null) return MatchStatus.sub;
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'starter':
          return MatchStatus.starter;
        case 'sub':
          return MatchStatus.sub;
        case 'unselected':
          return MatchStatus.unselected;
        default:
          return MatchStatus.sub;
      }
    }
    return MatchStatus.sub;
  }

  // Convertir a String para guardar en Supabase
  String get matchStatusString {
    switch (matchStatus) {
      case MatchStatus.starter:
        return 'starter';
      case MatchStatus.sub:
        return 'sub';
      case MatchStatus.unselected:
        return 'unselected';
    }
  }

  // Factory desde Supabase profile
  factory Player.fromSupabaseProfile(
    Map<String, dynamic> profile, {
    String? matchStatus,
    String? statusNote,
  }) {
    return Player(
      id: profile['id'] as String?,
      name: profile['full_name'] ?? 'Jugador',
      role: profile['position'] as String?,
      isStarter: matchStatus == 'starter',
      image: profile['avatar_url'] ?? 'assets/images/default_avatar.png',
      matchStatus: parseMatchStatus(matchStatus),
      statusNote: statusNote,
      nickname: profile['nickname'] as String?,
      number: profile['jersey_number'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'isStarter': isStarter,
      'image': image,
      'stats': stats.toMap(),
      'match_status': matchStatusString,
      'status_note': statusNote,
      'nickname': nickname,
      'number': number,
    };
  }

  Player copyWith({
    String? id,
    String? name,
    String? role,
    bool? isStarter,
    String? image,
    PlayerStats? stats,
    MatchStatus? matchStatus,
    String? statusNote,
    String? nickname,
    int? number,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      isStarter: isStarter ?? this.isStarter,
      image: image ?? this.image,
      stats: stats ?? this.stats,
      matchStatus: matchStatus ?? this.matchStatus,
      statusNote: statusNote ?? this.statusNote,
      nickname: nickname ?? this.nickname,
      number: number ?? this.number,
    );
  }
}
