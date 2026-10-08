/// Ordena las lecturas, escrituras y borrados de una instancia de almacenamiento.
/// Evita que una migración pendiente restaure datos después de un borrado.
class StorageOperationQueue {
  Future<void> _pending = Future<void>.value();

  Future<T> run<T>(Future<T> Function() operation) {
    final result = _pending.then((_) => operation());
    // Un fallo llega al llamador, pero no bloquea operaciones posteriores.
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}
