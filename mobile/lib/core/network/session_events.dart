import 'dart:async';

/// Canal para avisar que la sesión expiró (refresh fallido) sin acoplar la capa
/// de red al feature de auth.
class SessionEvents {
  final _expired = StreamController<void>.broadcast();

  Stream<void> get onExpired => _expired.stream;

  void notifyExpired() => _expired.add(null);

  Future<void> dispose() => _expired.close();
}
