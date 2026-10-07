import 'package:chaski/features/stores/stores.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Abre el detalle de un negocio desde el inicio (con su portada si ya se conoce).
void openStore(BuildContext context, String storeId, {String? coverUrl, Object? heroTag}) => context
    .pushNamed(StoreDetailPage.name, pathParameters: {'storeId': storeId}, extra: StoreRouteArgs(coverUrl: coverUrl, heroTag: heroTag))
    .ignore();
