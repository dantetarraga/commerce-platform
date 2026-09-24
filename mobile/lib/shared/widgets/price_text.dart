import 'package:chaski/core/domain/money.dart';
import 'package:chaski/core/utils/formatters.dart';
import 'package:flutter/material.dart';

class PriceText extends StatelessWidget {
  const PriceText(this.money, {this.style, this.prefix = '', super.key});

  final Money money;
  final TextStyle? style;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.titleSmall;
    return Text('$prefix${Formatters.money(money)}', style: base);
  }
}
