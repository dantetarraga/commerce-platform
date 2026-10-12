import 'dart:typed_data';

import 'package:apamuy/core/config/app_config_provider.dart';
import 'package:apamuy/core/errors/failure.dart';
import 'package:apamuy/core/fake/fake_providers.dart';
import 'package:apamuy/core/network/network_providers.dart';
import 'package:apamuy/core/result/result.dart';
import 'package:apamuy/core/utils/text_utils.dart';
import 'package:apamuy/features/merchant_catalog/domain/menu.dart';
import 'package:apamuy/features/merchant_catalog/domain/menu_import.dart';
import 'package:apamuy/features/merchant_catalog/infrastructure/datasources/fake_merchant_menu.dart';
import 'package:apamuy/features/merchant_catalog/infrastructure/datasources/menu_remote_data_source.dart';
import 'package:apamuy/features/merchant_catalog/infrastructure/menu_repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'menu_providers.g.dart';

@Riverpod(keepAlive: true)
FakeMerchantMenu fakeMerchantMenu(Ref ref) => FakeMerchantMenu(ref.watch(fakeBackendProvider));

@Riverpod(keepAlive: true)
MenuRemoteDataSource menuRemoteDataSource(Ref ref) => ref.watch(appEnvProvider).useFakeData
    ? FakeMenuRemoteDataSource(ref.watch(fakeMerchantMenuProvider))
    : ApiMenuRemoteDataSource(ref.watch(apiClientProvider));

@Riverpod(keepAlive: true)
MenuRepository menuRepository(Ref ref) => MenuRepositoryImpl(ref.watch(menuRemoteDataSourceProvider));

/// Sube con cada cambio de la carta. La lista de productos de Socios la
/// escucha para volver a pedirse sin depender de este feature.
@Riverpod(keepAlive: true)
class MenuRevision extends _$MenuRevision {
  @override
  int build() => 0;

  void bump() => state++;
}

/// Lo que entró con la última importación, por nombre (como lo reconoce el
/// backend): la lista lo resalta hasta que el dueño lo da por visto.
@Riverpod(keepAlive: true)
class ImportHighlights extends _$ImportHighlights {
  @override
  Map<String, ImportAction> build() => const {};

  void set(Iterable<ImportRowResult> rows) => state = {
    for (final r in rows)
      if (r.action == ImportAction.create || r.action == ImportAction.update) normalizeForSearch(r.name): r.action,
  };

  void clear() => state = const {};

  ImportAction? of(String productName) => state[normalizeForSearch(productName)];
}

/// La carta editable de un negocio, con sus secciones.
@riverpod
Future<StoreMenu> storeMenu(Ref ref, String storeId) {
  ref.watch(menuRevisionProvider);
  return ref.watch(menuRepositoryProvider).menu(storeId).then((r) => r.getOrThrow());
}

/// Cambios a la carta. Cada uno devuelve la falla (o `null`) y, si salió bien,
/// refresca la carta y la lista de productos.
// keepAlive: si se liberara a mitad de una acción, se perdería el refresco.
@Riverpod(keepAlive: true)
class MenuActions extends _$MenuActions {
  @override
  void build() {}

  MenuRepository get _repo => ref.read(menuRepositoryProvider);

  /// Si hay [photo], primero la sube y guarda su URL en el producto.
  Future<Failure?> saveProduct({
    required StoreMenu menu,
    required ProductDraft draft,
    String? productId,
    PickedPhoto? photo,
    void Function(double)? onProgress,
  }) async {
    var toSave = draft;
    if (photo != null) {
      switch (await _repo.uploadPhoto(menu.storeId, photo, onProgress: onProgress)) {
        case Ok(:final value):
          toSave = draft.copyWith(imageUrl: () => value);
        case Err(:final failure):
          return failure;
      }
    }
    return _done(
      productId == null
          ? await _repo.createProduct(menu.storeId, toSave, currency: menu.currency)
          : await _repo.updateProduct(productId, toSave, currency: menu.currency),
    );
  }

  Future<Failure?> removeProduct(String productId) async => _done(await _repo.removeProduct(productId));

  Future<Result<MenuSection>> createSection(String storeId, String name) async {
    final result = await _repo.createSection(storeId, name.trim());
    _done(result);
    return result;
  }

  Future<Failure?> renameSection(String sectionId, String name) async =>
      _done(await _repo.renameSection(sectionId, name.trim()));

  Future<Failure?> removeSection(String sectionId) async => _done(await _repo.removeSection(sectionId));

  Future<Failure?> reorderSections(String storeId, List<String> sectionIds) async =>
      _done(await _repo.reorderSections(storeId, sectionIds));

  /// Sube la foto y la pone en el producto, sin tocar lo demás.
  Future<Failure?> setPhoto(
    String storeId,
    String productId,
    PickedPhoto photo, {
    void Function(double)? onProgress,
  }) async => switch (await _repo.uploadPhoto(storeId, photo, onProgress: onProgress)) {
    Ok(:final value) => _done(await _repo.setPhoto(productId, value)),
    Err(:final failure) => failure,
  };

  Future<Failure?> applyToProducts(List<String> productIds, BulkChange change) async =>
      _done(await _repo.applyToProducts(productIds, change));

  Future<Result<SheetParse>> readImportFile(Uint8List bytes, String fileName) => _repo.readImportFile(bytes, fileName);

  /// Con [dryRun] solo revisa: la carta no cambia.
  Future<Result<ImportResult>> importProducts(String storeId, List<ImportRow> rows, {required bool dryRun}) async {
    final result = await _repo.importProducts(storeId, rows, dryRun: dryRun);
    if (!dryRun) _done(result);
    return result;
  }

  Failure? _done<T>(Result<T> result) {
    if (ref.mounted && result.isOk) ref.read(menuRevisionProvider.notifier).bump();
    return switch (result) {
      Ok() => null,
      Err(:final failure) => failure,
    };
  }
}
