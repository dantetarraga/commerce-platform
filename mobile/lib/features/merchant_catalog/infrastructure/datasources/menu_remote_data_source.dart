import 'dart:io';

import 'package:apamuy/core/network/api_client.dart';
import 'package:apamuy/features/merchant_catalog/infrastructure/datasources/fake_merchant_menu.dart';
import 'package:dio/dio.dart';

/// Fuente remota de la carta editable (`merchant/catalog/*`) y de la subida de
/// fotos (`uploads/images`). JSON crudo, el mismo que usa el Portal Socios web.
abstract interface class MenuRemoteDataSource {
  Future<Map<String, dynamic>> store(String storeId);

  Future<void> createProduct(String storeId, Map<String, Object?> body);

  Future<void> updateProduct(String productId, Map<String, Object?> body);

  Future<void> removeProduct(String productId);

  Future<Map<String, dynamic>> createSection(String storeId, String name);

  Future<void> renameSection(String sectionId, String name);

  Future<void> removeSection(String sectionId);

  Future<void> reorderSections(String storeId, List<String> sectionIds);

  /// Sube el archivo y devuelve la URL pública.
  Future<String> uploadImage(String storeId, String path, String contentType, {void Function(double)? onProgress});

  Future<Map<String, dynamic>> importProducts(String storeId, List<Map<String, Object>> rows, {required bool dryRun});
}

class ApiMenuRemoteDataSource implements MenuRemoteDataSource {
  ApiMenuRemoteDataSource(this._api, {Dio? storage}) : _storage = storage ?? Dio();

  final ApiClient _api;

  /// Sin interceptores: el storage recibe la URL firmada, nunca el token de Apamuy.
  final Dio _storage;

  static Map<String, dynamic> _map(Object? data) => data! as Map<String, dynamic>;

  @override
  Future<Map<String, dynamic>> store(String storeId) async => _map(await _api.get('/merchant/catalog/stores/$storeId'));

  @override
  Future<void> createProduct(String storeId, Map<String, Object?> body) =>
      _api.post('/merchant/catalog/stores/$storeId/products', body: body);

  @override
  Future<void> updateProduct(String productId, Map<String, Object?> body) =>
      _api.patch('/merchant/catalog/products/$productId', body: body);

  @override
  Future<void> removeProduct(String productId) => _api.delete('/merchant/catalog/products/$productId');

  @override
  Future<Map<String, dynamic>> createSection(String storeId, String name) async =>
      _map(await _api.post('/merchant/catalog/stores/$storeId/sections', body: {'name': name}));

  @override
  Future<void> renameSection(String sectionId, String name) =>
      _api.patch('/merchant/catalog/sections/$sectionId', body: {'name': name});

  @override
  Future<void> removeSection(String sectionId) => _api.delete('/merchant/catalog/sections/$sectionId');

  @override
  Future<void> reorderSections(String storeId, List<String> sectionIds) =>
      _api.put('/merchant/catalog/stores/$storeId/sections/order', body: {'sectionIds': sectionIds});

  @override
  Future<String> uploadImage(
    String storeId,
    String path,
    String contentType, {
    void Function(double)? onProgress,
  }) async {
    final file = File(path);
    final size = await file.length();
    final signed = _map(
      await _api.post(
        '/uploads/images',
        body: {'purpose': 'product', 'storeId': storeId, 'contentType': contentType, 'size': size},
      ),
    );
    try {
      await _storage.put<void>(
        signed['uploadUrl'] as String,
        data: file.openRead(),
        options: Options(
          headers: {...(signed['headers'] as Map).cast<String, Object>(), Headers.contentLengthHeader: size},
          sendTimeout: const Duration(minutes: 2),
        ),
        onSendProgress: onProgress == null ? null : (sent, total) => onProgress(total <= 0 ? 0 : sent / total),
      );
    } on DioException catch (e) {
      throw convertDioException(e);
    }
    return signed['publicUrl'] as String;
  }

  @override
  Future<Map<String, dynamic>> importProducts(
    String storeId,
    List<Map<String, Object>> rows, {
    required bool dryRun,
  }) async => _map(
    await _api.post('/merchant/catalog/stores/$storeId/products/import', body: {'rows': rows, 'dryRun': dryRun}),
  );
}

/// Modo demo: la carta vive en [FakeMerchantMenu], la misma que lee la lista de productos.
class FakeMenuRemoteDataSource implements MenuRemoteDataSource {
  const FakeMenuRemoteDataSource(this._fake);

  final FakeMerchantMenu _fake;

  @override
  Future<Map<String, dynamic>> store(String storeId) => _fake.store(storeId);

  @override
  Future<void> createProduct(String storeId, Map<String, Object?> body) => _fake.createProduct(storeId, body);

  @override
  Future<void> updateProduct(String productId, Map<String, Object?> body) => _fake.updateProduct(productId, body);

  @override
  Future<void> removeProduct(String productId) => _fake.removeProduct(productId);

  @override
  Future<Map<String, dynamic>> createSection(String storeId, String name) => _fake.createSection(storeId, name);

  @override
  Future<void> renameSection(String sectionId, String name) => _fake.renameSection(sectionId, name);

  @override
  Future<void> removeSection(String sectionId) => _fake.removeSection(sectionId);

  @override
  Future<void> reorderSections(String storeId, List<String> sectionIds) => _fake.reorderSections(storeId, sectionIds);

  /// En la demo la foto se queda en el teléfono.
  @override
  Future<String> uploadImage(
    String storeId,
    String path,
    String contentType, {
    void Function(double)? onProgress,
  }) async {
    onProgress?.call(1);
    return path;
  }

  @override
  Future<Map<String, dynamic>> importProducts(
    String storeId,
    List<Map<String, Object>> rows, {
    required bool dryRun,
  }) => _fake.importProducts(storeId, rows, dryRun: dryRun);
}
