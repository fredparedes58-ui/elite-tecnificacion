// ============================================================
// Modal: Términos de Seguridad y Derechos de Imagen
// El padre debe aceptar obligatoriamente antes de subir foto del hijo.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Muestra el modal de términos. Retorna true si el usuario acepta, false si cierra sin aceptar.
Future<bool> showTermsOfImageModal(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _TermsOfImageDialog(),
  );
  return result ?? false;
}

/// Comprueba si el usuario actual ya aceptó los términos (profiles.image_rights_terms_accepted_at).
Future<bool> hasAcceptedImageTerms(String? userId) async {
  if (userId == null) return false;
  try {
    final res = await Supabase.instance.client
        .from('profiles')
        .select('image_rights_terms_accepted_at')
        .eq('id', userId)
        .maybeSingle();
    return res != null && res['image_rights_terms_accepted_at'] != null;
  } catch (_) {
    return false;
  }
}

/// Marca en el perfil que el usuario aceptó los términos.
Future<void> setImageTermsAccepted(String userId) async {
  await Supabase.instance.client
      .from('profiles')
      .update({'image_rights_terms_accepted_at': DateTime.now().toUtc().toIso8601String()})
      .eq('id', userId);
}

class _TermsOfImageDialog extends StatelessWidget {
  const _TermsOfImageDialog();

  static const String _termsText = '''
TÉRMINOS DE SEGURIDAD Y DERECHOS DE IMAGEN

Al subir una fotografía de su hijo/a, usted declara y acepta:

1. Seguridad y privacidad: La imagen se utilizará únicamente en el ámbito de la escuela/actividad y con las medidas de seguridad y acceso que la organización tenga establecidas.

2. Derechos de imagen: Usted, como padre/madre o tutor legal, autoriza el uso de la imagen del menor en los canales y soportes que la organización utilice para fines educativos, informativos o promocionales de la actividad, dentro del marco legal aplicable.

3. Revocación: Puede solicitar en cualquier momento la retirada o no uso de la imagen del menor, dirigiéndose a la organización.

4. Veracidad: Declara que la imagen corresponde a su hijo/a o menor bajo su tutela y que tiene capacidad legal para prestar esta autorización.

Al pulsar "Acepto" confirma que ha leído y acepta estos términos.
''';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.security, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Términos de Seguridad y Derechos de Imagen',
              style: GoogleFonts.roboto(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _termsText,
                style: GoogleFonts.roboto(fontSize: 13, height: 1.4),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Acepto'),
        ),
      ],
    );
  }
}
