import 'package:apamuy/core/result/result.dart';
import 'package:equatable/equatable.dart';

final class Promotion extends Equatable {
  const Promotion({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.subtitle,
    this.storeId,
    this.couponCode,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String imageUrl;

  /// Si apunta a un negocio, al tocar el banner se abre su detalle.
  final String? storeId;
  final String? couponCode;

  @override
  List<Object?> get props => [id, title, subtitle, imageUrl, storeId, couponCode];
}

abstract interface class PromotionsRepository {
  Future<Result<List<Promotion>>> getActivePromotions();
}
