import 'package:chaski/app/config/app_config_provider.dart';
import 'package:chaski/core/network/api_client.dart';
import 'package:chaski/core/network/interceptors/auth_interceptor.dart';
import 'package:chaski/core/network/interceptors/request_id_interceptor.dart';
import 'package:chaski/core/network/session_events.dart';
import 'package:chaski/core/storage/storage_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'network_providers.g.dart';

@Riverpod(keepAlive: true)
SessionEvents sessionEvents(Ref ref) {
  final events = SessionEvents();
  ref.onDispose(events.dispose);
  return events;
}

@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final env = ref.watch(appEnvProvider);
  final options = BaseOptions(
    baseUrl: env.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    contentType: Headers.jsonContentType,
  );

  final dio = Dio(options);
  dio.interceptors.addAll([
    RequestIdInterceptor(),
    AuthInterceptor(
      dio: dio,
      refreshDio: Dio(options),
      tokenStorage: ref.watch(tokenStorageProvider),
      onSessionExpired: ref.read(sessionEventsProvider).notifyExpired,
    ),
    if (kDebugMode) LogInterceptor(requestBody: true, responseBody: true),
  ]);
  return dio;
}

@Riverpod(keepAlive: true)
ApiClient apiClient(Ref ref) => ApiClient(ref.watch(dioProvider));
