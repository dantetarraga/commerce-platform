import 'package:chaski/core/storage/storage_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_status.g.dart';

/// `true` si el usuario ya vio el onboarding en este dispositivo.
@Riverpod(keepAlive: true)
class OnboardingStatus extends _$OnboardingStatus {
  @override
  Future<bool> build() => ref.watch(preferencesStorageProvider).isOnboardingSeen();

  Future<void> complete() async {
    await ref.read(preferencesStorageProvider).markOnboardingSeen();
    state = const AsyncData(true);
  }
}
