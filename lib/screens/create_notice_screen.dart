// ============================================================
// PANTALLA: CREAR COMUNICADO OFICIAL
// ============================================================
// Formulario para que los entrenadores creen anuncios
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/models/notice_board_post_model.dart';
import 'package:myapp/services/supabase_service.dart';
import 'package:myapp/services/file_management_service.dart';
import 'package:file_picker/file_picker.dart';
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

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al subir el archivo'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveNotice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final notice = await _supabaseService.createNotice(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        attachmentUrl: _attachmentUrl,
        priority: _isUrgent ? NoticePriority.urgent : NoticePriority.normal,
      );

      if (notice != null && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comunicado creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('No se pudo crear el comunicado');
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
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
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
      body: Form(
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

            // Toggle Urgente
            Card(
              color: Colors.red.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _isUrgent
                      ? Colors.red.withOpacity(0.5)
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
                          color: Colors.green.withOpacity(0.1),
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
    );
  }
}
