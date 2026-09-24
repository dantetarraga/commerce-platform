import 'package:chaski/core/domain/geo_coordinates.dart';
import 'package:chaski/core/maps/delivery_location.dart';
import 'package:chaski/features/addresses/domain/address.dart';
import 'package:chaski/features/addresses/presentation/providers/address_providers.dart';
import 'package:chaski/features/addresses/presentation/widgets/neighborhood_plan.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:chaski/shared/utils/value_failure_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Nueva dirección: se marca moviendo el mapa hasta la puerta.
class AddressFormPage extends ConsumerStatefulWidget {
  const AddressFormPage({super.key});

  static const name = 'address-form';

  @override
  ConsumerState<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends ConsumerState<AddressFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _street = TextEditingController();
  final _reference = TextEditingController();
  final _label = TextEditingController();
  AddressKind _kind = AddressKind.home;
  var _saving = false;
  var _seed = '';

  /// Cuánto se movió el plano (px lógicos) respecto del punto de entrega actual.
  Offset _moved = Offset.zero;

  /// Grados por px del plano esquemático (~1 m por px en Espinar).
  static const _degreesPerPx = 0.00001;

  @override
  void dispose() {
    _street.dispose();
    _reference.dispose();
    _label.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    // Sin geocodificación todavía: se parte del punto de entrega actual y se
    // corre según cuánto se movió el plano (arrastrar a la derecha = ir al oeste).
    final center = ref.read(currentDeliveryLocationProvider).coordinates;
    final address = Address(
      id: 'adr_${DateTime.now().microsecondsSinceEpoch}',
      kind: _kind,
      label: _kind == AddressKind.other ? _label.text.trim() : null,
      street: StreetLine.create(_street.text).valueOrNull!.value,
      reference: _reference.text.trim(),
      coordinates: GeoCoordinates.trusted(
        center.latitude + _moved.dy * _degreesPerPx,
        center.longitude - _moved.dx * _degreesPerPx,
      ),
    );
    await ref.read(addressBookControllerProvider.notifier).save(address);
    if (!mounted) return;
    AppToast.show(context, 'Dirección guardada. Tus pedidos llegarán ahí.', kind: AppToastKind.success);
    context.pop(address);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Con el teclado abierto el mapa se encoge para dejar ver los campos.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    final mapHeight = keyboard ? 120.0 : (MediaQuery.sizeOf(context).height * 0.36).clamp(220.0, 340.0);
    return Scaffold(
      body: Column(
        children: [
          Stack(
            children: [
              NeighborhoodPlan(
                seed: _seed,
                height: mapHeight,
                hint: 'Mueve el mapa hasta tu puerta',
                onMoved: (offset) => _moved = offset,
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: _MapButton(onPressed: () => Navigator.of(context).maybePop()),
                ),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Semantics(header: true, child: Text('Nueva dirección', style: theme.textTheme.titleLarge)),
                          const SizedBox(height: AppSpacing.md),
                          AppInput(
                            label: 'Calle y número',
                            controller: _street,
                            hint: 'Jr. Tacna 214',
                            textCapitalization: TextCapitalization.words,
                            onChanged: (value) {
                              // El plano se acomoda cuando la calle ya se puede leer.
                              if (value.trim().length >= StreetLine.minLength) setState(() => _seed = value);
                            },
                            validator: (v) => StreetLine.create(v ?? '').failureOrNull?.message,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppInput(
                            label: 'Referencia para el repartidor',
                            controller: _reference,
                            variant: AppInputVariant.note,
                            maxLength: 140,
                            hint: 'Puerta verde, 2.º piso',
                            helper: 'Aquí las referencias valen más que el número.',
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: [
                              for (final (kind, label, icon) in const [
                                (AddressKind.home, 'Casa', Icons.home_rounded),
                                (AddressKind.work, 'Trabajo', Icons.work_rounded),
                                (AddressKind.other, 'Otro', Icons.place_rounded),
                              ])
                                AppChip(
                                  label: label,
                                  icon: icon,
                                  variant: AppChipVariant.choice,
                                  selected: _kind == kind,
                                  onTap: () => setState(() => _kind = kind),
                                ),
                            ],
                          ),
                          if (_kind == AddressKind.other) ...[
                            const SizedBox(height: AppSpacing.md),
                            AppInput(
                              label: 'Nombre',
                              controller: _label,
                              hint: 'Casa de mi mamá',
                              textCapitalization: TextCapitalization.sentences,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, AppSpacing.md),
              child: AppButton(label: 'Guardar dirección', loading: _saving, onPressed: _save),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón circular claro sobre el mapa.
class _MapButton extends StatelessWidget {
  const _MapButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: AppShadows.soft(theme.brightness)),
      child: IconButton(
        tooltip: 'Volver',
        style: IconButton.styleFrom(backgroundColor: theme.colorScheme.surface, foregroundColor: theme.colorScheme.onSurface),
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: onPressed,
      ),
    );
  }
}
