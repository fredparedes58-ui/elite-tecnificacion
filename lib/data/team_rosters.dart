// ============================================================
// DATOS DE PLANTILLAS DE EQUIPOS
// ============================================================
// Plantillas extraídas de resultadosffcv.isquad.es
// ============================================================

class TeamRoster {
  final String teamName;
  final String? logoPath; // Ruta del logo del equipo
  final List<PlayerInfo> starters;
  final List<PlayerInfo> substitutes;
  final List<CoachInfo> coaches;

  const TeamRoster({
    required this.teamName,
    this.logoPath,
    required this.starters,
    required this.substitutes,
    required this.coaches,
  });
}

/// Helper para obtener la ruta del logo de un equipo
class TeamLogoHelper {
  /// Mapa de nombres de equipos a rutas de logos
  static const Map<String, String> teamLogos = {
    'Picassent C.F. \'A\'': 'assets/images/teams/picassent.png',
    'F.B.U.E. Atlètic Amistat \'A\'': 'assets/images/teams/atletic_amistat.png',
    'Col. Salgui E.D.E. \'A\'': 'assets/images/teams/salgui.png',
    'C.D. Don Bosco \'A\'': 'assets/images/teams/don_bosco.png',
    'F.B.C.D. Catarroja \'B\'': 'assets/images/teams/catarroja.png',
    'C.F. Fundació VCF \'A\'': 'assets/images/teams/fundacio_vcf.png',
    'C.F. Sporting Xirivella \'C\'': 'assets/images/teams/sporting_xirivella.png',
    'Torrent C.F. \'C\'': 'assets/images/teams/torrent.png',
    'Unió Benetússer-Favara C.F. \'A\'': 'assets/images/teams/benetusser_favara.png',
    'U.D. Alzira \'A\'': 'assets/images/teams/alzira.png',
    'C.F.B. Ciutat de València \'A\'': 'assets/images/teams/ciutat_valencia.png',
    'C.D. San Marcelino \'A\'': 'assets/images/teams/san_marcelino.png',
  };

  /// Obtiene la ruta del logo de un equipo
  static String? getLogoPath(String teamName) {
    return teamLogos[teamName];
  }

  /// Obtiene el logo por defecto si no existe
  static String getDefaultLogo() {
    return 'assets/images/default_team_logo.png';
  }
}

class PlayerInfo {
  final String name;
  final int? number;
  final String? position; // Pt, C, Ps

  const PlayerInfo({
    required this.name,
    this.number,
    this.position,
  });
}

class CoachInfo {
  final String name;
  final String role;

  const CoachInfo({
    required this.name,
    required this.role,
  });
}

// Lista completa de plantillas
final List<TeamRoster> allTeamRosters = [
  // Picassent C.F. 'A'
  TeamRoster(
    teamName: 'Picassent C.F. \'A\'',
    logoPath: TeamLogoHelper.teamLogos['Picassent C.F. \'A\''],
    starters: [
      PlayerInfo(name: 'MATEO RODRIGUEZ CAMPOS', number: 13, position: 'Pt'),
      PlayerInfo(name: 'ABEL ARMERO SERRANO', number: 7),
      PlayerInfo(name: 'OLIVER TARAZONA RETAMAL', number: 8, position: 'C'),
      PlayerInfo(name: 'ISLAM OUSDAF EL HASSANI', number: 9),
      PlayerInfo(name: 'LUCAS PEREZ CORRALES', number: 10),
      PlayerInfo(name: 'DIEGO ANTONIO GOMEZ MARTINEZ', number: 17),
      PlayerInfo(name: 'DAVID MARTINEZ LLACER', number: 19),
      PlayerInfo(name: 'DEIVID NAVARRO BELENGUER', number: 71),
    ],
    substitutes: [
      PlayerInfo(name: 'YERAY CARRETERO DUART', number: 1, position: 'Ps'),
      PlayerInfo(name: 'Victor', number: 4),
      PlayerInfo(name: 'DARIO SANCHEZ CIJES', number: 5),
      PlayerInfo(name: 'LUCA MADRIGAL RAMOS', number: 11),
      PlayerInfo(name: 'ANDREU CACERES ALBERT', number: 25),
    ],
    coaches: [
      CoachInfo(name: 'RAFAEL BAREA MORENO', role: 'Entrenador'),
    ],
  ),

  // F.B.U.E. Atlètic Amistat 'A'
  TeamRoster(
    teamName: 'F.B.U.E. Atlètic Amistat \'A\'',
    logoPath: TeamLogoHelper.teamLogos['F.B.U.E. Atlètic Amistat \'A\''],
    starters: [
      PlayerInfo(name: 'ROBERTO MARTÍNEZ LÓPEZ', number: 99, position: 'Pt'),
      PlayerInfo(name: 'MARC ALCALA FERRER', number: 4),
      PlayerInfo(name: 'FRAN NOGUERA LÓPEZ-ROCA', number: 8),
      PlayerInfo(name: 'BOSCO ESTORS ANDREO', number: 9),
      PlayerInfo(name: 'Perez Cuesta', number: 10, position: 'C'),
      PlayerInfo(name: 'MARC ABAD GURREA', number: 14),
      PlayerInfo(name: 'CRISTIAN MORENO CAJA', number: 19),
      PlayerInfo(name: 'MARC DE SOJO CERVERA', number: 20),
    ],
    substitutes: [
      PlayerInfo(name: 'ROMERO NACHO PLA', number: 5),
      PlayerInfo(name: 'VICTOR CASTRO MOLINA', number: 7),
      PlayerInfo(name: 'BELTRAN LASTRA MARCOS', number: 11),
    ],
    coaches: [
      CoachInfo(name: 'ROBERTO NAVAS MORO', role: 'Entrenador'),
    ],
  ),

  // Col. Salgui E.D.E. 'A'
  TeamRoster(
    teamName: 'Col. Salgui E.D.E. \'A\'',
    logoPath: TeamLogoHelper.teamLogos['Col. Salgui E.D.E. \'A\''],
    starters: [
      PlayerInfo(name: 'CRISTIAN MIRAPEIX SANDELLS', number: 13, position: 'Pt'),
      PlayerInfo(name: 'ALEJANDRO MELLADO DUTRA', number: 2, position: 'C'),
      PlayerInfo(name: 'ENRIQUE PEREZ MORA', number: 4),
      PlayerInfo(name: 'ARNAU RUIPEREZ MONCHOLI', number: 7),
      PlayerInfo(name: 'CARLES MOLINA RODRIGUEZ', number: 8),
      PlayerInfo(name: 'MATEO PARRA PLANELLS', number: 9),
      PlayerInfo(name: 'MARIO LEAL TORRECILLAS', number: 11),
      PlayerInfo(name: 'ADRIAN BARTOLOME BAIXAULI', number: 16),
    ],
    substitutes: [
      PlayerInfo(name: 'MARTIN HUERTA VAILLO', number: 10),
      PlayerInfo(name: 'MARTIN MENJIBAR NAVARRO', number: 14),
      PlayerInfo(name: 'IGNACIO MOYA MERIDA', number: 17),
      PlayerInfo(name: 'OLIVER RODRIGUEZ CORTES', number: 20),
    ],
    coaches: [
      CoachInfo(name: 'LUCAS HOFMANN MUÑOZ', role: 'Entrenador'),
    ],
  ),

  // C.D. Don Bosco 'A'
  TeamRoster(
    teamName: 'C.D. Don Bosco \'A\'',
    logoPath: TeamLogoHelper.teamLogos['C.D. Don Bosco \'A\''],
    starters: [
      PlayerInfo(name: 'MARCOS FLORES SALES', number: 25, position: 'Pt'),
      PlayerInfo(name: 'PABLO ESCRIBANO RIOS', number: 4),
      PlayerInfo(name: 'MATEO VELAZQUEZ VELASCO', number: 5),
      PlayerInfo(name: 'JOAN COMES VILLALON', number: 6, position: 'C'),
      PlayerInfo(name: 'JUAN MARTINEZ FERNANDEZ', number: 7),
      PlayerInfo(name: 'SIMON MAGRO FLOR', number: 8),
      PlayerInfo(name: 'JOSE ANTONIO CARRASCO ALCAIDE', number: 9),
      PlayerInfo(name: 'CARLOS LOPEZ RAMOS', number: 16),
    ],
    substitutes: [
      PlayerInfo(name: 'HAOXUAN CHEN', number: 19),
    ],
    coaches: [
      CoachInfo(name: 'GUILLERMO AUSIAS ARLANDIS FERRANDO', role: 'Entrenador'),
    ],
  ),

  // F.B.C.D. Catarroja 'B'
  TeamRoster(
    teamName: 'F.B.C.D. Catarroja \'B\'',
    logoPath: TeamLogoHelper.teamLogos['F.B.C.D. Catarroja \'B\''],
    starters: [
      PlayerInfo(name: 'MARIO JIMENEZ ESPINOSA', number: 25, position: 'Pt'),
      PlayerInfo(name: 'MARC GRAU PASTOR', number: 6, position: 'C'),
      PlayerInfo(name: 'ALBERTO ARRIBAS GALLEGO', number: 7),
      PlayerInfo(name: 'OLIVER MORALES SOBRINO', number: 8),
      PlayerInfo(name: 'MARTIN DURAN GARCIA', number: 11),
      PlayerInfo(name: 'LEO PIQUER GOMEZ', number: 19),
      PlayerInfo(name: 'RICARDO DAVID CURBELO GUERRA', number: 22),
      PlayerInfo(name: 'MATEO CARBONELL GARNICA', number: 23),
    ],
    substitutes: [
      PlayerInfo(name: 'PABLO DURAN GARCIA', number: 1, position: 'Ps'),
      PlayerInfo(name: 'LUCAS MELLADO PEREZ', number: 9),
    ],
    coaches: [
      CoachInfo(name: 'ANDONI SORIA MARTINS', role: 'Entrenador'),
      CoachInfo(name: 'VICENTE RAMON PERIS TALAVERANO', role: 'Segundo Entrenador'),
    ],
  ),

  // C.F. Fundació VCF 'A'
  TeamRoster(
    teamName: 'C.F. Fundació VCF \'A\'',
    logoPath: TeamLogoHelper.teamLogos['C.F. Fundació VCF \'A\''],
    starters: [
      PlayerInfo(name: 'JEYCO ANDRE MOLINA PONCE', number: 1, position: 'Pt'),
      PlayerInfo(name: 'MARKO RODRIGUEZ SORIA', number: 4),
      PlayerInfo(name: 'MARC GARCES MARTINEZ', number: 6),
      PlayerInfo(name: 'ADAMA CONTEH NIMAGA', number: 7),
      PlayerInfo(name: 'DÍDAC SÁNCHEZ CARIÑENA', number: 8, position: 'C'),
      PlayerInfo(name: 'SERGIO SANMARTIN NADAL', number: 9),
      PlayerInfo(name: 'MARCO TERZANO', number: 11),
      PlayerInfo(name: 'JUAN NDIVO NGOMO', number: 12),
    ],
    substitutes: [
      PlayerInfo(name: 'PAU COLLADO REDONDO', number: 2),
      PlayerInfo(name: 'NICOLAE ALEJANDRO CIOBANU', number: 5),
      PlayerInfo(name: 'MARC TORRES OLVEIRA', number: 10),
    ],
    coaches: [
      CoachInfo(name: 'ALEJANDRO DRAGO MELENDEZ', role: 'Entrenador'),
      CoachInfo(name: 'LIAM QUILIS MARTINEZ', role: 'Segundo Entrenador'),
    ],
  ),

  // C.F. Sporting Xirivella 'C'
  TeamRoster(
    teamName: 'C.F. Sporting Xirivella \'C\'',
    logoPath: TeamLogoHelper.teamLogos['C.F. Sporting Xirivella \'C\''],
    starters: [
      PlayerInfo(name: 'MARC BRODIN LERMA', number: 1, position: 'Pt'),
      PlayerInfo(name: 'ARITZ ZARAGOZA TALAVERA', number: 16),
      PlayerInfo(name: 'LUCAS PAUL MARTINEZ MEDINA', number: 17, position: 'C'),
      PlayerInfo(name: 'VADIM PIATNITCKIT', number: 19),
      PlayerInfo(name: 'ERICK VALVERDE SERRANO', number: 21),
      PlayerInfo(name: 'THIAGO RODRIGUEZ GOMEZ', number: 23),
      PlayerInfo(name: 'LORENZO VEGA', number: 30),
      PlayerInfo(name: 'MARC ARJONA LAENCINA', number: 57),
    ],
    substitutes: [
      PlayerInfo(name: 'MATIAS MARTIN', number: 11),
      PlayerInfo(name: 'JESUS ALASCIO LLACER', number: 13),
      PlayerInfo(name: 'RODION SHEFER', number: 28),
      PlayerInfo(name: 'DANILA STROEV', number: 32),
    ],
    coaches: [
      CoachInfo(name: 'ALEJANDRO ROBERTO MASIP', role: 'Entrenador'),
    ],
  ),

  // Torrent C.F. 'C'
  TeamRoster(
    teamName: 'Torrent C.F. \'C\'',
    logoPath: TeamLogoHelper.teamLogos['Torrent C.F. \'C\''],
    starters: [
      PlayerInfo(name: 'JOEL NAVARRO PASTOR', number: 1, position: 'Pt'),
      PlayerInfo(name: 'PABLO MERINO MORA', number: 2),
      PlayerInfo(name: 'MARTIN PALOP GUERRERO', number: 6),
      PlayerInfo(name: 'FRANCESC BESO BERBEL', number: 9),
      PlayerInfo(name: 'GUILLERMO MENCHERO MONTESINOS', number: 10),
      PlayerInfo(name: 'ASIER GARCIA VIDAL', number: 11),
      PlayerInfo(name: 'ALBERTO LAGULLON DOMINGO', number: 12, position: 'C'),
      PlayerInfo(name: 'OLIVER POVEDA GARCIA', number: 16),
    ],
    substitutes: [
      PlayerInfo(name: 'GABRIEL RUBIO SORLA', number: 5),
      PlayerInfo(name: 'MARK MARIO YANNOPOULOS', number: 17),
      PlayerInfo(name: 'MARC GIMENEZ LASO', number: 23),
    ],
    coaches: [
      CoachInfo(name: 'HECTOR FENOLL JAREÑO', role: 'Entrenador'),
    ],
  ),

  // Unió Benetússer-Favara C.F. 'A'
  TeamRoster(
    teamName: 'Unió Benetússer-Favara C.F. \'A\'',
    logoPath: TeamLogoHelper.teamLogos['Unió Benetússer-Favara C.F. \'A\''],
    starters: [
      PlayerInfo(name: 'ANGEL CORTES GINER', number: 1, position: 'Pt'),
      PlayerInfo(name: 'OSCAR CASAL MARCO', number: 8),
      PlayerInfo(name: 'LEO PORRO GALLARDO', number: 9, position: 'C'),
      PlayerInfo(name: 'AITOR ARNAL ANTON', number: 10),
      PlayerInfo(name: 'ALVARO BERMEJO AMO', number: 11),
      PlayerInfo(name: 'LEO VELARDE SORIA', number: 15),
      PlayerInfo(name: 'FERNANDO VIDAL ROMEU', number: 16),
      PlayerInfo(name: 'JOSÉ ALCANTARILLA BONILLA', number: 17),
    ],
    substitutes: [
      PlayerInfo(name: 'LUCAS PÉREZ RODRÍGUEZ', number: 3),
      PlayerInfo(name: 'PAU SERRANO GIMÉNEZ', number: 5),
      PlayerInfo(name: 'SERGIO ZAMORA GARGALLO', number: 7),
      PlayerInfo(name: 'ARNAU CLAUDIO VILLAR', number: 14),
      PlayerInfo(name: 'ALAN CORTES GINER', number: 23),
      PlayerInfo(name: 'RODRIGO ALBERT SORIA', number: 31),
    ],
    coaches: [
      CoachInfo(name: 'ISRAEL MONTESINOS HIGON', role: 'Entrenador'),
    ],
  ),

  // U.D. Alzira 'A'
  TeamRoster(
    teamName: 'U.D. Alzira \'A\'',
    logoPath: TeamLogoHelper.teamLogos['U.D. Alzira \'A\''],
    starters: [
      PlayerInfo(name: 'MOHAMED AMIN', number: 1, position: 'Pt'),
      PlayerInfo(name: 'MAURO', number: 2),
      PlayerInfo(name: 'Sanjaime', number: 4),
      PlayerInfo(name: 'THIAGO', number: 6),
      PlayerInfo(name: 'MARC', number: 10, position: 'C'),
      PlayerInfo(name: 'cristian', number: 11),
      PlayerInfo(name: 'aimar', number: 14),
      PlayerInfo(name: 'daniel', number: 19),
    ],
    substitutes: [
      PlayerInfo(name: 'Román', number: 7),
      PlayerInfo(name: 'NEIZAN', number: 15),
    ],
    coaches: [
      CoachInfo(name: 'FERNANDO ALMIÑANA CHINCHILLA', role: 'Entrenador'),
    ],
  ),

  // C.F.B. Ciutat de València 'A'
  TeamRoster(
    teamName: 'C.F.B. Ciutat de València \'A\'',
    logoPath: TeamLogoHelper.teamLogos['C.F.B. Ciutat de València \'A\''],
    starters: [
      PlayerInfo(name: 'ANGEL THOMAS INFANTE LIZCANO', number: 1, position: 'Pt'),
      PlayerInfo(name: 'NOAH LECHA VALCARCEL', number: 7),
      PlayerInfo(name: 'MATHIAS SANDRO MORALES MANCO', number: 11),
      PlayerInfo(name: 'JOHANN ANDRES MESIAS SANCHEZ', number: 14),
      PlayerInfo(name: 'PEDRO VICENTE PEREZ', number: 17, position: 'C'),
      PlayerInfo(name: 'DENIS TSEKHANOVSKII', number: 18),
      PlayerInfo(name: 'ALEX HERNANDEZ FORTEA', number: 19),
      PlayerInfo(name: 'MARCO KAES GARCIA', number: 22),
    ],
    substitutes: [
      PlayerInfo(name: 'ALESSANDRO LEON ESQUIVEL', number: 8),
      PlayerInfo(name: 'HUGO SORIANO ASENSIO', number: 9),
      PlayerInfo(name: 'PABLO CASANOVA ORTÍ', number: 10),
      PlayerInfo(name: 'JUAN BONMATÍ MONTESINOS', number: 12),
    ],
    coaches: [
      CoachInfo(name: 'MOISES SALVADOR FORTEA', role: 'Entrenador'),
    ],
  ),

  // C.D. San Marcelino 'A' (ya existente)
  TeamRoster(
    teamName: 'C.D. San Marcelino \'A\'',
    logoPath: TeamLogoHelper.teamLogos['C.D. San Marcelino \'A\''],
    starters: [],
    substitutes: [
      PlayerInfo(name: 'JAIDER ANDRES ALCIBAR GOMEZ'),
      PlayerInfo(name: 'JORGE ARCOBA BIOT'),
      PlayerInfo(name: 'ALEJANDRO BALLESTEROS HUERTA'),
      PlayerInfo(name: 'MARTIN CABEZA CAÑAS'),
      PlayerInfo(name: 'IKER DOLZ SANCHEZ'),
      PlayerInfo(name: 'RAUL LAZURAN'),
      PlayerInfo(name: 'UNAI LILLO AVILA'),
      PlayerInfo(name: 'HUGO MARTÍNEZ RIAZA'),
      PlayerInfo(name: 'SAMUEL ALEJANDRO PAREDES CASTRO'),
      PlayerInfo(name: 'JULEN PARRAGA MORENO'),
      PlayerInfo(name: 'DYLAN STEVEN RAMOS GONZALEZ'),
      PlayerInfo(name: 'EMMANUEL RINCON SANCHEZ'),
      PlayerInfo(name: 'MARCOS RODRIGUEZ GIMENEZ'),
    ],
    coaches: [
      CoachInfo(name: 'JOSE EMILIO FARINOS CERVERA', role: 'Técnico'),
    ],
  ),
];
