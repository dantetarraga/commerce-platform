import 'package:chaski/core/domain/page_result.dart';
import 'package:chaski/core/result/result.dart';
import 'package:chaski/features/stores/domain/entities/category.dart';
import 'package:chaski/features/stores/domain/entities/store_detail.dart';
import 'package:chaski/features/stores/domain/entities/store_menu.dart';
import 'package:chaski/features/stores/domain/entities/store_query.dart';
import 'package:chaski/features/stores/domain/entities/store_summary.dart';
import 'package:chaski/features/stores/domain/repositories/stores_repository.dart';

class GetCategories {
  const GetCategories(this._repository);
  final StoresRepository _repository;

  Future<Result<List<Category>>> call() => _repository.getCategories();
}

class GetStores {
  const GetStores(this._repository);
  final StoresRepository _repository;

  /// Los abiertos primero, sin alterar el orden pedido dentro de cada grupo.
  Future<Result<PageResult<StoreSummary>>> call(StoreQuery query) async {
    final result = await _repository.getStores(query);
    return result.map(
      (page) => PageResult(
        items: [...page.items.where((s) => s.isOpenNow), ...page.items.where((s) => !s.isOpenNow)],
        page: page.page,
        limit: page.limit,
        total: page.total,
      ),
    );
  }
}

class GetStoreDetail {
  const GetStoreDetail(this._repository);
  final StoresRepository _repository;

  Future<Result<StoreDetail>> call(String storeId) => _repository.getStoreDetail(storeId);
}

class GetStoreMenu {
  const GetStoreMenu(this._repository);
  final StoresRepository _repository;

  Future<Result<StoreMenu>> call(String storeId) => _repository.getStoreMenu(storeId);
}
