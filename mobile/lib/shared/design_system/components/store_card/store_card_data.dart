import 'package:apamuy/core/domain/money.dart';
import 'package:apamuy/core/utils/formatters.dart';
import 'package:flutter/foundation.dart';

/// Datos que una card de negocio necesita. El design system no conoce las
/// entidades de los features: cada feature arma este objeto.
@immutable
class StoreCardData {
  const StoreCardData({
    required this.id,
    required this.name,
    required this.etaMinutes,
    required this.deliveryFee,
    required this.isOpen,
    this.coverUrl,
    this.logoUrl,
    this.distanceKm,
    this.rating,
    this.promo,
    this.closedLabel,
    this.subtitle,
    this.minOrder,
  });

  final String id;
  final String name;
  final String? coverUrl;
  final String? logoUrl;
  final int etaMinutes;
  final Money deliveryFee;
  final bool isOpen;
  final double? distanceKm;
  final double? rating;

  /// Texto de la cinta de oferta ("−15 % en caldos hoy").
  final String? promo;

  /// Cuando está cerrado: "Abre mañana 7:00".
  final String? closedLabel;

  /// Una línea de contexto opcional ("Caldos · Sopas").
  final String? subtitle;

  /// Pedido mínimo del negocio (null o cero = sin mínimo).
  final Money? minOrder;

  String get minOrderLabel => minOrder == null || minOrder!.isZero ? 'Sin mínimo' : 'Pedido mín. ${Formatters.money(minOrder!)}';

  /// "20–30 min · Envío S/ 3.00" — lo único necesario para decidir.
  String get meta {
    final fee = deliveryFee.isZero ? 'Envío gratis' : 'Envío ${Formatters.money(deliveryFee)}';
    return '${Formatters.eta(etaMinutes)} · $fee';
  }
}
