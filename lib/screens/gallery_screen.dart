import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();
      if (response['role'] != null) {
        setState(() {
          userRole = response['role'];
        });
      }
    }
  }

  Future<void> _upload() async {
    final res = await picker.pickImage(source: ImageSource.gallery);
    if (res != null) {
      final bytes = await res.readAsBytes();
      final newName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Supabase.instance.client.storage
          .from('gallery')
          .uploadBinary(newName, bytes);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Subida!"),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final files = Supabase.instance.client.storage.from('gallery').list();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Galería'),
        actions: [
          if (userRole == 'coach')
            IconButton(
              icon: const Icon(Icons.add_a_photo),
              onPressed: _upload,
              tooltip: 'Subir Foto',
            ),
        ],
      ),
      body: FutureBuilder<List<FileObject>>(
        future: files,
        builder: (c, s) {
          if (!s.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final f = s.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: f.length,
            itemBuilder: (c, i) {
              final url = Supabase.instance.client.storage
                  .from('gallery')
                  .getPublicUrl(f[i].name);
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(url, fit: BoxFit.cover),
              );
            },
          );
        },
      ),
    );
  }
}
