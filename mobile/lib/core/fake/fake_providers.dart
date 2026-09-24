import 'package:chaski/core/fake/fake_backend.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'fake_providers.g.dart';

@Riverpod(keepAlive: true)
FakeBackend fakeBackend(Ref ref) => FakeBackend();
