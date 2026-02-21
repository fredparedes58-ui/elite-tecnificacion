// ============================================================
// VICTORY SHARE SCREEN - "Victory Mode" (Viralización)
// ============================================================
// Pantalla para compartir victorias simultáneamente:
// 1. Guardar en el feed social de la app (R2 + Supabase)
// 2. Abrir menú nativo para compartir en Instagram/WhatsApp
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/social_post_model.dart';
import '../services/social_service.dart';
import '../services/media_upload_service.dart';

class VictoryShareScreen extends StatefulWidget {
  final File imageFile;

  const VictoryShareScreen({
    super.key,
    required this.imageFile,
  });

  @override
  State<VictoryShareScreen> createState() => _VictoryShareScreenState();
}

class _VictoryShareScreenState extends State<VictoryShareScreen> {
  final SocialService _socialService = SocialService();
  final MediaUploadService _mediaUploadService = MediaUploadService();

  bool _isPublishing = false;
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'VICTORY SHARE',
          style: GoogleFonts.oswald(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: theme.primaryColor,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isPublishing ? _buildPublishingState() : _buildPreviewState(),
      ),
    );
  }

  Widget _buildPreviewState() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Vista Previa de la Imagen
          Container(
            height: 500,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.primaryColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                widget.imageFile,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Botón Mágico: Publicar y Compartir
          ElevatedButton.icon(
            onPressed: _handleVictoryShare,
            icon: const Icon(Icons.share, size: 28),
            label: Text(
              '📢 PUBLICAR Y COMPARTIR VICTORIA',
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 1.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
            ),
          ),

          const SizedBox(height: 16),

          // Texto informativo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1D1E33),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Esta foto se guardará en el feed del equipo y se abrirá el menú para compartir en Instagram, WhatsApp y más.',
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublishingState() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 6,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.primaryColor,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _statusMessage.isEmpty ? 'Procesando...' : _statusMessage,
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Por favor espera',
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ============================================================
  /// LÓGICA DUAL: Guardar Interno + Compartir Externo
  /// ============================================================

  Future<void> _handleVictoryShare() async {
    // Verificar autenticación
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      _showError('Usuario no autenticado');
      return;
    }

    setState(() {
      _isPublishing = true;
      _statusMessage = 'Guardando en la app...';
    });

    try {
      // ==========================================
      // FASE A: GUARDAR EN LA APP (Interna)
      // ==========================================

      // 1. Subir imagen a R2
      _updateStatus('Subiendo imagen a la nube...');
      final String mediaUrl = await _mediaUploadService.uploadPhoto(
        widget.imageFile,
      );

      // 2. Obtener teamId del usuario actual
      _updateStatus('Obteniendo información del equipo...');
      final String teamId = await _getCurrentTeamId();

      // 3. Crear post en Supabase
      _updateStatus('Publicando en el feed...');
      final postDto = CreateSocialPostDto(
        teamId: teamId,
        userId: currentUser.id,
        contentText: '¡Gran momento del equipo! 🏆',
        mediaUrl: mediaUrl,
        mediaType: MediaType.image,
        thumbnailUrl: null,
      );

      await _socialService.createPost(postDto: postDto);

      // ==========================================
      // FASE B: COMPARTIR EXTERNAMENTE (Viralizar)
      // ==========================================

      _updateStatus('Preparando para compartir...');

      // Usar share_plus para abrir el menú nativo de compartir
      await Share.shareXFiles(
        [XFile(widget.imageFile.path)],
        text: '¡Mira el partidazo de nuestro equipo! #FutbolBase 🏆',
        subject: 'Victoria del equipo',
      );

      // Éxito: Cerrar pantalla y mostrar mensaje
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '¡Victoria compartida exitosamente!',
                    style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error en Victory Share: $e');
      _showError('Error al compartir: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isPublishing = false;
          _statusMessage = '';
        });
      }
    }
  }

  void _updateStatus(String message) {
    if (mounted) {
      setState(() {
        _statusMessage = message;
      });
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Obtiene el ID del equipo del usuario actual
  Future<String> _getCurrentTeamId() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception("Usuario no autenticado");

      final response = await Supabase.instance.client
          .from('team_members')
          .select('team_id')
          .eq('user_id', userId)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return response['team_id'] as String;
      }

      // Si no encuentra el equipo del usuario, intenta obtener el primer equipo disponible
      final team = await Supabase.instance.client
          .from('teams')
          .select('id')
          .limit(1)
          .maybeSingle();

      if (team != null) {
        return team['id'] as String;
      }

      throw Exception("No se pudo obtener el equipo");
    } catch (e) {
      debugPrint('❌ Error obteniendo teamId: $e');
      rethrow;
    }
  }
}
