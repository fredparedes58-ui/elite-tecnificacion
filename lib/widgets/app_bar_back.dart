import 'package:flutter/material.dart';

/// AppBar con botón Atrás visible cuando la ruta puede hacer pop.
/// Uso en pantallas de flujo profundo para UX móvil consistente.
AppBar buildAppBarWithBack(
  BuildContext context, {
  required Widget title,
  List<Widget>? actions,
  PreferredSizeWidget? bottom,
  bool? automaticallyImplyLeading,
  Color? backgroundColor,
  double? elevation,
}) {
  final canPop = Navigator.canPop(context);
  return AppBar(
    leading: canPop
        ? IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.maybePop(context),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          )
        : null,
    automaticallyImplyLeading: automaticallyImplyLeading ?? canPop,
    title: title,
    actions: actions,
    bottom: bottom,
    backgroundColor: backgroundColor,
    elevation: elevation ?? 0,
  );
}
