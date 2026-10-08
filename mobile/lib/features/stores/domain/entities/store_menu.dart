import 'package:apamuy/core/domain/money.dart';
import 'package:equatable/equatable.dart';

/// Producto tal como aparece en el menú de un negocio. El detalle completo
/// (variantes y opciones) vive en el feature `products`.
final class MenuItem extends Equatable {
  const MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.isAvailable,
    required this.hasChoices,
    this.description,
    this.imageUrl,
    this.isFeatured = false,
  });

  final String id;
  final String name;
  final String? description;
  final String? imageUrl;

  /// Precio "desde": el de la variante más barata disponible, si tiene variantes.
  final Money price;
  final bool isAvailable;

  final bool hasChoices;

  /// "Lo más pedido" del negocio.
  final bool isFeatured;

  @override
  List<Object?> get props => [id, name, description, imageUrl, price, isAvailable, hasChoices, isFeatured];
}

final class MenuSection extends Equatable {
  const MenuSection({required this.id, required this.name, required this.items});

  final String id;
  final String name;
  final List<MenuItem> items;

  @override
  List<Object?> get props => [id, name, items];
}

final class StoreMenu extends Equatable {
  const StoreMenu(this.sections);

  final List<MenuSection> sections;

  List<MenuSection> get visibleSections => sections.where((s) => s.items.isNotEmpty).toList();

  bool get isEmpty => visibleSections.isEmpty;

  /// Destacados disponibles de todas las secciones (sin repetir).
  List<MenuItem> get featured {
    final seen = <String>{};
    return [
      for (final section in visibleSections)
        for (final item in section.items)
          if (item.isFeatured && item.isAvailable && seen.add(item.id)) item,
    ];
  }

  @override
  List<Object?> get props => [sections];
}
