import 'package:apamuy/features/merchant_catalog/domain/menu.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

enum PhotoSource { camera, gallery, remove }

/// Hoja para elegir de dónde sale la foto; con [canRemove], también quitarla.
Future<PhotoSource?> showPhotoSourceSheet(BuildContext context, {bool canRemove = false}) {
  return showAppBottomSheet<PhotoSource>(
    context,
    title: 'Foto del producto',
    subtitle: 'Después la encuadras cuadrada, como se ve en la app.',
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      Widget option(PhotoSource source, IconData icon, String label, {Color? color}) => ListTile(
        minTileHeight: AppSpacing.minTouch + 8,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        leading: Icon(icon, color: color),
        title: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
        onTap: () => Navigator.pop(context, source),
      );
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              option(PhotoSource.camera, Icons.photo_camera_outlined, 'Tomar foto'),
              option(PhotoSource.gallery, Icons.photo_library_outlined, 'Elegir de la galería'),
              if (canRemove)
                option(PhotoSource.remove, Icons.delete_outline_rounded, 'Quitar foto', color: scheme.error),
            ],
          ),
        ),
      );
    },
  );
}

/// Abre la cámara o la galería y luego el recorte cuadrado. La foto sale
/// achicada (1600 px, calidad 85) para que suba rápido con datos. `null` si no
/// eligió, canceló el recorte o no se pudo.
Future<PickedPhoto?> pickPhoto(BuildContext context, PhotoSource source) async {
  final XFile? file;
  try {
    file = await ImagePicker().pickImage(
      source: source == PhotoSource.camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
  } on Exception {
    if (context.mounted) {
      AppToast.show(context, 'No pudimos abrir la cámara ni la galería.', kind: AppToastKind.error);
    }
    return null;
  }
  if (file == null || !context.mounted) return null;
  final path = await _cropSquare(context, file.path);
  if (path == null) return null;
  final photo = PickedPhoto.fromPath(path);
  if (photo == null && context.mounted) {
    AppToast.show(context, 'Elige una foto JPG, PNG o WebP.', kind: AppToastKind.error);
  }
  return photo;
}

/// `null` si cancela. Si el recorte falla, sigue con la foto completa.
Future<String?> _cropSquare(BuildContext context, String path) async {
  final scheme = Theme.of(context).colorScheme;
  try {
    final cropped = await ImageCropper().cropImage(
      sourcePath: path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      maxWidth: 1600,
      maxHeight: 1600,
      compressQuality: 85,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Encuadra la foto',
          toolbarColor: scheme.primary,
          toolbarWidgetColor: scheme.onPrimary,
          activeControlsWidgetColor: scheme.primary,
          initAspectRatio: CropAspectRatioPreset.square,
          aspectRatioPresets: const [CropAspectRatioPreset.square],
          lockAspectRatio: true,
        ),
        IOSUiSettings(title: 'Encuadra la foto', aspectRatioLockEnabled: true, resetAspectRatioEnabled: false),
      ],
    );
    return cropped?.path;
  } on PlatformException {
    return path;
  } on MissingPluginException {
    return path;
  }
}
