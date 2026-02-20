// ============================================================
// PANTALLA: GESTIÓN DE ENTRENAMIENTOS POR CATEGORÍAS
// ============================================================
// Permite gestionar entrenamientos con archivos y texto
// por categorías específicas
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/services/file_management_service.dart' show FileManagementService;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

enum TrainingCategory {
  ataque('Ataque', Icons.sports_soccer, Colors.red),
  defensa('Defensa', Icons.shield, Colors.blue),
  unoContraUno('Uno contra uno', Icons.person_outline, Colors.orange),
  duelos('Duelos', Icons.flash_on, Colors.purple),
  resistencia('Resistencia', Icons.directions_run, Colors.green),
  fuerza('Fuerza', Icons.fitness_center, Colors.indigo),
  pliometria('Pliometría', Icons.trending_up, Colors.pink);

  final String label;
  final IconData icon;
  final Color color;

  const TrainingCategory(this.label, this.icon, this.color);
}

class TrainingContent {
  final String id;
  final String category;
  final String? text;
  final List<String> fileUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TrainingContent({
    required this.id,
    required this.category,
    this.text,
    this.fileUrls = const [],
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'text': text,
      'file_urls': fileUrls,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory TrainingContent.fromMap(Map<String, dynamic> map) {
    return TrainingContent(
      id: map['id'] as String,
      category: map['category'] as String,
      text: map['text'] as String?,
      fileUrls: List<String>.from(map['file_urls'] ?? []),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }
}

class TrainingCategoriesScreen extends StatefulWidget {
  const TrainingCategoriesScreen({super.key});

  @override
  State<TrainingCategoriesScreen> createState() => _TrainingCategoriesScreenState();
}

class _TrainingCategoriesScreenState extends State<TrainingCategoriesScreen> {
  final FileManagementService _fileService = FileManagementService();
  final Map<String, TrainingContent> _categoryContents = {};
  final Map<String, bool> _loadingCategories = {};
  final Map<String, TextEditingController> _textControllers = {};

  @override
  void initState() {
    super.initState();
    _loadAllCategories();
  }

  @override
  void dispose() {
    for (var controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAllCategories() async {
    for (var category in TrainingCategory.values) {
      await _loadCategory(category);
    }
  }

  Future<void> _loadCategory(TrainingCategory category) async {
    setState(() {
      _loadingCategories[category.name] = true;
    });

    try {
      final teamId = await _getCurrentTeamId();
      if (teamId == null) return;

      final response = await Supabase.instance.client
          .from('training_contents')
          .select()
          .eq('team_id', teamId)
          .eq('category', category.name)
          .maybeSingle();

      if (response != null) {
        final content = TrainingContent.fromMap(response);
        setState(() {
          _categoryContents[category.name] = content;
          _textControllers[category.name] = TextEditingController(text: content.text ?? '');
        });
      } else {
        setState(() {
          _textControllers[category.name] = TextEditingController();
        });
      }
    } catch (e) {
      debugPrint('Error cargando categoría ${category.name}: $e');
    } finally {
      setState(() {
        _loadingCategories[category.name] = false;
      });
    }
  }

  Future<String?> _getCurrentTeamId() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await Supabase.instance.client
          .from('team_members')
          .select('team_id')
          .eq('user_id', userId)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return response['team_id'] as String;
      }
      return null;
    } catch (e) {
      debugPrint('Error obteniendo teamId: $e');
      return null;
    }
  }

  Future<void> _saveCategoryContent(TrainingCategory category) async {
    final teamId = await _getCurrentTeamId();
    if (teamId == null) return;

    final text = _textControllers[category.name]?.text.trim();
    final existingContent = _categoryContents[category.name];

    try {
      if (existingContent == null) {
        // Crear nuevo contenido
        final newContent = TrainingContent(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          category: category.name,
          text: text?.isEmpty == true ? null : text,
          fileUrls: [],
          createdAt: DateTime.now(),
        );

        await Supabase.instance.client.from('training_contents').insert({
          'id': newContent.id,
          'team_id': teamId,
          'category': category.name,
          'text': newContent.text,
          'file_urls': newContent.fileUrls,
          'created_at': newContent.createdAt.toIso8601String(),
        });

        setState(() {
          _categoryContents[category.name] = newContent;
        });
      } else {
        // Actualizar contenido existente
        final updatedContent = TrainingContent(
          id: existingContent.id,
          category: category.name,
          text: text?.isEmpty == true ? null : text,
          fileUrls: existingContent.fileUrls,
          createdAt: existingContent.createdAt,
          updatedAt: DateTime.now(),
        );

        await Supabase.instance.client
            .from('training_contents')
            .update({
              'text': updatedContent.text,
              'file_urls': updatedContent.fileUrls,
              'updated_at': updatedContent.updatedAt?.toIso8601String(),
            })
            .eq('id', existingContent.id);

        setState(() {
          _categoryContents[category.name] = updatedContent;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${category.label} guardado correctamente'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error guardando categoría: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadFileToCategory(TrainingCategory category) async {
    try {
      final file = await _fileService.pickFile();
      if (file == null) return;

      // Subir archivo a Supabase Storage
      final fileUrl = await _fileService.uploadFile(
        file: file,
        folder: 'training-files',
        fileName: '${category.name}_${DateTime.now().millisecondsSinceEpoch}.${file.path.split('.').last}',
      );

      if (fileUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al subir archivo'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Obtener contenido existente o crear uno nuevo
      final teamId = await _getCurrentTeamId();
      if (teamId == null) return;

      final existingContent = _categoryContents[category.name];
      final currentUrls = existingContent?.fileUrls ?? [];
      final updatedUrls = [...currentUrls, fileUrl];

      if (existingContent == null) {
        // Crear nuevo contenido con el archivo
        final text = _textControllers[category.name]?.text.trim();
        final newContent = TrainingContent(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          category: category.name,
          text: text?.isEmpty == true ? null : text,
          fileUrls: updatedUrls,
          createdAt: DateTime.now(),
        );

        await Supabase.instance.client.from('training_contents').insert({
          'id': newContent.id,
          'team_id': teamId,
          'category': category.name,
          'text': newContent.text,
          'file_urls': updatedUrls,
          'created_at': newContent.createdAt.toIso8601String(),
        });

        setState(() {
          _categoryContents[category.name] = newContent;
        });
      } else {
        // Actualizar contenido existente
        await Supabase.instance.client
            .from('training_contents')
            .update({
              'file_urls': updatedUrls,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingContent.id);

        await _loadCategory(category);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Archivo agregado a ${category.label}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error subiendo archivo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeFileFromCategory(TrainingCategory category, String fileUrl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar archivo'),
        content: const Text('¿Estás seguro de que quieres eliminar este archivo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final existingContent = _categoryContents[category.name];
      if (existingContent == null) return;

      final updatedUrls = existingContent.fileUrls.where((url) => url != fileUrl).toList();

      await Supabase.instance.client
          .from('training_contents')
          .update({'file_urls': updatedUrls})
          .eq('id', existingContent.id);

      await _loadCategory(category);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Archivo eliminado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error eliminando archivo: $e');
    }
  }

  Future<void> _clearText(TrainingCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar texto'),
        content: const Text('¿Estás seguro de que quieres eliminar todo el texto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _textControllers[category.name]?.clear();
      await _saveCategoryContent(category);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ENTRENAMIENTOS',
          style: GoogleFonts.oswald(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: TrainingCategory.values.length,
        itemBuilder: (context, index) {
          final category = TrainingCategory.values[index];
          final content = _categoryContents[category.name];
          final isLoading = _loadingCategories[category.name] ?? false;
          final controller = _textControllers[category.name] ?? TextEditingController();

          return _buildCategoryCard(category, content, controller, isLoading, theme);
        },
      ),
    );
  }

  Widget _buildCategoryCard(
    TrainingCategory category,
    TrainingContent? content,
    TextEditingController controller,
    bool isLoading,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: category.color.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: category.color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con icono y nombre
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  category.color.withValues(alpha: 0.2),
                  category.color.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(category.icon, color: category.color, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category.label,
                    style: GoogleFonts.oswald(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          // Área de texto
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Descripción',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: category.color,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: Colors.red.withValues(alpha: 0.7),
                      onPressed: () => _clearText(category),
                      tooltip: 'Eliminar texto',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  maxLines: 5,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Escribe la descripción del entrenamiento...',
                    hintStyle: TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: category.color.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: category.color,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (_) {
                    // Auto-guardar después de un delay podría implementarse aquí
                  },
                ),
              ],
            ),
          ),

          // Botón guardar texto
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _saveCategoryContent(category),
                icon: const Icon(Icons.save),
                label: const Text('Guardar Texto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: category.color,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Archivos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Archivos',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: category.color,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _uploadFileToCategory(category),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: category.color.withValues(alpha: 0.2),
                    foregroundColor: category.color,
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),

          // Lista de archivos
          if (content?.fileUrls.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: content!.fileUrls.length,
                itemBuilder: (context, index) {
                  final fileUrl = content.fileUrls[index];
                  final isImage = fileUrl.contains('.jpg') ||
                      fileUrl.contains('.jpeg') ||
                      fileUrl.contains('.png') ||
                      fileUrl.contains('.gif') ||
                      fileUrl.contains('.webp');

                  return Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white24,
                            width: 1,
                          ),
                        ),
                        child: isImage
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: fileUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: category.color,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Icon(
                                    Icons.broken_image,
                                    color: Colors.white54,
                                  ),
                                ),
                              )
                            : Center(
                                child: Icon(
                                  Icons.insert_drive_file,
                                  color: category.color,
                                  size: 32,
                                ),
                              ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeFileFromCategory(category, fileUrl),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No hay archivos agregados',
                  style: TextStyle(color: Colors.white38, fontSize: 14),
                ),
              ),
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
