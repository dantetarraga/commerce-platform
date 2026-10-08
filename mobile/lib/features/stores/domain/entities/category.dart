import 'package:equatable/equatable.dart';

final class Category extends Equatable {
  const Category({required this.id, required this.name, required this.slug, this.iconUrl, this.openStoreCount = 0});

  final String id;
  final String name;
  final String slug;
  final String? iconUrl;

  /// Negocios abiertos ahora que llegan a la ubicación (lo cuenta el backend).
  final int openStoreCount;

  @override
  List<Object?> get props => [id, name, slug, iconUrl, openStoreCount];
}
