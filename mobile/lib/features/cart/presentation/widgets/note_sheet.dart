import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Hoja de texto corto (nota del negocio, de un producto, de ayuda…).
/// Devuelve el texto sin espacios de borde, o null si se cierra sin guardar.
Future<String?> showNoteSheet(
  BuildContext context, {
  required String title,
  required String label,
  String initial = '',
  String? hint,
  String saveLabel = 'Guardar nota',
  int maxLength = 140,
}) async {
  final notes = await showAppBottomSheet<String>(
    context,
    title: title,
    builder: (_) => NoteSheet(label: label, initial: initial, hint: hint, saveLabel: saveLabel, maxLength: maxLength),
  );
  return notes?.trim();
}

/// Contenido de [showNoteSheet]. Posee su controller: se libera cuando la
/// hoja termina de cerrarse, no antes.
class NoteSheet extends StatefulWidget {
  const NoteSheet({required this.label, this.initial = '', this.hint, this.saveLabel = 'Guardar nota', this.maxLength = 140, super.key});

  final String label;
  final String initial;
  final String? hint;
  final String saveLabel;
  final int maxLength;

  @override
  State<NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<NoteSheet> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppInput(
            label: widget.label,
            controller: _controller,
            variant: AppInputVariant.note,
            maxLength: widget.maxLength,
            autofocus: true,
            hint: widget.hint,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(label: widget.saveLabel, onPressed: () => Navigator.of(context).pop(_controller.text)),
        ],
      ),
    );
  }
}
