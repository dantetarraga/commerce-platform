import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Reglas de dependencias de `lib/` (ver `mobile/CLAUDE.md`). Lee las directivas
/// `import`/`export` de cada archivo; no compila nada.
void main() {
  final sources = _readLib();

  test('core y shared no importan features ni apps', () {
    expect(
      _violations(sources, (from, to) {
        final layer = from.split('/').first;
        return (layer == 'core' || layer == 'shared') && (to.startsWith('features/') || to.startsWith('apps/'));
      }),
      isEmpty,
    );
  });

  test('ningún feature importa apps', () {
    expect(
      _violations(
        sources,
        (from, to) => from.startsWith('features/') && to.startsWith('apps/'),
      ),
      isEmpty,
    );
  });

  test(
    'entre features solo se importan sus barrels; desde domain, solo <feature>_domain.dart',
    () {
      expect(
        _violations(sources, (from, to) {
          final source = _feature(from);
          final target = _feature(to);
          if (source == null || target == null || source == target) return false;
          final file = to.split('/').skip(2).join('/');
          if (_isDomain(from)) return file != '${target}_domain.dart';
          return !RegExp('^$target(_[a-z]+)?\\.dart\$').hasMatch(file);
        }),
        isEmpty,
      );
    },
  );

  test('domain es Dart puro', () {
    const forbidden = [
      'package:flutter/',
      'package:dio/',
      'package:json_annotation/',
      'package:flutter_riverpod/',
    ];
    expect(
      _violations(sources, (from, to) {
        if (!_isDomain(from)) return false;
        return forbidden.any(to.startsWith) ||
            RegExp(
              '^features/[a-z_]+/(presentation|infrastructure)/',
            ).hasMatch(to);
      }),
      isEmpty,
    );
  });

  test('no hay ciclos entre features', () {
    final graph = <String, Set<String>>{};
    for (final MapEntry(key: from, value: targets) in sources.entries) {
      final source = _feature(from);
      if (source == null) continue;
      for (final target in targets.map(_feature).nonNulls) {
        if (target != source) (graph[source] ??= {}).add(target);
      }
    }
    final cyclic = [
      for (final feature in graph.keys)
        if (_reachable(graph, feature).contains(feature)) feature,
    ];
    expect(cyclic, isEmpty);
  });

  test('cada app solo alcanza sus features y las comunes', () {
    const partnerOnly = {
      'partner_session',
      'merchant_orders',
      'courier_deliveries',
    };
    const shared = {'auth', 'orders'};
    final customer = _reachable(
      sources,
      'main.dart',
    ).map(_feature).nonNulls.toSet();
    final partner = _reachable(
      sources,
      'main_partner.dart',
    ).map(_feature).nonNulls.toSet();
    expect(
      customer.intersection(partnerOnly),
      isEmpty,
      reason: 'el cliente alcanza features de Socios',
    );
    expect(
      partner.difference({...partnerOnly, ...shared}),
      isEmpty,
      reason: 'Socios alcanza features del cliente',
    );
  });
}

/// `lib/`-relativo → destinos de sus directivas (rutas `lib/`-relativas o URIs de otros paquetes).
Map<String, List<String>> _readLib() {
  final directive = RegExp(r"^(?:import|export)\s+'([^']+)'", multiLine: true);
  final lib = Directory('lib');
  return {
    for (final file in lib.listSync(recursive: true).whereType<File>())
      if (file.path.endsWith('.dart') && !file.path.endsWith('.g.dart'))
        _relative(file.path): [
          for (final match in directive.allMatches(file.readAsStringSync()))
            _resolve(_relative(file.path), match.group(1)!),
        ],
  };
}

String _relative(String path) => path.replaceAll(r'\', '/').replaceFirst(RegExp('^lib/'), '');

String _resolve(String from, String uri) {
  if (uri.startsWith('package:apamuy/')) return uri.substring('package:apamuy/'.length);
  if (uri.startsWith('package:') || uri.startsWith('dart:')) return uri;
  return Uri.parse(from).resolve(uri).path;
}

String? _feature(String path) {
  final parts = path.split('/');
  return parts.length > 2 && parts.first == 'features' ? parts[1] : null;
}

bool _isDomain(String path) => RegExp('^features/[a-z_]+/domain/').hasMatch(path);

List<String> _violations(
  Map<String, List<String>> sources,
  bool Function(String from, String to) broken,
) => [
  for (final MapEntry(key: from, value: targets) in sources.entries)
    for (final to in targets)
      if (broken(from, to)) '$from -> $to',
];

Set<String> _reachable(Map<String, Iterable<String>> graph, String start) {
  final seen = <String>{};
  final pending = [...?graph[start]];
  while (pending.isNotEmpty) {
    final next = pending.removeLast();
    if (seen.add(next)) pending.addAll(graph[next] ?? const []);
  }
  return seen;
}
