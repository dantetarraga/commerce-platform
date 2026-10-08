import 'package:apamuy/features/stores/domain/entities/store_summary.dart';
import 'package:equatable/equatable.dart';

/// Una página de `GET /stores` con los filtros ya aplicados por el backend.
final class StorePage extends Equatable {
  const StorePage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    this.openCount = 0,
  });

  final List<StoreSummary> items;
  final int page;
  final int limit;
  final int total;

  /// Abiertos ahora que llegan a la ubicación, sin contar los filtros.
  final int openCount;

  bool get hasMore => page * limit < total;
  bool get isEmpty => items.isEmpty;

  @override
  List<Object?> get props => [items, page, limit, total, openCount];
}
