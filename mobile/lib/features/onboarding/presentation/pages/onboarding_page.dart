import 'package:chaski/features/auth/auth.dart';
import 'package:chaski/features/onboarding/presentation/providers/onboarding_status.dart';
import 'package:chaski/features/onboarding/presentation/widgets/city_onboarding_scene.dart';
import 'package:chaski/features/onboarding/presentation/widgets/onboarding_content.dart';
import 'package:chaski/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Onboarding como una sola historia (descubre → pide → recibe) sobre fotos de
/// la ciudad; debajo, el progreso.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  static const name = 'onboarding';

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();
  int _page = 0;
  bool _saving = false;

  /// La entrada escalonada solo se ve en la primera apertura.
  bool _introPlayed = false;

  bool get _isLast => _page == onboardingSlides.length - 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _introPlayed = true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Posición continua de la cámara (sigue al dedo).
  double get _cameraPage {
    final position = _controller.hasClients ? _controller.position : null;
    if (position == null || !position.hasContentDimensions || !position.hasPixels) return _page.toDouble();
    return _controller.page ?? _page.toDouble();
  }

  Future<void> _finish() async {
    if (_saving) return;
    HapticFeedback.lightImpact().ignore();
    setState(() => _saving = true);
    final router = GoRouter.of(context);
    try {
      await ref.read(onboardingStatusProvider.notifier).complete();
    } on Exception {
      if (!mounted) return;
      setState(() => _saving = false);
      AppToast.show(context, 'No pudimos guardar tu avance. Inténtalo de nuevo.', kind: AppToastKind.error);
      return;
    }
    if (!mounted) return;
    router.goNamed(PhoneEntryPage.name);
  }

  void _dragScene(DragUpdateDetails details) {
    if (_saving || !_controller.hasClients) return;
    _controller.jumpTo((_controller.offset - details.delta.dx).clamp(0.0, _controller.position.maxScrollExtent));
  }

  void _endSceneDrag(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final destination = velocity.abs() > 300 ? (velocity < 0 ? _cameraPage.floor() + 1 : _cameraPage.ceil() - 1) : _cameraPage.round();
    _goTo(destination.clamp(0, onboardingSlides.length - 1));
  }

  void _goTo(int page) {
    if (_saving) return;
    if (reduceMotionOf(context)) {
      _controller.jumpToPage(page);
    } else {
      _controller.animateToPage(page, duration: AppMotion.story, curve: Curves.easeInOutCubic).ignore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduced = reduceMotionOf(context);

    return PopScope(
      canPop: !_saving && _page == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_saving && _page > 0) _goTo(_page - 1);
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Contenido y acciones se desplazan juntos en pantallas bajas
                  // o con texto grande.
                  final compact = constraints.maxHeight < 650 || MediaQuery.textScalerOf(context).scale(16) > 20;
                  final sceneHeight = compact ? (constraints.maxHeight * 0.3).clamp(150.0, 220.0) : (constraints.maxHeight * 0.4).clamp(240.0, 360.0);

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xxs, AppSpacing.sm, AppSpacing.xxs),
                        child: SizedBox(
                          height: AppSpacing.minTouch,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: _isLast ? null : AuthLink(label: 'Saltar', onTap: _saving ? null : _finish),
                          ),
                        ),
                      ),
                      Padding(
                        padding: AppSpacing.screen,
                        child: SizedBox(
                          height: sceneHeight,
                          child: FadeSlideIn(
                            enabled: !_introPlayed,
                            duration: AppMotion.story,
                            offset: const Offset(0, 16),
                            child: AnimatedBuilder(
                              animation: _controller,
                              builder: (context, _) => GestureDetector(
                                onHorizontalDragUpdate: _dragScene,
                                onHorizontalDragEnd: _endSceneDrag,
                                child: CityOnboardingScene(page: _cameraPage, still: reduced),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.gutter - AppSpacing.sm,
                          compact ? 0 : AppSpacing.xs,
                          AppSpacing.gutter,
                          compact ? 0 : AppSpacing.xs,
                        ),
                        child: Align(alignment: Alignment.centerLeft, child: _progress(context)),
                      ),
                      Expanded(
                        child: AbsorbPointer(
                          absorbing: _saving,
                          child: PageView.builder(
                            controller: _controller,
                            itemCount: onboardingSlides.length,
                            onPageChanged: (page) {
                              HapticFeedback.selectionClick().ignore();
                              setState(() => _page = page);
                            },
                            itemBuilder: (context, index) => ExcludeSemantics(
                              excluding: index != _page,
                              child: SingleChildScrollView(
                                key: PageStorageKey('onboarding-scroll-$index'),
                                padding: AppSpacing.screen,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    AnimatedBuilder(
                                      animation: _controller,
                                      builder: (context, _) => OnboardingCopy(
                                        slide: onboardingSlides[index],
                                        compact: compact,
                                        pageOffset: reduced ? 0 : _cameraPage - index,
                                        animateIn: index == 0 && !_introPlayed,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    if (compact) _footer(context, page: index),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (!compact)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.md),
                          child: _footer(context),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Progreso: el paso actual es una barra ancha; los demás, puntos. Cada punto
  /// lleva a su paso (área táctil de 48).
  Widget _progress(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reduced = reduceMotionOf(context);
    return Semantics(
      label: 'Paso ${_page + 1} de ${onboardingSlides.length}',
      liveRegion: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < onboardingSlides.length; index++)
            Semantics(
              label: 'Ir al paso ${index + 1}',
              selected: index == _page,
              button: true,
              child: InkResponse(
                onTap: _saving ? null : () => _goTo(index),
                radius: 20,
                child: SizedBox(
                  width: index == _page ? 44 : 24,
                  height: AppSpacing.minTouch,
                  child: Center(
                    child: AnimatedContainer(
                      duration: reduced ? Duration.zero : AppMotion.base,
                      curve: AppMotion.arrive,
                      width: index == _page ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: index == _page ? scheme.primary : scheme.onSurfaceVariant.withValues(alpha: 0.3),
                        borderRadius: const BorderRadius.all(AppRadius.pill),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context, {int? page}) {
    final current = page ?? _page;
    final isLast = current == onboardingSlides.length - 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: AppButton(
        label: _saving ? 'Un momento…' : onboardingSlides[current].cta,
        loading: _saving,
        onPressed: _saving ? null : () => isLast ? _finish() : _goTo(current + 1),
      ),
    );
  }
}
