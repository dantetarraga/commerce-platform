import 'package:flutter/material.dart';

/// Pide el nombre de una sección ("Bebidas"). Devuelve `null` si se cancela.
Future<String?> showSectionNameDialog(BuildContext context, {required String title, String initial = ''}) =>
    showDialog<String>(
      context: context,
      builder: (_) => _SectionNameDialog(title: title, initial: initial),
    );

class _SectionNameDialog extends StatefulWidget {
  const _SectionNameDialog({required this.title, required this.initial});

  final String title;
  final String initial;

  @override
  State<_SectionNameDialog> createState() => _SectionNameDialogState();
}

class _SectionNameDialogState extends State<_SectionNameDialog> {
  late final _controller = TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty || name.length > 60) {
      setState(() => _error = 'Escribe un nombre de hasta 60 caracteres.');
      return;
    }
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 60,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: 'Por ejemplo, Bebidas', errorText: _error),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _submit, child: const Text('Guardar')),
      ],
    );
  }
}
