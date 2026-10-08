import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// Textos legales. Se editan en `assets/legal/*.md`; los enlaces `apamuy:<slug>` abren otro de estos textos.
enum LegalDocument {
  terms('terminos', 'Términos y condiciones'),
  privacy('privacidad', 'Política de privacidad');

  const LegalDocument(this.slug, this.title);

  final String slug;
  final String title;

  String get asset => 'assets/legal/$slug.md';

  static LegalDocument? fromSlug(String? slug) => values.where((d) => d.slug == slug).firstOrNull;
}

/// Pantalla de un texto legal; la registran los routers de las dos apps con [name].
class LegalPage extends StatefulWidget {
  const LegalPage({required this.document, super.key});

  static const name = 'legal';
  static const param = 'doc';

  final LegalDocument document;

  static Future<void> open(BuildContext context, LegalDocument document) =>
      context.pushNamed(name, pathParameters: {param: document.slug});

  @override
  State<LegalPage> createState() => _LegalPageState();
}

class _LegalPageState extends State<LegalPage> {
  late final Future<String> _text = rootBundle.loadString(widget.document.asset);

  void _onTapLink(BuildContext context, String? href) {
    if (href == null) return;
    if (href.startsWith('apamuy:')) {
      if (LegalDocument.fromSlug(href.substring('apamuy:'.length)) case final other?) {
        LegalPage.open(context, other).ignore();
      }
      return;
    }
    launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication).ignore();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.document.title)),
      body: FutureBuilder<String>(
        future: _text,
        builder: (context, snapshot) => switch (snapshot) {
          AsyncSnapshot(:final data?) => Markdown(
            data: data,
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, AppSpacing.xxl),
            onTapLink: (_, href, _) => _onTapLink(context, href),
            styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
              h1: theme.textTheme.headlineSmall,
              h2: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              h2Padding: const EdgeInsets.only(top: AppSpacing.md),
              p: theme.textTheme.bodyMedium,
              tableBody: theme.textTheme.bodySmall,
              tableHead: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
              tableBorder: TableBorder.all(color: theme.colorScheme.outlineVariant),
              tableCellsPadding: const EdgeInsets.all(AppSpacing.xs),
              blockquoteDecoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: AppRadius.tile,
              ),
            ),
          ),
          AsyncSnapshot(hasError: true) => const AppEmptyState(
            kind: AppEmptyKind.error,
            title: 'No pudimos abrir este texto',
            message: 'Cierra y vuelve a intentarlo.',
          ),
          _ => const Center(child: AppWaitLoader()),
        },
      ),
    );
  }
}
