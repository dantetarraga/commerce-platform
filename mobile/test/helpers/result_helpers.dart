import 'package:chaski/core/errors/failure.dart';
import 'package:chaski/core/result/result.dart';

/// El `Failure` de un resultado que se espera fallido.
Failure failureOf<T>(Result<T> result) =>
    result.fold((value) => throw StateError('Se esperaba un error y llegó $value'), (failure) => failure);
