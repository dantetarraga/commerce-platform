import 'dart:typed_data';

import 'package:apamuy/core/errors/app_exception.dart';
import 'package:apamuy/core/errors/failure.dart';
import 'package:apamuy/core/errors/failure_mapper.dart';
import 'package:apamuy/core/result/result.dart';
import 'package:apamuy/features/merchant_catalog/domain/menu.dart';
import 'package:apamuy/features/merchant_catalog/domain/menu_import.dart';
import 'package:apamuy/features/merchant_catalog/infrastructure/datasources/menu_remote_data_source.dart';
import 'package:apamuy/features/merchant_catalog/infrastructure/models/menu_json.dart';
import 'package:apamuy/features/merchant_catalog/infrastructure/spreadsheet_reader.dart';

class MenuRepositoryImpl implements MenuRepository {
  const MenuRepositoryImpl(this._remote);

  final MenuRemoteDataSource _remote;

  @override
  Future<Result<StoreMenu>> menu(String storeId) => guard(() async => MenuJson.menu(await _remote.store(storeId)));

  @override
  Future<Result<void>> createProduct(String storeId, ProductDraft draft, {required String currency}) =>
      guard(() => _remote.createProduct(storeId, MenuJson.draft(draft, currency: currency)));

  @override
  Future<Result<void>> updateProduct(String productId, ProductDraft draft, {required String currency}) =>
      guard(() => _remote.updateProduct(productId, MenuJson.draft(draft, currency: currency)));

  @override
  Future<Result<void>> removeProduct(String productId) => guard(() => _remote.removeProduct(productId));

  @override
  Future<Result<MenuSection>> createSection(String storeId, String name) => guard(() async {
    final json = await _remote.createSection(storeId, name);
    return MenuSection(id: json['id'] as String, name: json['name'] as String);
  });

  @override
  Future<Result<void>> renameSection(String sectionId, String name) =>
      guard(() => _remote.renameSection(sectionId, name));

  @override
  Future<Result<void>> removeSection(String sectionId) => guard(() => _remote.removeSection(sectionId));

  @override
  Future<Result<void>> reorderSections(String storeId, List<String> sectionIds) =>
      guard(() => _remote.reorderSections(storeId, sectionIds));

  @override
  Future<Result<void>> setPhoto(String productId, String imageUrl) =>
      guard(() => _remote.updateProduct(productId, {'imageUrl': imageUrl}));

  @override
  Future<Result<void>> applyToProducts(List<String> productIds, BulkChange change) => guard(() async {
    final body = switch (change) {
      SetAvailable(:final available) => {'isAvailable': available},
      MoveToSection(:final sectionId) => {'menuSectionId': sectionId},
    };
    // De a pocos: con datos móviles, 50 PATCH a la vez fallan por tiempo.
    for (var i = 0; i < productIds.length; i += 4) {
      await Future.wait([for (final id in productIds.skip(i).take(4)) _remote.updateProduct(id, body)]);
    }
  });

  @override
  Future<Result<String>> uploadPhoto(String storeId, PickedPhoto photo, {void Function(double)? onProgress}) async {
    try {
      return Result.ok(await _remote.uploadImage(storeId, photo.path, photo.contentType, onProgress: onProgress));
    } on ApiException catch (e) {
      // Es un 503: sin esto quedaría como "algo salió mal de nuestro lado".
      if (e.code == 'STORAGE_NOT_CONFIGURED') {
        return const Result.err(BusinessFailure('STORAGE_NOT_CONFIGURED', 'La subida de fotos aún no está activada.'));
      }
      return Result.err(mapExceptionToFailure(e));
    } on AppException catch (e) {
      return Result.err(mapExceptionToFailure(e));
    } on Exception {
      return const Result.err(BusinessFailure('PHOTO_UNREADABLE', 'No pudimos leer la foto. Elige otra.'));
    }
  }

  @override
  Future<Result<SheetParse>> readImportFile(Uint8List bytes, String fileName) async {
    try {
      return Result.ok(sheetToRows(readSpreadsheet(bytes, fileName)));
    } on Object {
      return const Result.err(
        BusinessFailure(
          'FILE_UNREADABLE',
          'No pudimos leer el archivo. Guárdalo como .xlsx o .csv y vuelve a intentarlo.',
        ),
      );
    }
  }

  @override
  Future<Result<ImportResult>> importProducts(String storeId, List<ImportRow> rows, {required bool dryRun}) => guard(
    () async => MenuJson.importResult(
      await _remote.importProducts(storeId, [for (final r in rows) r.toJson()], dryRun: dryRun),
    ),
  );
}
