import 'package:chaski/core/maps/delivery_location.dart';
import 'package:chaski/core/result/result.dart';
import 'package:chaski/features/cart/cart.dart';
import 'package:chaski/features/discovery/domain/search.dart';
import 'package:chaski/features/stores/presentation/providers/stores_providers.dart';
import 'package:chaski/features/stores/stores.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "+" rápido fuera del negocio (inicio, Explorar). Sin [known] carga el negocio
/// para saber si se puede pedir; todo error es un aviso. `true` si quedó en la bolsa.
Future<bool> quickAddProduct(BuildContext context, WidgetRef ref, ProductHit product, {StoreSummary? known}) async {
  var store = known;
  if (store == null) {
    final near = ref.read(currentDeliveryLocationProvider).coordinates;
    final result = await ref.read(storesRepositoryProvider).getStoreDetail(product.storeId, near: near);
    if (!context.mounted) return false;
    switch (result) {
      case Ok(:final value):
        store = value.summary;
      case Err(:final failure):
        AppToast.show(context, AppInlineNotice.messageFor(failure), kind: AppToastKind.error);
        return false;
    }
  }
  if (!store.canOrder) {
    AppToast.show(context, cannotOrderMessage(store));
    return false;
  }
  return addToCart(
    context,
    ref,
    line: quickCartLine(productId: product.id, name: product.name, price: product.price, imageUrl: product.imageUrl),
    store: store.toCartStore(),
  );
}
