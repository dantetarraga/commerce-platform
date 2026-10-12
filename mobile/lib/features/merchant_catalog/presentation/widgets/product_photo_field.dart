import 'dart:io';
import 'dart:math' as math;

import 'package:apamuy/features/merchant_catalog/domain/menu.dart';
import 'package:apamuy/features/merchant_catalog/presentation/widgets/photo_picker.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Lo que el dueño eligió para la foto: la que ya tenía, una nueva o ninguna.
sealed class PhotoChoice {
  const PhotoChoice();
}

final class KeepPhoto extends PhotoChoice {
  const KeepPhoto(this.url);

  final String? url;
}

final class NewPhoto extends PhotoChoice {
  const NewPhoto(this.photo);

  final PickedPhoto photo;
}

final class NoPhoto extends PhotoChoice {
  const NoPhoto();
}

/// Foto grande del producto, como la verá el cliente. Se cambia desde una hoja
/// (cámara, galería o quitar) y se sube al guardar.
class ProductPhotoField extends StatelessWidget {
  const ProductPhotoField({required this.value, required this.onChanged, this.enabled = true, super.key});

  final PhotoChoice value;
  final ValueChanged<PhotoChoice> onChanged;
  final bool enabled;

  bool get _hasPhoto => switch (value) {
    NewPhoto() => true,
    KeepPhoto(:final url) => url != null && url.isNotEmpty,
    NoPhoto() => false,
  };

  Future<void> _change(BuildContext context) async {
    final source = await showPhotoSourceSheet(context, canRemove: _hasPhoto);
    if (source == null || !context.mounted) return;
    if (source == PhotoSource.remove) return onChanged(const NoPhoto());
    final photo = await pickPhoto(context, source);
    if (photo != null) onChanged(NewPhoto(photo));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final image = switch (value) {
      NewPhoto(:final photo) => Image.file(File(photo.path), fit: BoxFit.cover),
      KeepPhoto(:final url?) when url.isNotEmpty => AppNetworkImage(url: url),
      _ => ColoredBox(
        color: context.apamuy.raised,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_a_photo_outlined, size: 36, color: scheme.onSurfaceVariant),
              const SizedBox(height: AppSpacing.xs),
              Text('Sin foto', style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    };
    return Semantics(
      label: _hasPhoto ? 'Foto del producto' : 'El producto no tiene foto',
      child: ClipRRect(
        borderRadius: AppRadius.tile,
        child: LayoutBuilder(
          // 16:10, sin pasar de 260 px en tablet.
          builder: (context, constraints) => SizedBox(
            height: math.min(constraints.maxWidth * 10 / 16, 260),
            child: Stack(
              fit: StackFit.expand,
              children: [
                image,
                Positioned(
                  right: AppSpacing.sm,
                  bottom: AppSpacing.sm,
                  child: FilledButton.icon(
                    onPressed: enabled ? () => _change(context) : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.inverseSurface.withValues(alpha: 0.86),
                      foregroundColor: scheme.onInverseSurface,
                      minimumSize: const Size(0, AppSpacing.minTouch - 4),
                    ),
                    icon: const Icon(Icons.photo_camera_outlined, size: 20),
                    label: Text(_hasPhoto ? 'Cambiar foto' : 'Agregar foto'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
