import 'package:chaski/app/posta/posta_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Tres destinos (Cerca · Explorar · Tú) y la posta flotando encima.
///
/// No hay pestaña de Pedidos: el pedido en curso vive en la posta, visible en
/// toda la app; el historial está dentro de "Tú".
class ScaffoldWithNav extends StatelessWidget {
  const ScaffoldWithNav({required this.shell, super.key});

  final StatefulNavigationShell shell;

  void _select(int index) {
    // Tocar la pestaña activa vuelve a su pantalla inicial.
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PostaBar(),
          NavigationBar(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: _select,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.near_me_outlined),
                selectedIcon: Icon(Icons.near_me_rounded),
                label: 'Cerca',
                tooltip: 'Cerca: lo que hay a tu alrededor',
              ),
              NavigationDestination(
                icon: Icon(Icons.travel_explore_rounded),
                selectedIcon: Icon(Icons.manage_search_rounded),
                label: 'Explorar',
                tooltip: 'Explorar: busca negocios y productos',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Tú',
                tooltip: 'Tú: pedidos, direcciones y ajustes',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
