import 'package:myapp/models/drill_model.dart';
import 'package:uuid/uuid.dart';

final _uuid = Uuid();

// Lista unificada de todos los ejercicios de entrenamiento.
final List<Drill> allDrills = [
  // --- Ejercicios Defensivos ---
  Drill(
    id: _uuid.v4(),
    title: 'High Press Transition',
    description: 'Entrenamiento de alta intensidad para recuperar el balón inmediatamente tras la pérdida en campo rival. Objetivo: Mejorar la velocidad de reacción y la presión coordinada del equipo.',
    difficulty: 'Alta',
    category: 'Defensa',
  ),
  Drill(
    id: _uuid.v4(),
    title: 'Low Block Organization',
    description: 'Organizar una estructura defensiva compacta y sólida en el tercio defensivo para cerrar espacios. Objetivo: Fortalecer la comunicación y el posicionamiento en un bloque bajo.',
    difficulty: 'Media',
    category: 'Defensa',
  ),
  Drill(
    id: _uuid.v4(),
    title: 'Defensa 1v1 en Banda',
    description: 'Ejercicios específicos para que los defensores aprendan a temporizar, contener y robar el balón en situaciones de uno contra uno en la banda. Objetivo: Mejorar la técnica defensiva individual y evitar que los rivales centren con facilidad.',
    difficulty: 'Media',
    category: 'Defensa',
  ),
  Drill(
    id: _uuid.v4(),
    title: 'Zone 14 Control',
    description: 'Ejercicio táctico para negar espacios clave al rival en la zona entre la defensa y el mediocampo. Objetivo: Reducir las oportunidades de gol del rival y forzar errores en la construcción de su juego.',
    difficulty: 'Media',
    category: 'Defensa',
  ),

  // --- Ejercicios Ofensivos ---
  Drill(
    id: _uuid.v4(),
    title: 'Attacking Overloads',
    description: 'Crear superioridad numérica en las bandas para generar oportunidades de centro y remate. Objetivo: Mejorar la sincronización de los desmarques y la precisión en los pases finales.',
    difficulty: 'Alta',
    category: 'Ataque',
  ),
  Drill(
    id: _uuid.v4(),
    title: 'Third Man Runs',
    description: 'Mejorar el juego de combinación y los desmarques de ruptura para romper las líneas defensivas del rival. Objetivo: Aumentar la fluidez del juego ofensivo y la creación de ocasiones de gol.',
    difficulty: 'Media',
    category: 'Ataque',
  ),
  Drill(
    id: _uuid.v4(),
    title: 'Finalización Rápida tras Desmarque',
    description: 'Los atacantes practican desmarques de ruptura para recibir un pase al espacio y finalizar a portería en un solo toque. Objetivo: Mejorar la velocidad de ejecución y la efectividad de cara a gol.',
    difficulty: 'Alta',
    category: 'Ataque',
  ),

  // --- Técnica Individual ---
  Drill(
    id: _uuid.v4(),
    title: 'Circuito de Regate y Pase',
    description: 'Un circuito diseñado para mejorar el control del balón en velocidad, la precisión en el pase y la agilidad. Objetivo: Aumentar la confianza y habilidad del jugador con el balón en los pies.',
    difficulty: 'Media',
    category: 'Técnica',
  ),
];
