import 'package:myapp/models/drill_model.dart';

final List<Drill> defensiveDrills = [
  Drill(
    title: 'High Press Transition',
    description: 'High in position to win the ball immediately after the loss.',
    category: 'Defensa',
    intensity: DrillIntensity.alta,
    players: '4-6',
    time: '15m',
    imagePath: 'https://i.ytimg.com/vi/5-a5pOA_f7k/maxresdefault.jpg',
  ),
  Drill(
    title: 'Low Block Organization',
    description: 'Structure a compact defense in the defensive third.',
    category: 'Defensa',
    intensity: DrillIntensity.media,
    players: '8-10',
    time: '20m',
    imagePath: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR-Jot-O2NAE_E3pX5g-n23b08G-3cM8e2p1A&s',
  ),
  Drill(
    title: 'Zone 14 Control',
    description: 'Deny key spaces between lines.',
    category: 'Defensa',
    intensity: DrillIntensity.media,
    players: '6',
    time: '10m',
    imagePath: 'https://e1.pxfuel.com/desktop-wallpaper/813/466/desktop-wallpaper-the-zone-14-in-soccer-and-its-importance-in-the-game-pitch-lane.jpg',
  ),
];

final List<Drill> offensiveDrills = [
  Drill(
    title: 'Attacking Overloads',
    description: 'Create numerical superiority in wide areas.',
    category: 'Ataque',
    intensity: DrillIntensity.alta,
    players: '6-8',
    time: '20m',
    imagePath: 'https://i.ytimg.com/vi/A_2n-jI5a3w/maxresdefault.jpg',
  ),
  Drill(
    title: 'Third Man Runs',
    description: 'Improve combination play to break lines.',
    category: 'Ataque',
    intensity: DrillIntensity.media,
    players: '6',
    time: '15m',
    imagePath: 'https://i.ytimg.com/vi/c0e_9q0-p_M/maxresdefault.jpg',
  ),
];
