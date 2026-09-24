import 'package:equatable/equatable.dart';

/// Página de un listado con paginación por offset.
final class PageResult<T> extends Equatable {
  const PageResult({required this.items, required this.page, required this.limit, required this.total});

  final List<T> items;
  final int page;
  final int limit;
  final int total;

  bool get hasMore => page * limit < total;
  bool get isEmpty => items.isEmpty;

  @override
  List<Object?> get props => [items, page, limit, total];
}
