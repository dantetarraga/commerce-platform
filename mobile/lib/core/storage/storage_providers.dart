import 'package:chaski/core/storage/local_json_store.dart';
import 'package:chaski/core/storage/preferences_storage.dart';
import 'package:chaski/core/storage/token_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'storage_providers.g.dart';

@Riverpod(keepAlive: true)
TokenStorage tokenStorage(Ref ref) => TokenStorage();

@Riverpod(keepAlive: true)
PreferencesStorage preferencesStorage(Ref ref) => PreferencesStorage();

@Riverpod(keepAlive: true)
LocalJsonStore localJsonStore(Ref ref) => SharedPrefsJsonStore();
