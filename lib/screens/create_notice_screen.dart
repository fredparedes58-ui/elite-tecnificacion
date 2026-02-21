// ============================================================
// PANTALLA: CREAR COMUNICADO OFICIAL
// ============================================================
// Formulario para que los entrenadores creen anuncios
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/services/supabase_service.dart';
import 'package:myapp/widgets/app_bar_back.dart';
import 'package:myapp/services/file_management_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/utils/snackbar_helper.dart';
import 'dart:io';

class CreateNoticeScreen extends StatefulWidget {
  const CreateNoticeScreen({super.key});

  @override
  State<CreateNoticeScreen> createState() => _CreateNoticeScreenState();
}

class _CreateNoticeScreenState extends State<CreateNoticeScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final FileManagementService _fileService = FileManagementService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  String? _attachmentUrl;
  String? _attachmentFileName;
  bool _isUrgent = false;
  bool _isUploading = false;
  bool _isSaving = false;
  bool _isTeamNotice = true; // true = equipo, false = club
  String? _currentTeamId;
  bool _isCoachOrAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _loadCurrentTeamId();
  }

  Future<void> _checkUserRole() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        // Si no hay usuario, redirigir
        if (mounted) {
          Navigator.pop(context);
          SnackBarHelper.showError(context, 'Debes iniciar sesión para crear avisos');
        }
        return;
      }

      final response = await Supabase.instance.client
          .from('team_members')
          .select('role')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null && mounted) {
        final isCoachOrAdmin = ['coach', 'admin'].contains(response['role']);
        setState(() {
          _isCoachOrAdmin = isCoachOrAdmin;
        });

        // Si no es coach/admin, mostrar error y cerrar
        if (!isCoachOrAdmin) {
          Navigator.pop(context);
          SnackBarHelper.showWarning(context, 'Solo los entrenadores pueden crear avisos');
        }
      } else {
        // No está en team_members, no puede crear avisos
        if (mounted) {
          Navigator.pop(context);
          SnackBarHelper.showWarning(context, 'No tienes permisos para crear avisos');
        }
      }
    } catch (e) {
      debugPrint('Error verificando rol: $e');
      if (mounted) {
        Navigator.pop(context);
        SnackBarHelper.showError(context, 'Error verificando permisos: $e');
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentTeamId() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('team_members')
          .select('team_id')
          .eq('user_id', userId)
          .limit(1)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _currentTeamId = response['team_id'] as String?;
        });
      }
    } catch (e) {
      debugPrint('Error obteniendo teamId: $e');
    }
  }

  Future<void> _pickAttachment() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;

      setState(() {
        _isUploading = true;
        _attachmentFileName = fileName;
      });

      // Subir archivo
      String? url;
      if (fileName.toLowerCase().endsWith('.pdf')) {
        url = await _fileService.uploadPDF(
          pdf: file,
          folder: 'notices',
          pdfName: fileName,
        );
      } else {
        url = await _fileService.uploadImage(
          image: file,
          folder: 'notices',
          imageName: fileName,
        );
      }

      setState(() {
        _isUploading = false;
        if (url != null) {
          _attachmentUrl = url;
        } else {
          _attachmentFileName = null;
        }
      });
      if (!mounted) return;
      if (url == null) {
        SnackBarHelper.showError(context, 'Error al subir el archivo');
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Error: $e');
    }
  }

  Future<void> _saveNotice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final notice = await _supabaseService.createNotice(
        teamId: _isTeamNotice ? _currentTeamId! : '', // null = club, teamId = equipo
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        priority: _isUrgent ? 'urgent' : 'normal',
        targetRoles: ['coach', 'player', 'parent', 'staff'], // Todos los roles por defecto
        attachmentUrl: _attachmentUrl,
      );

      if (notice.isNotEmpty && mounted) {
        Navigator.pop(context, true);
        SnackBarHelper.showSuccess(context, 'Comunicado creado exitosamente');
      } else {
        throw Exception('No se pudo crear el comunicado');
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si no es coach/admin, mostrar mensaje (aunque ya debería haber sido redirigido en initState)
    if (!_isCoachOrAdmin) {
      return Scaffold(
        appBar: buildAppBarWithBack(context, title: const Text('Crear Aviso')),
        body: SafeArea(
          child: const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No tienes permisos para crear avisos. Solo los entrenadores pueden crear comunicados.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: buildAppBarWithBack(
        context,
        title: Text(
          'NUEVO COMUNICADO',
          style: GoogleFonts.oswald(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 1.5,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Título
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Título',
                hintText: 'Ej: Horario del Autobús para el Domingo',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.title),
              ),
              style: GoogleFonts.roboto(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El título es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Contenido
            TextFormField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: 'Contenido',
                hintText: 'Escribe el mensaje del comunicado...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                alignLabelWithHint: true,
              ),
              style: GoogleFonts.roboto(),
              maxLines: 8,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El contenido es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Selector de tipo de comunicado
            Card(
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: colorScheme.primary.withValues(alpha: 0.3),
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
                          Icons.category,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tipo de Comunicado',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() => _isTeamNotice = true);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _isTeamNotice
                                    ? colorScheme.primary.withValues(alpha: 0.3)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _isTeamNotice
                                      ? colorScheme.primary
                                      : Colors.white24,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.group,
                                    size: 20,
                                    color: _isTeamNotice
                                        ? colorScheme.primary
                                        : Colors.white54,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Equipo',
                                    style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      fontWeight: _isTeamNotice
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: _isTeamNotice
                                          ? colorScheme.primary
                                          : Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() => _isTeamNotice = false);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: !_isTeamNotice
                                    ? colorScheme.primary.withValues(alpha: 0.3)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: !_isTeamNotice
                                      ? colorScheme.primary
                                      : Colors.white24,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.business,
                                    size: 20,
                                    color: !_isTeamNotice
                                        ? colorScheme.primary
                                        : Colors.white54,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Club',
                                    style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      fontWeight: !_isTeamNotice
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: !_isTeamNotice
                                          ? colorScheme.primary
                                          : Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isTeamNotice
                          ? 'El comunicado será visible solo para tu equipo'
                          : 'El comunicado será visible para todo el club',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Toggle Urgente
            Card(
              color: Colors.red.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _isUrgent
                      ? Colors.red.withValues(alpha: 0.5)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: SwitchListTile(
                title: Text(
                  'Marcar como Urgente',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.bold,
                    color: _isUrgent ? Colors.red : Colors.white,
                  ),
                ),
                subtitle: Text(
                  'Los comunicados urgentes aparecen con borde rojo',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
                value: _isUrgent,
                onChanged: (value) {
                  setState(() => _isUrgent = value);
                },
                secondary: Icon(
                  Icons.priority_high,
                  color: _isUrgent ? Colors.red : Colors.white54,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Adjunto
            Card(
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: colorScheme.primary.withValues(alpha: 0.3),
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
                          Icons.attach_file,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Archivo Adjunto',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PDFs o imágenes (horarios, documentos importantes)',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_attachmentFileName != null && !_isUploading) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _attachmentFileName!,
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () {
                                setState(() {
                                  _attachmentUrl = null;
                                  _attachmentFileName = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (_isUploading)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ElevatedButton.icon(
                      onPressed: _isUploading ? null : _pickAttachment,
                      icon: const Icon(Icons.upload_file),
                      label: Text(_attachmentFileName == null
                          ? 'Seleccionar Archivo'
                          : 'Cambiar Archivo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Botón Guardar
            ElevatedButton(
              onPressed: _isSaving ? null : _saveNotice,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'PUBLICAR COMUNICADO',
                      style: GoogleFonts.oswald(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
