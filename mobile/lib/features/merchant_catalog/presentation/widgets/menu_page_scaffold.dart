import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:apamuy/shared/partner/partner.dart';
import 'package:flutter/material.dart';

/// Armazón de las pantallas de la carta: cabecera de Socios, contenido centrado
/// y, si hay [bottom], la acción principal fija abajo.
class MenuPageScaffold extends StatelessWidget {
  const MenuPageScaffold({
    required this.title,
    required this.accent,
    required this.body,
    this.bottom,
    this.trailing = const [],
    this.showBack = true,
    super.key,
  });

  final String title;
  final String accent;
  final Widget body;
  final Widget? bottom;
  final List<Widget> trailing;

  /// Sin botón de volver: dentro del panel lateral en tablet.
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: partnerStatusBar(context),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            PartnerPageHeader(
              eyebrow: '${brandName.toUpperCase()} SOCIOS · CARTA',
              title: title,
              accent: accent,
              titleSize: 24,
              showBack: showBack,
              trailing: trailing,
            ),
            Expanded(child: PartnerContent(maxWidth: 760, child: body)),
          ],
        ),
      ),
      bottomNavigationBar: bottom == null ? null : MenuBottomBar(child: bottom!),
    );
  }
}

/// La acción principal fija abajo, del ancho del contenido.
class MenuBottomBar extends StatelessWidget {
  const MenuBottomBar({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.sm),
        // Column con tamaño mínimo: sin ella, el botón ocupa toda la pantalla.
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760), child: child),
          ],
        ),
      ),
    );
  }
}
