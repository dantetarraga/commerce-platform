import 'package:apamuy/core/maps/delivery_location.dart';
import 'package:apamuy/core/result/result.dart';
import 'package:apamuy/features/cart/cart.dart';
import 'package:apamuy/features/discovery/domain/search.dart';
import 'package:apamuy/features/stores/stores.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "+" rápido fuera del negocio (inicio, Explorar). Sin [known] carga el negocio
/// para saber si se puede pedir; todo error es un aviso. `true` si quedó en la bolsa.
Future<bool> quickAddProduct(BuildContext context, WidgetRef ref, ProductHit product, {StoreSummary? known}) async {
  var store = known;
  if (store == null) {
    final near = ref.read(currentDeliveryLocationProvider).coordinates;
    final result = await ref.read(getStoreDetailProvider).call(product.storeId, near: near);
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
