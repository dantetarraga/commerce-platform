import 'package:chaski/features/auth/infrastructure/datasources/remote/fake_auth_remote_data_source.dart';

/// Cuenta que el modo demo ofrece para entrar con un toque.
typedef DemoAccount = ({String label, String phone});

/// Cuentas y código del modo demo (`USE_FAKE_DATA`). Las páginas las leen de
/// aquí para no depender de la infraestructura fake.
abstract final class AuthDemo {
  static const String code = FakeAuthRemoteDataSource.demoCode;
  static const DemoAccount customer = (label: 'Cliente', phone: FakeAuthRemoteDataSource.demoPhone);
  static const DemoAccount merchant = (label: 'Negocio', phone: FakeAuthRemoteDataSource.demoMerchantPhone);
  static const DemoAccount courier = (label: 'Repartidor', phone: FakeAuthRemoteDataSource.demoCourierPhone);
}
