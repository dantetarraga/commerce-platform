import 'dart:async';

import 'package:apamuy/features/merchant_catalog/domain/menu.dart';
import 'package:apamuy/features/merchant_catalog/presentation/providers/menu_providers.dart';
import 'package:apamuy/features/merchant_catalog/presentation/widgets/photo_picker.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:apamuy/shared/partner/partner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// En la lista, en lugar de la foto que falta: toma o elige una y la guarda
/// en el producto sin abrirlo.
class QuickPhotoButton extends ConsumerStatefulWidget {
  const QuickPhotoButton({
    required this.storeId,
    required this.productId,
    required this.productName,
    this.size = 56,
    super.key,
  });

  final String storeId;
  final String productId;
  final String productName;
  final double size;

  @override
  ConsumerState<QuickPhotoButton> createState() => _QuickPhotoButtonState();
}

class _QuickPhotoButtonState extends ConsumerState<QuickPhotoButton> with PartnerActionRunner {
  double? _progress;

  Future<void> _add() async {
    final source = await showPhotoSourceSheet(context);
    if (source == null || !mounted) return;
    final photo = await pickPhoto(context, source);
    if (photo == null || !mounted) return;
    await _upload(photo);
  }

  /// Si falla, «Reintentar» vuelve a subir la misma foto.
  Future<void> _upload(PickedPhoto photo) async {
    await run(
      () => ref
          .read(menuActionsProvider.notifier)
          .setPhoto(
            widget.storeId,
            widget.productId,
            photo,
            onProgress: (p) {
              if (mounted) setState(() => _progress = p);
            },
          ),
      success: 'Foto guardada.',
      retry: () => unawaited(_upload(photo)),
    );
    if (mounted) setState(() => _progress = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return Semantics(
      button: true,
      label: 'Agregar foto a ${widget.productName}',
      excludeSemantics: true,
      child: Material(
        color: context.apamuy.raised,
        borderRadius: AppRadius.tile,
        child: InkWell(
          onTap: busy ? null : _add,
          borderRadius: AppRadius.tile,
          child: SizedBox.square(
            dimension: widget.size,
            child: busy
                ? Center(
                    child: SizedBox.square(
                      dimension: 26,
                      child: CircularProgressIndicator(
                        value: _progress,
                        strokeWidth: 3,
                        semanticsLabel: 'Subiendo la foto',
                      ),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, size: 20, color: color),
                      const SizedBox(height: 2),
                      Text(
                        'Foto',
                        textScaler: TextScaler.noScaling,
                        style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
