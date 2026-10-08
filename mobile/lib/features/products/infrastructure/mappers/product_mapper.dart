import 'package:apamuy/features/products/domain/entities/product.dart';
import 'package:apamuy/features/products/infrastructure/models/product_dtos.dart';

extension ProductDetailDtoMapper on ProductDetailDto {
  Product toDomain() => Product(
    id: id,
    storeId: storeId,
    storeName: storeName,
    store: switch (store) {
      null => null,
      final s => ProductStore(
        logoUrl: s.logoUrl,
        deliveryFee: s.deliveryFee.toDomain(),
        minOrderAmount: s.minOrderAmount.toDomain(),
        etaMinutes: s.etaMinutes,
        isOpenNow: s.isOpenNow,
      ),
    },
    name: name,
    description: description,
    imageUrl: imageUrl,
    basePrice: basePrice.toDomain(),
    isAvailable: isAvailable,
    variants: [
      for (final v in variants)
        ProductVariant(id: v.id, name: v.name, price: v.price.toDomain(), isAvailable: v.isAvailable),
    ],
    options: [
      for (final o in options)
        ProductOption(
          id: o.id,
          name: o.name,
          minSelect: o.minSelect,
          maxSelect: o.maxSelect,
          values: [
            for (final value in o.values)
              OptionValue(
                id: value.id,
                name: value.name,
                priceDelta: value.priceDelta.toDomain(),
                isAvailable: value.isAvailable,
              ),
          ],
        ),
    ],
  );
}
