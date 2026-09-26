import 'package:chaski/features/partner_session/partner_session.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Inicio del modo Negocio: los pedidos del día.
class MerchantHomePage extends StatelessWidget {
  const MerchantHomePage({super.key});

  static const name = 'merchantHome';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tu negocio'), actions: const [PartnerAccountButton()]),
      body: const AppEmptyState(
        title: 'Aquí llegarán tus pedidos',
        message: 'Cuando un cliente te pida, sonará una alarma y lo verás en esta pantalla.',
      ),
    );
  }
}
