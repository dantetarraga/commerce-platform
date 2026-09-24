import 'package:chaski/app/posta/posta_provider.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// La posta conectada al estado de la app (bolsa / pedido en curso).
/// Se coloca sobre la barra de navegación y en las pantallas de detalle.
class PostaBar extends ConsumerWidget {
  const PostaBar({this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.sm), super.key});

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posta = ref.watch(postaProvider);
    return Padding(
      padding: padding,
      child: AppPosta(
        state: posta.state,
        pulse: posta.pulse,
        onTap: () => ref.read(postaProvider.notifier).open(context),
      ),
    );
  }
}
