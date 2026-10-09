import 'dart:async';

import 'package:apamuy/core/config/city.dart';
import 'package:apamuy/core/config/city_area.dart';
import 'package:apamuy/core/domain/geo_coordinates.dart';
import 'package:apamuy/core/maps/delivery_location.dart';
import 'package:apamuy/core/maps/geocoding_service.dart';
import 'package:apamuy/core/maps/location_service.dart';
import 'package:apamuy/features/addresses/domain/address.dart';
import 'package:apamuy/features/addresses/presentation/providers/address_providers.dart';
import 'package:apamuy/features/addresses/presentation/widgets/door_map.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:apamuy/shared/utils/value_failure_message.dart';
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
  /// La zona de reparto que el admin define en Ciudades (la misma que valida el backend).
  bool _inArea(GeoCoordinates point) => ref.read(currentCityAreaProvider).contains(point);

  final _formKey = GlobalKey<FormState>();
  final _street = TextEditingController();
  final _reference = TextEditingController();
  final _label = TextEditingController();
  AddressKind _kind = AddressKind.home;
  var _saving = false;
  var _seed = '';

  late final GeoCoordinates _origin = ref.read(currentDeliveryLocationProvider).coordinates;

  /// El punto bajo el pin.
  late GeoCoordinates _door = _origin;

  /// Adónde debe volar el mapa ("Mi ubicación").
  GeoCoordinates? _focus;
  var _locating = false;

  /// La última calle que puso el mapa. Mientras el campo la tenga (o esté
  /// vacío) el mapa puede cambiarla; si el usuario escribe, ya no.
  String? _autoStreet;
  var _streetLookup = 0;
  Timer? _findDebounce;

  @override
  void initState() {
    super.initState();
    if (googleMapsSupported) WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_locate(quiet: true)));
  }

  /// Lleva el mapa a la ubicación del teléfono. Con [quiet] (al abrir) no avisa
  /// si falta permiso o señal: el usuario igual puede mover el mapa.
  Future<void> _locate({bool quiet = false}) async {
    setState(() => _locating = true);
    final service = ref.read(locationServiceProvider);
    final reading = await service.current();
    if (!mounted) return;
    setState(() => _locating = false);
    final (String? message, String? action) = switch (reading) {
      LocationFix(:final coordinates) when _inArea(coordinates) => (null, null),
      LocationFix() => ('Tu ubicación está fuera de $cityName. Mueve el mapa hasta tu puerta.', null),
      LocationOff() => ('Activa la ubicación del teléfono para encontrarte.', 'Activar'),
      LocationDenied(forever: true) => ('Da permiso de ubicación a Apamuy en Ajustes.', 'Ajustes'),
      LocationDenied() => quiet ? (null, null) : ('Sin permiso de ubicación. Mueve el mapa hasta tu puerta.', null),
      LocationUnavailable() => quiet ? (null, null) : ('No pudimos encontrarte. Mueve el mapa hasta tu puerta.', null),
    };
    if (reading case LocationFix(:final coordinates) when _inArea(coordinates)) {
      setState(() => _focus = coordinates);
    }
    if (message != null) {
      AppToast.show(
        context,
        message,
        actionLabel: action,
        onAction: action == null ? null : () => unawaited(service.openSettings(reading)),
      );
    }
  }

  void _onCenter(GeoCoordinates door) {
    setState(() => _door = door);
    unawaited(_fillStreet(door));
  }

  bool get _streetIsAuto => _street.text.trim().isEmpty || _street.text == _autoStreet;

  Future<void> _fillStreet(GeoCoordinates door) async {
    if (!_streetIsAuto) return;
    final lookup = ++_streetLookup;
    final street = await ref.read(geocodingServiceProvider).streetAt(door);
    if (!mounted || lookup != _streetLookup || street == null || !_streetIsAuto) return;
    _autoStreet = street;
    _street.text = street;
  }

  /// Al dejar de escribir, lleva el mapa a la calle si la encuentra en la zona.
  void _onStreetTyped(String value) {
    if (value.trim().length >= StreetLine.minLength) setState(() => _seed = value);
    _findDebounce?.cancel();
    if (value == _autoStreet || value.trim().length < StreetLine.minLength) return;
    _findDebounce = Timer(const Duration(milliseconds: 900), () async {
      final point = await ref.read(geocodingServiceProvider).find(value, within: _inArea);
      if (mounted && point != null && _street.text == value) setState(() => _focus = point);
    });
  }

  @override
  void dispose() {
    _findDebounce?.cancel();
    _street.dispose();
    _reference.dispose();
    _label.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_inArea(_door)) {
      AppToast.show(context, 'Ese punto está fuera de la zona de reparto de $cityName.', kind: AppToastKind.error);
      return;
    }
    setState(() => _saving = true);
    final Address address;
    try {
      address = await ref
          .read(addressBookControllerProvider.notifier)
          .add(
            kind: _kind,
            street: StreetLine.create(_street.text).valueOrNull!,
            coordinates: _door,
            reference: _reference.text,
            label: _label.text,
          );
    } on Object {
      if (mounted) AppToast.show(context, 'No pudimos guardar la dirección. Inténtalo otra vez.', kind: AppToastKind.error);
      return;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
              DoorMap(
                origin: _origin,
                focus: _focus,
                seed: _seed,
                height: mapHeight,
                hint: _inArea(_door) ? 'Mueve el mapa hasta tu puerta' : 'Fuera de la zona de reparto',
                onCenter: _onCenter,
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: AppCircleButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Volver',
                    elevated: true,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
              if (googleMapsSupported)
                Positioned(
                  right: AppSpacing.xs,
                  bottom: AppSpacing.xs,
                  child: AppCircleButton(
                    icon: Icons.my_location_rounded,
                    tooltip: 'Mi ubicación',
                    elevated: true,
                    onPressed: _locating ? null : () => unawaited(_locate()),
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
                            onChanged: _onStreetTyped,
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
                            validator: (v) =>
                                (v ?? '').trim().isEmpty ? 'Cuéntale al repartidor cómo reconocer tu puerta.' : null,
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
                              validator: (v) => (v ?? '').trim().isEmpty ? 'Ponle un nombre para reconocerla.' : null,
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
