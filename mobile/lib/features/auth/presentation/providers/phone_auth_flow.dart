import 'package:apamuy/core/domain/phone_number.dart';
import 'package:apamuy/core/errors/failure.dart';
import 'package:apamuy/features/auth/domain/entities/otp.dart';
import 'package:apamuy/features/auth/domain/value_objects/otp_code.dart';
import 'package:apamuy/features/auth/domain/value_objects/person_name.dart';
import 'package:apamuy/features/auth/presentation/providers/auth_providers.dart';
import 'package:apamuy/features/auth/presentation/providers/auth_session.dart';
import 'package:equatable/equatable.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'phone_auth_flow.g.dart';

enum PhoneAuthStep { phone, code, profile }

/// Estado del flujo celular → código → (nombre). Vive entre las tres
/// pantallas; se reinicia al iniciar sesión.
final class PhoneAuthState extends Equatable {
  const PhoneAuthState({
    this.step = PhoneAuthStep.phone,
    this.phone,
    this.challenge,
    this.codeSentAt,
    this.registrationToken,
    this.loading = false,
    this.error,
  });

  final PhoneAuthStep step;
  final PhoneNumber? phone;
  final OtpChallenge? challenge;
  final DateTime? codeSentAt;
  final String? registrationToken;
  final bool loading;
  final Failure? error;

  /// Momento a partir del cual se puede pedir otro código.
  DateTime? get canResendAt => codeSentAt == null || challenge == null ? null : codeSentAt!.add(challenge!.resendAfter);

  PhoneAuthState copyWith({
    PhoneAuthStep? step,
    PhoneNumber? phone,
    OtpChallenge? challenge,
    DateTime? codeSentAt,
    String? registrationToken,
    bool? loading,
    Failure? error,
    bool clearError = false,
  }) => PhoneAuthState(
    step: step ?? this.step,
    phone: phone ?? this.phone,
    challenge: challenge ?? this.challenge,
    codeSentAt: codeSentAt ?? this.codeSentAt,
    registrationToken: registrationToken ?? this.registrationToken,
    loading: loading ?? this.loading,
    error: clearError ? null : (error ?? this.error),
  );

  @override
  List<Object?> get props => [step, phone, challenge, codeSentAt, registrationToken, loading, error];
}

@Riverpod(keepAlive: true)
class PhoneAuthFlow extends _$PhoneAuthFlow {
  @override
  PhoneAuthState build() => const PhoneAuthState();

  /// Pide (o reenvía) el código. Devuelve `true` si se envió.
  Future<bool> requestCode(PhoneNumber phone) async {
    state = state.copyWith(loading: true, clearError: true);
    final result = await ref.read(requestCodeProvider).call(phone);
    if (!ref.mounted) return false;
    return result.fold(
      (challenge) {
        state = PhoneAuthState(step: PhoneAuthStep.code, phone: phone, challenge: challenge, codeSentAt: DateTime.now());
        return true;
      },
      (failure) {
        state = state.copyWith(loading: false, error: failure);
        return false;
      },
    );
  }

  /// Verifica el código. Si el número ya tenía cuenta inicia sesión (el router
  /// redirige solo); si es nuevo pasa al paso de nombre.
  Future<PhoneAuthStep?> verify(OtpCode code) async {
    final phone = state.phone;
    if (phone == null) return null;
    state = state.copyWith(loading: true, clearError: true);
    final result = await ref.read(verifyCodeProvider).call(phone, code);
    if (!ref.mounted) return null;
    return result.fold(
      (verification) {
        switch (verification) {
          case OtpSignedIn(:final user):
            ref.read(authSessionProvider.notifier).signedIn(user);
            state = const PhoneAuthState();
            return null;
          case OtpProfileRequired(:final registrationToken):
            state = state.copyWith(step: PhoneAuthStep.profile, registrationToken: registrationToken, loading: false);
            return PhoneAuthStep.profile;
        }
      },
      (failure) {
        state = state.copyWith(loading: false, error: failure);
        return PhoneAuthStep.code;
      },
    );
  }

  /// Crea la cuenta con el nombre y entra.
  Future<void> completeProfile({required PersonName firstName, required PersonName lastName}) async {
    final token = state.registrationToken;
    if (token == null) return;
    state = state.copyWith(loading: true, clearError: true);
    final result = await ref
        .read(completeProfileProvider)
        .call(registrationToken: token, firstName: firstName, lastName: lastName);
    if (!ref.mounted) return;
    result.fold(
      (user) {
        ref.read(authSessionProvider.notifier).signedIn(user);
        state = const PhoneAuthState();
      },
      (failure) => state = state.copyWith(loading: false, error: failure),
    );
  }

  void clearError() => state = state.copyWith(clearError: true);

  void reset() => state = const PhoneAuthState();
}
