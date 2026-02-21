import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:myapp/widgets/app_bar_back.dart';
import 'package:myapp/widgets/empty_state_widget.dart';
import 'package:myapp/utils/snackbar_helper.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final picker = ImagePicker();
  String? userRole;

  @override
  void initState() {
    super.initState();
    _getUserRole();
  }

  Future<void> _getUserRole() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .maybeSingle();
        
        if (response != null && response['role'] != null && mounted) {
          setState(() {
            userRole = response['role'] as String?;
          });
        }
      }
    } catch (e) {
      debugPrint('Error obteniendo rol de usuario: $e');
      // Si falla, intentar obtener desde team_members
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          final teamMember = await Supabase.instance.client
              .from('team_members')
              .select('role')
              .eq('user_id', user.id)
              .maybeSingle();
          
          if (teamMember != null && teamMember['role'] != null && mounted) {
            setState(() {
              userRole = teamMember['role'] as String?;
            });
          }
        }
      } catch (e2) {
        debugPrint('Error obteniendo rol desde team_members: $e2');
      }
    }
  }

  Future<void> _upload() async {
    try {
      final res = await picker.pickImage(source: ImageSource.gallery);
      if (res != null) {
        final bytes = await res.readAsBytes();
        final newName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        await Supabase.instance.client.storage
            .from('gallery')
            .uploadBinary(newName, bytes);
        
        if (mounted) {
          setState(() {});
          SnackBarHelper.showSuccess(context, "Foto subida exitosamente");
        }
      }
    } catch (e) {
      debugPrint('Error subiendo foto: $e');
      if (mounted) {
        SnackBarHelper.showError(
          context,
          "Error al subir foto: ${e.toString()}",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final files = Supabase.instance.client.storage.from('gallery').list();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: buildAppBarWithBack(
        context,
        title: Text(
          'Galería',
          style: GoogleFonts.oswald(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (userRole == 'coach')
            IconButton(
              icon: const Icon(Icons.add_a_photo),
              onPressed: _upload,
              tooltip: 'Subir Foto',
            ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<FileObject>>(
        future: files,
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cargando galería...',
                    style: GoogleFonts.roboto(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          // Error state
          if (snapshot.hasError) {
            return EmptyStateWidget(
              icon: Icons.broken_image_outlined,
              title: 'Error al cargar la galería',
              subtitle: 'Por favor, intenta de nuevo más tarde',
              actionLabel: 'Reintentar',
              onAction: () {
                setState(() {});
              },
            );
          }

          final filesList = snapshot.data ?? [];

          // Empty state
          if (filesList.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.photo_library_outlined,
              title: 'Galería vacía',
              subtitle: userRole == 'coach'
                  ? 'Comparte los mejores momentos del equipo'
                  : 'Aún no hay fotos en la galería',
              actionLabel: userRole == 'coach' ? 'Subir primera foto' : null,
              onAction: userRole == 'coach' ? _upload : null,
            );
          }

          // Gallery grid
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: filesList.length,
              itemBuilder: (context, index) {
                final file = filesList[index];
                final url = Supabase.instance.client.storage
                    .from('gallery')
                    .getPublicUrl(file.name);
                
                return Hero(
                  tag: 'gallery_${file.name}',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // TODO: Navegar a vista completa de imagen
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Imagen: ${file.name}'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: theme.colorScheme.errorContainer.withOpacity(0.3),
                            child: Icon(
                              Icons.broken_image,
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      ),
    );
  }
}
