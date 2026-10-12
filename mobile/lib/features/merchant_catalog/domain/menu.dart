import 'dart:typed_data';

import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/core/result/result.dart';
import 'package:apamuy/features/merchant_catalog/domain/menu_import.dart';
import 'package:equatable/equatable.dart';

final class MenuSection extends Equatable {
  const MenuSection({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

/// Un producto de la carta con todo lo que el dueño puede editar.
final class MenuProduct extends Equatable {
  const MenuProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.isAvailable,
    this.description,
    this.imageUrl,
    this.sectionId,
    this.stock,
    this.variantCount = 0,
  });

  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final Money price;
  final String? sectionId;

  /// `null`: no se controla stock.
  final int? stock;
  final bool isAvailable;

  /// Con variantes, el cliente paga el precio de la variante ("1/4", "1/2"):
  /// el precio base no se edita desde aquí.
  final int variantCount;

  bool get hasVariants => variantCount > 0;

  @override
  List<Object?> get props => [id, name, description, imageUrl, price, sectionId, stock, isAvailable, variantCount];
}

/// La carta editable de un negocio (`GET /merchant/catalog/stores/:id`).
final class StoreMenu extends Equatable {
  const StoreMenu({
    required this.storeId,
    required this.storeName,
    required this.currency,
    required this.sections,
    required this.products,
  });

  final String storeId;
  final String storeName;
  final String currency;
  final List<MenuSection> sections;
  final List<MenuProduct> products;

  MenuProduct? product(String id) => products.where((p) => p.id == id).firstOrNull;

  int productsIn(String sectionId) => products.where((p) => p.sectionId == sectionId).length;

  @override
  List<Object?> get props => [storeId, storeName, currency, sections, products];
}

/// Lo que se guarda al crear o editar un producto.
final class ProductDraft extends Equatable {
  const ProductDraft({
    required this.name,
    required this.price,
    required this.isAvailable,
    this.description = '',
    this.imageUrl,
    this.sectionId,
    this.stock,
  });

  /// Lo que hoy tiene [product], para cambiar solo una parte.
  factory ProductDraft.fromProduct(MenuProduct product) => ProductDraft(
    name: product.name,
    description: product.description ?? '',
    price: product.hasVariants ? null : product.price,
    imageUrl: product.imageUrl,
    sectionId: product.sectionId,
    stock: product.stock,
    isAvailable: product.isAvailable,
  );

  final String name;
  final String description;

  /// `null` en un producto con variantes: el precio no se toca.
  final Money? price;
  final String? imageUrl;
  final String? sectionId;
  final int? stock;
  final bool isAvailable;

  /// [stock] e [imageUrl] aceptan `null` como valor: se pasan envueltos en una función.
  ProductDraft copyWith({
    Money? price,
    int? Function()? stock,
    String? Function()? imageUrl,
    bool? isAvailable,
  }) => ProductDraft(
    name: name,
    description: description,
    price: price ?? this.price,
    imageUrl: imageUrl == null ? this.imageUrl : imageUrl(),
    sectionId: sectionId,
    stock: stock == null ? this.stock : stock(),
    isAvailable: isAvailable ?? this.isAvailable,
  );

  @override
  List<Object?> get props => [name, description, price, imageUrl, sectionId, stock, isAvailable];
}

/// Un cambio que se aplica a varios productos elegidos de la lista.
sealed class BulkChange extends Equatable {
  const BulkChange();
}

final class SetAvailable extends BulkChange {
  const SetAvailable({required this.available});

  final bool available;

  @override
  List<Object?> get props => [available];
}

/// [sectionId] `null`: quedan sin sección.
final class MoveToSection extends BulkChange {
  const MoveToSection(this.sectionId);

  final String? sectionId;

  @override
  List<Object?> get props => [sectionId];
}

/// Una foto elegida en el teléfono, lista para subir.
final class PickedPhoto extends Equatable {
  const PickedPhoto({required this.path, required this.contentType});

  final String path;

  /// `image/jpeg`, `image/png` o `image/webp`.
  final String contentType;

  static PickedPhoto? fromPath(String path) {
    final type = switch (path.split('.').last.toLowerCase()) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => null,
    };
    return type == null ? null : PickedPhoto(path: path, contentType: type);
  }

  @override
  List<Object?> get props => [path, contentType];
}

abstract interface class MenuRepository {
  Future<Result<StoreMenu>> menu(String storeId);

  Future<Result<void>> createProduct(String storeId, ProductDraft draft, {required String currency});

  Future<Result<void>> updateProduct(String productId, ProductDraft draft, {required String currency});

  Future<Result<void>> removeProduct(String productId);

  Future<Result<MenuSection>> createSection(String storeId, String name);

  Future<Result<void>> renameSection(String sectionId, String name);

  Future<Result<void>> removeSection(String sectionId);

  /// Todas las secciones del negocio, en el orden en que el cliente las ve.
  Future<Result<void>> reorderSections(String storeId, List<String> sectionIds);

  /// Cambia solo la foto de un producto (desde la lista, sin abrirlo).
  Future<Result<void>> setPhoto(String productId, String imageUrl);

  /// Aplica el mismo cambio a cada producto de [productIds].
  Future<Result<void>> applyToProducts(List<String> productIds, BulkChange change);

  /// Sube la foto al storage de Apamuy y devuelve su URL pública. [onProgress]
  /// recibe de 0 a 1.
  Future<Result<String>> uploadPhoto(String storeId, PickedPhoto photo, {void Function(double)? onProgress});

  /// Lee un `.xlsx` o `.csv` y arma las filas a importar.
  Future<Result<SheetParse>> readImportFile(Uint8List bytes, String fileName);

  Future<Result<ImportResult>> importProducts(String storeId, List<ImportRow> rows, {required bool dryRun});
}
