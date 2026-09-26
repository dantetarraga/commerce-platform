import 'package:chaski/features/partner_session/partner_session.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Inicio del modo Repartidor: conectarse y tomar pedidos.
class CourierHomePage extends StatelessWidget {
  const CourierHomePage({super.key});

  static const name = 'courierHome';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reparto'), actions: const [PartnerAccountButton()]),
      body: const AppEmptyState(
        title: 'Aquí verás los pedidos listos',
        message: 'Conéctate para recibir pedidos de los negocios de tu ciudad.',
      ),
    );
  }
}
