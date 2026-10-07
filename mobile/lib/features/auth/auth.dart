/// API pública del feature `auth`.
library;

export 'domain/entities/auth_user.dart';
export 'presentation/pages/otp_page.dart';
export 'presentation/pages/phone_entry_page.dart';
export 'presentation/pages/profile_setup_page.dart';
export 'presentation/pages/splash_page.dart';
export 'presentation/providers/auth_demo.dart';
export 'presentation/providers/auth_session.dart';
export 'presentation/providers/phone_auth_flow.dart' show phoneAuthFlowProvider;
export 'presentation/providers/splash_gate.dart';
export 'presentation/widgets/auth_scaffold.dart' show AuthHeader, AuthLink, AuthScaffold;
