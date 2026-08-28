/// Templates for everything outside a feature slice: app bootstrap, core
/// layer, configuration files and docs.
class ProjectTemplates {
  const ProjectTemplates._();

  static const String pubspec = r'''
name: {{project_name}}
description: "{{description}}"
publish_to: "none"
version: {{app_version}}

environment:
  sdk: ^3.5.0

dependencies:
{{dependencies}}
dev_dependencies:
{{dev_dependencies}}
{{#use_localization}}
easy_localization:
  assets_path: assets/translations
  output_dir: lib/core/localization
  output_file: locale_keys.g.dart

{{/use_localization}}
flutter:
  uses-material-design: true
  assets:
    - assets/images/
{{#use_localization}}
    - assets/translations/
{{/use_localization}}
{{#use_env}}
    - .env
{{/use_env}}
{{#use_flavors}}

flavorizr:
  app:
    android:
      flavorDimensions: "flavor-type"
    ios:

  flavors:
    dev:
      app:
        name: "{{display_name}} Dev"
      android:
        applicationId: "{{android_package}}.dev"
      ios:
        bundleId: "{{ios_bundle_id}}.dev"
    stg:
      app:
        name: "{{display_name}} Stg"
      android:
        applicationId: "{{android_package}}.stg"
      ios:
        bundleId: "{{ios_bundle_id}}.stg"
    prod:
      app:
        name: "{{display_name}}"
      android:
        applicationId: "{{android_package}}"
      ios:
        bundleId: "{{ios_bundle_id}}"
{{/use_flavors}}
''';

  static const String main = r'''
{{#use_localization}}
import 'package:easy_localization/easy_localization.dart';
{{/use_localization}}
{{#use_firebase}}
import 'package:firebase_core/firebase_core.dart';
{{/use_firebase}}
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
{{#use_env}}
import 'package:flutter_dotenv/flutter_dotenv.dart';
{{/use_env}}

import 'package:{{project_name}}/app.dart';
import 'package:{{project_name}}/core/bloc/app_bloc_observer.dart';
{{#use_firebase}}
import 'package:{{project_name}}/core/notifications/push_notification_service.dart';
{{/use_firebase}}
import 'package:{{project_name}}/injection_container.dart' as di;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
{{#use_localization}}
  await EasyLocalization.ensureInitialized();
{{/use_localization}}
{{#use_env}}
  await dotenv.load(fileName: '.env');
{{/use_env}}
{{#use_firebase}}
  await Firebase.initializeApp();
{{/use_firebase}}

  Bloc.observer = const AppBlocObserver();
  await di.init();
{{#use_firebase}}
  await di.sl<PushNotificationService>().initialize();
{{/use_firebase}}

{{#use_localization}}
  runApp(
    EasyLocalization(
      supportedLocales: const [
{{#locales}}
        Locale('{{language}}'),
{{/locales}}
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('{{default_locale}}'),
      child: const {{app_class}}(),
    ),
  );
{{/use_localization}}
{{^use_localization}}
  runApp(const {{app_class}}());
{{/use_localization}}
}
''';

  static const String app = r'''
{{#use_localization}}
import 'package:easy_localization/easy_localization.dart';
{{/use_localization}}
import 'package:flutter/material.dart';
{{^use_routing}}
import 'package:flutter_bloc/flutter_bloc.dart';
{{/use_routing}}
{{#use_responsive}}
import 'package:flutter_screenutil/flutter_screenutil.dart';
{{/use_responsive}}

{{#use_routing}}
import 'package:{{project_name}}/core/router/app_router.dart';
{{/use_routing}}
{{#use_theming}}
import 'package:{{project_name}}/core/theme/app_theme.dart';
{{/use_theming}}
{{^use_routing}}
{{#use_example}}
import 'package:{{project_name}}/features/example/presentation/{{state_dir}}/example_{{state_dir}}.dart';
import 'package:{{project_name}}/features/example/presentation/pages/example_page.dart';
import 'package:{{project_name}}/injection_container.dart';
{{/use_example}}
{{/use_routing}}
// clean_bloc:imports

class {{app_class}} extends StatelessWidget {
  const {{app_class}}({super.key});

  @override
  Widget build(BuildContext context) {
{{#use_routing}}
    // Feature blocs are provided per route in AppRouter, so they live exactly
    // as long as the screen that uses them. Only app-wide blocs belong here.
{{/use_routing}}
{{^use_routing}}
    // Without a router there is no per-screen scope, so feature blocs are
    // provided above MaterialApp.
{{/use_routing}}
{{^use_routing}}
    return MultiBlocProvider(
{{^use_example}}
      // The list is filled in by `clean_bloc feature`.
      // ignore: prefer_const_literals_to_create_immutables
{{/use_example}}
      providers: [
{{#use_example}}
        BlocProvider(
          create: (_) =>
{{#use_bloc}}
              sl<ExampleBloc>()..add(const LoadExamples()),
{{/use_bloc}}
{{#use_cubit}}
              sl<ExampleCubit>()..loadExamples(),
{{/use_cubit}}
        ),
{{/use_example}}
        // clean_bloc:providers
      ],
{{#use_responsive}}
      child: ScreenUtilInit(
        designSize: const Size({{design_width}}, {{design_height}}),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => const _AppView(),
      ),
{{/use_responsive}}
{{^use_responsive}}
      child: const _AppView(),
{{/use_responsive}}
    );
{{/use_routing}}
{{#use_routing}}
{{#use_responsive}}
    return ScreenUtilInit(
      designSize: const Size({{design_width}}, {{design_height}}),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => const _AppView(),
    );
{{/use_responsive}}
{{^use_responsive}}
    return const _AppView();
{{/use_responsive}}
{{/use_routing}}
  }
}

class _AppView extends StatelessWidget {
  const _AppView();

  @override
  Widget build(BuildContext context) {
{{#use_routing}}
    return MaterialApp.router(
      title: '{{display_name}}',
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
{{/use_routing}}
{{^use_routing}}
    return MaterialApp(
      title: '{{display_name}}',
      debugShowCheckedModeBanner: false,
{{#use_example}}
      home: const ExamplePage(),
{{/use_example}}
{{^use_example}}
      home: const Scaffold(body: Center(child: Text('{{display_name}}'))),
{{/use_example}}
{{/use_routing}}
{{#use_theming}}
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
{{/use_theming}}
{{#use_localization}}
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
{{/use_localization}}
    );
  }
}
''';

  static const String injectionContainer = r'''
{{#use_network}}
import 'package:dio/dio.dart';
{{/use_network}}
{{#use_env_network}}
import 'package:flutter_dotenv/flutter_dotenv.dart';
{{/use_env_network}}
{{#use_secure_storage}}
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
{{/use_secure_storage}}
import 'package:get_it/get_it.dart';
{{#use_connectivity}}
import 'package:internet_connection_checker/internet_connection_checker.dart';
{{/use_connectivity}}
{{#use_prefs}}
import 'package:shared_preferences/shared_preferences.dart';
{{/use_prefs}}

{{#use_network}}
import 'package:{{project_name}}/core/constants/app_constants.dart';
import 'package:{{project_name}}/core/network/api_client.dart';
{{#use_secure_storage}}
import 'package:{{project_name}}/core/network/interceptors/auth_interceptor.dart';
{{/use_secure_storage}}
import 'package:{{project_name}}/core/network/interceptors/error_interceptor.dart';
{{#use_localization}}
import 'package:{{project_name}}/core/network/interceptors/headers_interceptor.dart';
{{/use_localization}}
import 'package:{{project_name}}/core/network/interceptors/retry_interceptor.dart';
{{/use_network}}
{{#use_connectivity}}
import 'package:{{project_name}}/core/network/network_info.dart';
import 'package:{{project_name}}/core/network/network_info_impl.dart';
{{/use_connectivity}}
{{#use_firebase}}
import 'package:{{project_name}}/core/notifications/push_notification_service.dart';
{{/use_firebase}}
{{#use_secure_storage}}
import 'package:{{project_name}}/core/storage/secure_storage_service.dart';
{{/use_secure_storage}}
{{#use_example}}
{{#use_prefs}}
import 'package:{{project_name}}/features/example/data/datasources/example_local_data_source.dart';
import 'package:{{project_name}}/features/example/data/datasources/example_local_data_source_impl.dart';
{{/use_prefs}}
{{#use_network}}
import 'package:{{project_name}}/features/example/data/datasources/example_remote_data_source.dart';
import 'package:{{project_name}}/features/example/data/datasources/example_remote_data_source_impl.dart';
{{/use_network}}
import 'package:{{project_name}}/features/example/data/repositories/example_repository_impl.dart';
import 'package:{{project_name}}/features/example/domain/repositories/example_repository.dart';
import 'package:{{project_name}}/features/example/domain/usecases/get_examples.dart';
import 'package:{{project_name}}/features/example/presentation/{{state_dir}}/example_{{state_dir}}.dart';
{{/use_example}}
// clean_bloc:imports

final GetIt sl = GetIt.instance;

/// Wires the object graph. Call once, before `runApp`.
///
/// Registration follows the dependency direction: external packages first,
/// then core services, then one block per feature. Blocs are factories - each
/// screen gets a fresh instance; everything below them is a lazy singleton.
Future<void> init() async {
  await _registerExternal();
  _registerCore();
  _registerFeatures();
}

/// Third party singletons the app does not own.
Future<void> _registerExternal() async {
{{#use_prefs}}
  final preferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => preferences);
{{/use_prefs}}
{{#use_secure_storage}}
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );
{{/use_secure_storage}}
{{#use_connectivity}}
  sl.registerLazySingleton<InternetConnectionChecker>(
    InternetConnectionChecker.new,
  );
{{/use_connectivity}}
}

/// Cross cutting services: storage, connectivity, HTTP and its interceptors.
void _registerCore() {
{{#use_secure_storage}}
  sl.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(sl()),
  );
{{/use_secure_storage}}
{{#use_connectivity}}
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
{{/use_connectivity}}
{{#use_firebase}}
  sl.registerLazySingleton<PushNotificationService>(
    PushNotificationService.new,
  );
{{/use_firebase}}
{{#use_network}}

  // A bare client for calls that must not go through the auth interceptor
  // (token refresh), otherwise a failing refresh would recurse.
  sl.registerLazySingleton<Dio>(
    () => ApiClient.create(baseUrl: _baseUrl),
    instanceName: refreshClient,
  );

  sl.registerLazySingleton<Dio>(
    () => ApiClient.create(
      baseUrl: _baseUrl,
      interceptors: [
{{#use_localization}}
        HeadersInterceptor(localeResolver: () => AppConstants.defaultLocale),
{{/use_localization}}
{{#use_secure_storage}}
        AuthInterceptor(
          storage: sl(),
          refreshDio: sl<Dio>(instanceName: refreshClient),
        ),
{{/use_secure_storage}}
        RetryInterceptor(dio: sl<Dio>(instanceName: refreshClient)),
        const ErrorInterceptor(),
      ],
    ),
  );
{{/use_network}}
}

/// One block per feature: bloc -> use cases -> repository -> data sources.
void _registerFeatures() {
{{#use_example}}
  // Example
  sl.registerFactory(() => Example{{state_suffix}}(getExamples: sl()));

  sl.registerLazySingleton(() => GetExamples(sl()));

  sl.registerLazySingleton<ExampleRepository>(
{{#has_repo_deps}}
    () => ExampleRepositoryImpl(
{{#use_network}}
      remoteDataSource: sl(),
{{/use_network}}
{{#use_prefs}}
      localDataSource: sl(),
{{/use_prefs}}
{{#use_connectivity}}
      networkInfo: sl(),
{{/use_connectivity}}
    ),
{{/has_repo_deps}}
{{^has_repo_deps}}
    () => const ExampleRepositoryImpl(),
{{/has_repo_deps}}
  );
{{#use_network}}
  sl.registerLazySingleton<ExampleRemoteDataSource>(
    () => ExampleRemoteDataSourceImpl(dio: sl()),
  );
{{/use_network}}
{{#use_prefs}}
  sl.registerLazySingleton<ExampleLocalDataSource>(
    () => ExampleLocalDataSourceImpl(preferences: sl()),
  );
{{/use_prefs}}
{{/use_example}}
  // clean_bloc:registrations
}
{{#use_network}}

/// Name of the interceptor-free client used for token refresh and retries.
const String refreshClient = 'refreshClient';

String get _baseUrl {
{{#use_env_network}}
  return dotenv.env['API_BASE_URL'] ?? AppConstants.fallbackBaseUrl;
{{/use_env_network}}
{{^use_env_network}}
  return AppConstants.fallbackBaseUrl;
{{/use_env_network}}
}
{{/use_network}}
''';

  static const String exceptions = r'''
/// Errors thrown by the data layer. They never leave a repository - the
/// repository maps them to a [Failure] via `Failure.from`.
sealed class AppException implements Exception {
  const AppException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => '$runtimeType($statusCode): $message';
}

/// 5xx, or a response the app could not make sense of.
class ServerException extends AppException {
  const ServerException([
    super.message = 'Server error. Please try again.',
    int? statusCode,
  ]) : super(statusCode: statusCode);
}

/// 401 / 403 - the caller needs to authenticate again.
class UnauthorizedException extends AppException {
  const UnauthorizedException([
    super.message = 'Your session has expired. Please sign in again.',
  ]) : super(statusCode: 401);
}

/// 404.
class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Not found.'])
      : super(statusCode: 404);
}

/// 400 / 422 with a field-level error map.
class ValidationException extends AppException {
  const ValidationException(
    super.message, {
    this.errors = const {},
    super.statusCode = 422,
  });

  final Map<String, List<String>> errors;
}

/// Connect, send or receive timeout.
class RequestTimeoutException extends AppException {
  const RequestTimeoutException([
    super.message = 'The request timed out. Please try again.',
  ]);
}

/// The device is offline or the host is unreachable.
class NoInternetException extends AppException {
  const NoInternetException([
    super.message = 'No internet connection. Please check your network.',
  ]);
}

/// The request was cancelled before it completed.
class RequestCancelledException extends AppException {
  const RequestCancelledException([super.message = 'Request cancelled.']);
}

/// Nothing usable is stored locally.
class CacheException extends AppException {
  const CacheException([super.message = 'No cached data available.']);
}

/// Anything the layers above could not classify.
class UnknownException extends AppException {
  const UnknownException([super.message = 'Something went wrong.']);
}
''';

  static const String failures = r'''
import 'package:equatable/equatable.dart';

import 'package:{{project_name}}/core/error/exceptions.dart';

/// Domain level error. Repositories return these instead of throwing, so the
/// presentation layer never has to catch anything.
sealed class Failure extends Equatable {
  const Failure(this.message, {this.statusCode});

  /// Maps a data layer [AppException] (or any error) onto its [Failure].
  factory Failure.from(Object error) {
    return switch (error) {
      UnauthorizedException() => UnauthorizedFailure(error.message),
      NotFoundException() => NotFoundFailure(error.message),
      ValidationException() =>
        ValidationFailure(error.message, errors: error.errors),
      RequestTimeoutException() => TimeoutFailure(error.message),
      NoInternetException() => NetworkFailure(error.message),
      RequestCancelledException() => CancelledFailure(error.message),
      CacheException() => CacheFailure(error.message),
      ServerException(:final statusCode?) =>
        ServerStatusFailure(error.message, statusCode: statusCode),
      ServerException() => ServerFailure(error.message),
      AppException() => UnknownFailure(error.message),
      _ => UnknownFailure(error.toString()),
    };
  }

  final String message;
  final int? statusCode;

  @override
  List<Object?> get props => [message, statusCode];
}

class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Server error. Please try again.',
  ]) : super(statusCode: null);
}

/// A server failure that carries the HTTP status it came from.
class ServerStatusFailure extends Failure {
  const ServerStatusFailure(super.message, {required super.statusCode});
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'No cached data available.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'No internet connection. Please check your network.',
  ]);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([
    super.message = 'The request timed out. Please try again.',
  ]);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([
    super.message = 'Your session has expired. Please sign in again.',
  ]);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Not found.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {this.errors = const {}});

  final Map<String, List<String>> errors;

  @override
  List<Object?> get props => [...super.props, errors];
}

class CancelledFailure extends Failure {
  const CancelledFailure([super.message = 'Request cancelled.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something went wrong.']);
}
''';

  static const String useCaseContract = r'''
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:{{project_name}}/core/error/failures.dart';

/// Every use case is a callable object returning `Either<Failure, Type>`.
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
''';

  static const String networkInfo = r'''
abstract class NetworkInfo {
  Future<bool> get isConnected;
}
''';

  static const String networkInfoImpl = r'''
import 'package:internet_connection_checker/internet_connection_checker.dart';

import 'package:{{project_name}}/core/network/network_info.dart';

class NetworkInfoImpl implements NetworkInfo {
  const NetworkInfoImpl(this.connectionChecker);

  final InternetConnectionChecker connectionChecker;

  @override
  Future<bool> get isConnected => connectionChecker.hasConnection;
}
''';

  static const String dioClient = r'''
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

/// Builds the shared [Dio] instance.
///
/// Interceptor order matters - they run top to bottom on the way out and
/// bottom to top on the way back:
///
/// 1. headers     - static + per-request headers
/// 2. auth        - attaches the token, refreshes it on 401
/// 3. retry       - retries transient network failures
/// 4. error       - turns DioException into a typed AppException
/// 5. logging     - debug builds only, must stay last to see everything
class ApiClient {
  const ApiClient._();

  static Dio create({
    required String baseUrl,
    List<Interceptor> interceptors = const [],
    Duration timeout = const Duration(seconds: 30),
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: timeout,
        sendTimeout: timeout,
        receiveTimeout: timeout,
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        // Let the error interceptor decide what counts as a failure.
        validateStatus: (status) => status != null && status < 400,
      ),
    );

    dio.interceptors.addAll(interceptors);

    assert(() {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          compact: true,
        ),
      );
      return true;
    }());

    return dio;
  }
}
''';

  static const String errorInterceptor = r'''
import 'package:dio/dio.dart';

import 'package:{{project_name}}/core/error/exceptions.dart';

/// Translates transport level failures into the app's [AppException] types,
/// so data sources never have to interpret Dio internals.
///
/// The exception is attached to `DioException.error`; data sources rethrow it
/// unchanged.
class ErrorInterceptor extends Interceptor {
  const ErrorInterceptor();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        stackTrace: err.stackTrace,
        error: toAppException(err),
      ),
    );
  }

  static AppException toAppException(DioException error) {
    final existing = error.error;
    if (existing is AppException) return existing;

    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        const RequestTimeoutException(),
      DioExceptionType.connectionError =>
        const NoInternetException(),
      DioExceptionType.cancel => const RequestCancelledException(),
      DioExceptionType.badCertificate =>
        const ServerException('Invalid server certificate.'),
      DioExceptionType.badResponse => _fromResponse(error.response),
      DioExceptionType.unknown when error.error is String =>
        ServerException(error.error! as String),
      _ => const UnknownException(),
    };
  }

  static AppException _fromResponse(Response<dynamic>? response) {
    final status = response?.statusCode ?? 0;
    final message = _messageOf(response?.data);

    return switch (status) {
      401 || 403 => UnauthorizedException(
          message ?? 'Your session has expired. Please sign in again.',
        ),
      404 => NotFoundException(message ?? 'Not found.'),
      400 || 422 => ValidationException(
          message ?? 'Some of the submitted values are invalid.',
          errors: _fieldErrorsOf(response?.data),
          statusCode: status,
        ),
      _ => ServerException(
          message ?? 'Server error. Please try again.',
          status,
        ),
    };
  }

  /// Reads the message out of the common `{"message": ...}` /
  /// `{"error": ...}` response shapes.
  static String? _messageOf(Object? data) {
    if (data is! Map<String, dynamic>) return null;
    for (final key in const ['message', 'error', 'detail']) {
      final value = data[key];
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }

  /// Reads `{"errors": {"email": ["is invalid"]}}` style field errors.
  static Map<String, List<String>> _fieldErrorsOf(Object? data) {
    if (data is! Map<String, dynamic>) return const {};
    final errors = data['errors'];
    if (errors is! Map) return const {};

    return {
      for (final entry in errors.entries)
        entry.key.toString(): switch (entry.value) {
          final List<dynamic> list =>
            list.map((value) => value.toString()).toList(),
          final Object value => [value.toString()],
          null => const <String>[],
        },
    };
  }
}
''';

  static const String retryInterceptor = r'''
import 'dart:async';

import 'package:dio/dio.dart';

/// Retries transient failures (timeouts, dropped connections) with a linear
/// backoff. Only safe methods are retried, so a POST is never sent twice.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required this.dio,
    this.maxAttempts = 3,
    this.backoff = const [
      Duration(milliseconds: 500),
      Duration(seconds: 2),
    ],
  });

  final Dio dio;
  final int maxAttempts;
  final List<Duration> backoff;

  static const String _attemptKey = 'retry_attempt';
  static const Set<String> _retryableMethods = {'GET', 'HEAD', 'OPTIONS'};

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final attempt = (options.extra[_attemptKey] as int? ?? 0) + 1;

    if (!_shouldRetry(err) || attempt >= maxAttempts) {
      return handler.next(err);
    }

    await Future<void>.delayed(
      backoff[(attempt - 1).clamp(0, backoff.length - 1)],
    );

    try {
      final response = await dio.fetch<dynamic>(
        options..extra[_attemptKey] = attempt,
      );
      return handler.resolve(response);
    } on DioException catch (error) {
      return handler.next(error);
    }
  }

  bool _shouldRetry(DioException error) {
    if (!_retryableMethods.contains(error.requestOptions.method.toUpperCase())) {
      return false;
    }
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError =>
        true,
      DioExceptionType.badResponse =>
        (error.response?.statusCode ?? 0) >= 500,
      _ => false,
    };
  }
}
''';

  static const String headersInterceptor = r'''
import 'package:dio/dio.dart';

/// Adds headers that every request should carry.
///
/// [localeResolver] is supplied by the app layer so the data layer never has
/// to reach into the widget tree for the current locale.
class HeadersInterceptor extends Interceptor {
  const HeadersInterceptor({
    this.localeResolver,
    this.extraHeaders = const {},
  });

  final String Function()? localeResolver;
  final Map<String, String> extraHeaders;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final locale = localeResolver?.call();
    if (locale != null && locale.isNotEmpty) {
      options.headers['Accept-Language'] = locale;
    }
    options.headers.addAll(extraHeaders);
    handler.next(options);
  }
}
''';

  static const String authInterceptor = r'''
import 'package:dio/dio.dart';

import 'package:{{project_name}}/core/error/exceptions.dart';
import 'package:{{project_name}}/core/storage/secure_storage_service.dart';

/// Attaches the access token and refreshes it once on a 401.
///
/// Extends [QueuedInterceptor] so that parallel requests failing at the same
/// time trigger a single refresh instead of a stampede.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this.storage,
    required this.refreshDio,
    this.onSessionExpired,
  });

  final SecureStorageService storage;

  /// A bare Dio (no auth interceptor) used for the refresh call itself,
  /// otherwise a failing refresh would recurse.
  final Dio refreshDio;

  /// Called when the session cannot be recovered - sign the user out here.
  final Future<void> Function()? onSessionExpired;

  /// TODO: point this at your refresh endpoint.
  static const String refreshPath = '/auth/refresh';
  static const String _retriedKey = 'auth_retried';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['skip_auth'] != true) {
      final token = await storage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final alreadyRetried = err.requestOptions.extra[_retriedKey] == true;

    if (status != 401 || alreadyRetried) {
      return handler.next(err);
    }

    final refreshed = await _refresh();
    if (!refreshed) {
      await storage.clear();
      await onSessionExpired?.call();
      return handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          type: err.type,
          error: const UnauthorizedException(),
        ),
      );
    }

    try {
      final options = err.requestOptions..extra[_retriedKey] = true;
      final token = await storage.readAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.resolve(await refreshDio.fetch<dynamic>(options));
    } on DioException catch (error) {
      return handler.next(error);
    }
  }

  Future<bool> _refresh() async {
    final refreshToken = await storage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await refreshDio.post<Map<String, dynamic>>(
        refreshPath,
        data: {'refresh_token': refreshToken},
      );
      final data = response.data;
      final access = data?['access_token'] as String?;
      if (access == null || access.isEmpty) return false;

      await storage.writeAccessToken(access);
      final next = data?['refresh_token'] as String?;
      if (next != null && next.isNotEmpty) {
        await storage.writeRefreshToken(next);
      }
      return true;
    } on DioException {
      return false;
    }
  }
}
''';

  static const String apiEndpoints = r'''
/// Every path the app calls, in one place.
class ApiEndpoints {
  const ApiEndpoints._();

  static const String examples = '/posts';
  // clean_bloc:endpoints
}
''';

  static const String appRouter = r'''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

{{#use_example}}
import 'package:{{project_name}}/features/example/presentation/{{state_dir}}/example_{{state_dir}}.dart';
import 'package:{{project_name}}/features/example/presentation/pages/example_page.dart';
{{/use_example}}
import 'package:{{project_name}}/injection_container.dart';
// clean_bloc:imports

/// Routes own the blocs they need: each one is created from the service
/// locator when the route is entered and disposed when it is popped, so no
/// feature bloc outlives the screen that uses it.
class AppRouter {
  const AppRouter._();

  static final GoRouter router = GoRouter(
{{#use_example}}
    initialLocation: ExamplePage.routePath,
{{/use_example}}
{{^use_example}}
    initialLocation: '/',
{{/use_example}}
    debugLogDiagnostics: true,
    errorBuilder: (context, state) => RouteErrorPage(error: state.error),
    routes: [
{{#use_example}}
      GoRoute(
        path: ExamplePage.routePath,
        name: ExamplePage.routeName,
        builder: (context, state) => BlocProvider(
          create: (_) =>
{{#use_bloc}}
              sl<ExampleBloc>()..add(const LoadExamples()),
{{/use_bloc}}
{{#use_cubit}}
              sl<ExampleCubit>()..loadExamples(),
{{/use_cubit}}
          child: const ExamplePage(),
        ),
      ),
{{/use_example}}
      // clean_bloc:routes
    ],
  );
}

class RouteErrorPage extends StatelessWidget {
  const RouteErrorPage({required this.error, super.key});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            error?.toString() ?? 'That page does not exist.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
''';

  static const String appTheme = r'''
import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const Color seed = Color(0xFF2962FF);

  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: true,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
        ),
      ),
    );
  }
}
''';

  static const String appLogger = r'''
import 'package:logger/logger.dart';

/// Thin wrapper so the rest of the app never imports `package:logger`
/// directly - swapping the implementation stays a one file change.
class AppLogger {
  const AppLogger._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(methodCount: 0, errorMethodCount: 5),
  );

  static void debug(Object? message) => _logger.d(message);

  static void info(Object? message) => _logger.i(message);

  static void warning(Object? message) => _logger.w(message);

  static void error(Object? message, [Object? error, StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}
''';

  static const String blocObserver = r'''
import 'package:flutter_bloc/flutter_bloc.dart';
{{#use_logger}}

import 'package:{{project_name}}/core/utils/app_logger.dart';
{{/use_logger}}
{{^use_logger}}
import 'package:flutter/foundation.dart';
{{/use_logger}}

/// Single place to observe every bloc in the app: state changes, the events
/// that caused them, and unhandled errors.
class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    _log('${bloc.runtimeType} <- $event');
  }

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    _log(
      '${bloc.runtimeType} ${transition.currentState.runtimeType}'
      ' -> ${transition.nextState.runtimeType}',
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
{{#use_logger}}
    AppLogger.error('${bloc.runtimeType} failed', error, stackTrace);
{{/use_logger}}
{{^use_logger}}
    debugPrint('${bloc.runtimeType} failed: $error\n$stackTrace');
{{/use_logger}}
    super.onError(bloc, error, stackTrace);
  }

  void _log(String message) {
{{#use_logger}}
    AppLogger.debug(message);
{{/use_logger}}
{{^use_logger}}
    if (kDebugMode) debugPrint(message);
{{/use_logger}}
  }
}
''';

  static const String secureStorageService = r'''
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Typed access to the encrypted key/value store.
class SecureStorageService {
  const SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<void> writeAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> writeRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  Future<void> clear() => _storage.deleteAll();
}
''';

  static const String pushNotificationService = r'''
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Requests permission, wires the Firebase handlers and shows foreground
/// messages through a local notification channel.
class PushNotificationService {
  PushNotificationService();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High importance notifications',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    await _messaging.requestPermission();

    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    FirebaseMessaging.onMessage.listen(_showForeground);
  }

  Future<String?> get token => _messaging.getToken();

  Future<void> _showForeground(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          importance: Importance.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
''';

  static const String appConstants = r'''
class AppConstants {
  const AppConstants._();

  static const String appName = '{{display_name}}';
  static const String androidPackage = '{{android_package}}';
  static const String iosBundleId = '{{ios_bundle_id}}';
{{#use_network}}
  static const String fallbackBaseUrl = '{{base_url}}';
{{/use_network}}
{{#use_localization}}
  static const String defaultLocale = '{{default_locale}}';
{{/use_localization}}
}
''';

  static const String analysisOptions = r'''
include: package:flutter_lints/flutter.yaml

analyzer:
  errors:
    invalid_annotation_target: ignore
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"

linter:
  rules:
    - always_declare_return_types
    - avoid_print
    - prefer_const_constructors
    - prefer_final_locals
    - prefer_single_quotes
    - require_trailing_commas
    - unawaited_futures
''';

  static const String gitignore = r'''
# Flutter / Dart
.dart_tool/
.packages
build/
.flutter-plugins
.flutter-plugins-dependencies
pubspec.lock

# IDE
.idea/
.vscode/
*.iml

# Secrets
{{#use_env}}
.env
{{/use_env}}
android/key.properties
**/google-services.json
**/GoogleService-Info.plist

# OS
.DS_Store
''';

  static const String envExample = r'''
# Copy to `.env` (git ignored) and adjust per environment.
API_BASE_URL={{base_url}}
''';

  static const String translations = r'''
{
  "app": {
    "name": "{{display_name}}"
  },
  "common": {
    "retry": "Retry",
    "error": "Something went wrong",
    "loading": "Loading..."
  }
}
''';

  static const String readme = r'''
# {{display_name}}

{{description}}

Generated with the **clean_bloc** generator: Clean Architecture + BLoC,
feature-first structure.

| Setting | Value |
| --- | --- |
| Package name | `{{project_name}}` |
| Android applicationId | `{{android_package}}` |
| iOS bundle id | `{{ios_bundle_id}}` |
| State management | `{{state_dir}}` |
{{#use_localization}}
| Locales | {{default_locale}} (default) |
{{/use_localization}}

## Getting started

```bash
flutter pub get
{{#use_env}}
cp .env.example .env
{{/use_env}}
flutter run
```

## Structure

```
lib
├── app.dart                 # MaterialApp + global BlocProviders
├── main.dart                # bootstrap
├── injection_container.dart # get_it registrations
├── core                     # shared infrastructure
│   ├── error                # Failure / Exception types
{{#use_network}}
│   ├── network              # Dio client{{#use_connectivity}} + connectivity{{/use_connectivity}}
{{/use_network}}
{{#use_routing}}
│   ├── router               # go_router configuration
{{/use_routing}}
{{#use_theming}}
│   ├── theme                # light / dark themes
{{/use_theming}}
│   └── usecases             # UseCase contract
└── features
    └── <feature>
        ├── data             # models, data sources, repository impl
        ├── domain           # entities, repository contract, use cases
        └── presentation     # {{state_dir}}, pages, widgets
```

## Adding a feature

`clean_bloc.yaml` records how this project was generated, so the generator can
keep new slices consistent with it. Install the generator once:

```bash
dart pub global activate --source path <path-to-clean_bloc_gen>
```

Then, from this project's root:

```bash
clean_bloc feature <name>
```

It writes the whole slice - entity, repository, use case, model, data sources,
{{state_dir}}, page, widget and test - and wires it into
`injection_container.dart`{{#use_routing}}, `core/router/app_router.dart`{{/use_routing}}
and `app.dart`. Re-running is safe: existing files are skipped and no
registration is inserted twice.

## Native identifiers

Android and iOS identifiers are already set to the values above. To change them
later:

```bash
clean_bloc rename --android-package com.acme.app \
  --ios-bundle-id com.acme.app --display-name "Acme"
```
''';
}
