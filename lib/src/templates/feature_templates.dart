/// Templates for a single Clean Architecture feature slice.
///
/// Every string is a raw Dart string so that generated code may contain `$`
/// interpolation without escaping.
class FeatureTemplates {
  const FeatureTemplates._();

  static const String entity = r'''
import 'package:equatable/equatable.dart';

/// Domain entity - framework free, the shape the app reasons about.
class {{feature_pascal}}Entity extends Equatable {
  const {{feature_pascal}}Entity({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
''';

  static const String repositoryContract = r'''
import 'package:dartz/dartz.dart';

import 'package:{{project_name}}/core/error/failures.dart';
import 'package:{{project_name}}/features/{{feature_name}}/domain/entities/{{feature_name}}_entity.dart';

abstract class {{feature_pascal}}Repository {
  Future<Either<Failure, List<{{feature_pascal}}Entity>>> get{{feature_plural_pascal}}();
}
''';

  static const String useCase = r'''
import 'package:dartz/dartz.dart';

import 'package:{{project_name}}/core/error/failures.dart';
import 'package:{{project_name}}/core/usecases/usecase.dart';
import 'package:{{project_name}}/features/{{feature_name}}/domain/entities/{{feature_name}}_entity.dart';
import 'package:{{project_name}}/features/{{feature_name}}/domain/repositories/{{feature_name}}_repository.dart';

class Get{{feature_plural_pascal}}
    implements UseCase<List<{{feature_pascal}}Entity>, NoParams> {
  const Get{{feature_plural_pascal}}(this.repository);

  final {{feature_pascal}}Repository repository;

  @override
  Future<Either<Failure, List<{{feature_pascal}}Entity>>> call(
    NoParams params,
  ) {
    return repository.get{{feature_plural_pascal}}();
  }
}
''';

  static const String model = r'''
import 'package:{{project_name}}/features/{{feature_name}}/domain/entities/{{feature_name}}_entity.dart';

/// Data transfer object for [{{feature_pascal}}Entity].
class {{feature_pascal}}Model extends {{feature_pascal}}Entity {
  const {{feature_pascal}}Model({required super.id, required super.name});

  factory {{feature_pascal}}Model.fromJson(Map<String, dynamic> json) {
    return {{feature_pascal}}Model(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? json['title'] ?? '').toString(),
    );
  }

  factory {{feature_pascal}}Model.fromEntity({{feature_pascal}}Entity entity) {
    return {{feature_pascal}}Model(id: entity.id, name: entity.name);
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
''';

  static const String remoteDataSource = r'''
import 'package:{{project_name}}/features/{{feature_name}}/data/models/{{feature_name}}_model.dart';

abstract class {{feature_pascal}}RemoteDataSource {
  /// Throws a [ServerException] when the call fails.
  Future<List<{{feature_pascal}}Model>> get{{feature_plural_pascal}}();
}
''';

  static const String remoteDataSourceImpl = r'''
import 'package:dio/dio.dart';

import 'package:{{project_name}}/core/error/exceptions.dart';
import 'package:{{project_name}}/core/network/interceptors/error_interceptor.dart';
import 'package:{{project_name}}/features/{{feature_name}}/data/datasources/{{feature_name}}_remote_data_source.dart';
import 'package:{{project_name}}/features/{{feature_name}}/data/models/{{feature_name}}_model.dart';

class {{feature_pascal}}RemoteDataSourceImpl
    implements {{feature_pascal}}RemoteDataSource {
  const {{feature_pascal}}RemoteDataSourceImpl({required this.dio});

  final Dio dio;

  /// TODO: move this to ApiEndpoints once the real path is known.
  static const String endpoint = '/{{feature_plural}}';

  @override
  Future<List<{{feature_pascal}}Model>> get{{feature_plural_pascal}}() async {
    try {
      final response = await dio.get<dynamic>(endpoint);
      final data = response.data;
      if (data is! List) {
        throw const ServerException('Unexpected response shape.');
      }
      return data
          .whereType<Map<String, dynamic>>()
          .map({{feature_pascal}}Model.fromJson)
          .toList();
    } on DioException catch (error) {
      // The error interceptor has already classified this.
      throw ErrorInterceptor.toAppException(error);
    }
  }
}
''';

  static const String localDataSource = r'''
import 'package:{{project_name}}/features/{{feature_name}}/data/models/{{feature_name}}_model.dart';

abstract class {{feature_pascal}}LocalDataSource {
  /// Throws a [CacheException] when nothing is cached.
  Future<List<{{feature_pascal}}Model>> getCached{{feature_plural_pascal}}();

  Future<void> cache{{feature_plural_pascal}}(
    List<{{feature_pascal}}Model> {{feature_plural_camel}},
  );
}
''';

  static const String localDataSourceImpl = r'''
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:{{project_name}}/core/error/exceptions.dart';
import 'package:{{project_name}}/features/{{feature_name}}/data/datasources/{{feature_name}}_local_data_source.dart';
import 'package:{{project_name}}/features/{{feature_name}}/data/models/{{feature_name}}_model.dart';

class {{feature_pascal}}LocalDataSourceImpl
    implements {{feature_pascal}}LocalDataSource {
  const {{feature_pascal}}LocalDataSourceImpl({required this.preferences});

  final SharedPreferences preferences;

  static const String cacheKey = 'cached_{{feature_plural}}';

  @override
  Future<List<{{feature_pascal}}Model>> getCached{{feature_plural_pascal}}() async {
    final raw = preferences.getString(cacheKey);
    if (raw == null) {
      throw const CacheException('No cached {{feature_plural}} available.');
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map({{feature_pascal}}Model.fromJson)
          .toList();
    } on FormatException {
      await preferences.remove(cacheKey);
      throw const CacheException('Cached {{feature_plural}} were corrupted.');
    }
  }

  @override
  Future<void> cache{{feature_plural_pascal}}(
    List<{{feature_pascal}}Model> {{feature_plural_camel}},
  ) async {
    final encoded = jsonEncode(
      {{feature_plural_camel}}.map((item) => item.toJson()).toList(),
    );
    await preferences.setString(cacheKey, encoded);
  }
}
''';

  static const String repositoryImpl = r'''
import 'package:dartz/dartz.dart';

{{#has_repo_deps}}
import 'package:{{project_name}}/core/error/exceptions.dart';
{{/has_repo_deps}}
import 'package:{{project_name}}/core/error/failures.dart';
{{#use_connectivity}}
import 'package:{{project_name}}/core/network/network_info.dart';
{{/use_connectivity}}
{{#use_local}}
import 'package:{{project_name}}/features/{{feature_name}}/data/datasources/{{feature_name}}_local_data_source.dart';
{{/use_local}}
{{#use_remote}}
import 'package:{{project_name}}/features/{{feature_name}}/data/datasources/{{feature_name}}_remote_data_source.dart';
{{/use_remote}}
{{^use_remote}}
import 'package:{{project_name}}/features/{{feature_name}}/data/models/{{feature_name}}_model.dart';
{{/use_remote}}
import 'package:{{project_name}}/features/{{feature_name}}/domain/entities/{{feature_name}}_entity.dart';
import 'package:{{project_name}}/features/{{feature_name}}/domain/repositories/{{feature_name}}_repository.dart';

/// The only place that knows about both the data sources and the domain.
/// Exceptions stop here: everything above sees `Either<Failure, T>`.
class {{feature_pascal}}RepositoryImpl implements {{feature_pascal}}Repository {
{{#has_repo_deps}}
  const {{feature_pascal}}RepositoryImpl({
{{#use_remote}}
    required this.remoteDataSource,
{{/use_remote}}
{{#use_local}}
    required this.localDataSource,
{{/use_local}}
{{#use_connectivity}}
    required this.networkInfo,
{{/use_connectivity}}
  });
{{/has_repo_deps}}
{{^has_repo_deps}}
  const {{feature_pascal}}RepositoryImpl();
{{/has_repo_deps}}

{{#use_remote}}
  final {{feature_pascal}}RemoteDataSource remoteDataSource;
{{/use_remote}}
{{#use_local}}
  final {{feature_pascal}}LocalDataSource localDataSource;
{{/use_local}}
{{#use_connectivity}}
  final NetworkInfo networkInfo;
{{/use_connectivity}}

  @override
  Future<Either<Failure, List<{{feature_pascal}}Entity>>>
      get{{feature_plural_pascal}}() async {
{{#use_remote}}
{{#use_connectivity}}
    if (!await networkInfo.isConnected) {
{{#use_local}}
      // Offline: serve whatever was cached on the last successful load.
      return _readCache(fallback: const NetworkFailure());
{{/use_local}}
{{^use_local}}
      return const Left(NetworkFailure());
{{/use_local}}
    }

{{/use_connectivity}}
    try {
      final remote = await remoteDataSource.get{{feature_plural_pascal}}();
{{#use_local}}
      await localDataSource.cache{{feature_plural_pascal}}(remote);
{{/use_local}}
      return Right(remote);
    } on AppException catch (error) {
{{#use_local}}
      return _readCache(fallback: Failure.from(error));
{{/use_local}}
{{^use_local}}
      return Left(Failure.from(error));
{{/use_local}}
    } catch (error) {
      return Left(UnknownFailure(error.toString()));
    }
{{/use_remote}}
{{^use_remote}}
{{#use_local}}
    return _readCache(fallback: const CacheFailure());
{{/use_local}}
{{^use_local}}
    // No data source is configured yet - return the seed data.
    return const Right([
      {{feature_pascal}}Model(id: '1', name: '{{feature_title}} 1'),
      {{feature_pascal}}Model(id: '2', name: '{{feature_title}} 2'),
    ]);
{{/use_local}}
{{/use_remote}}
  }
{{#use_local}}

  /// Reads the cache, reporting [fallback] when there is nothing to read.
  Future<Either<Failure, List<{{feature_pascal}}Entity>>> _readCache({
    required Failure fallback,
  }) async {
    try {
      return Right(await localDataSource.getCached{{feature_plural_pascal}}());
    } on AppException {
      return Left(fallback);
    }
  }
{{/use_local}}
}
''';

  static const String bloc = r'''
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:{{project_name}}/core/error/failures.dart';
import 'package:{{project_name}}/core/usecases/usecase.dart';
import 'package:{{project_name}}/features/{{feature_name}}/domain/entities/{{feature_name}}_entity.dart';
import 'package:{{project_name}}/features/{{feature_name}}/domain/usecases/get_{{feature_plural}}.dart';

part '{{feature_name}}_event.dart';
part '{{feature_name}}_state.dart';

/// Presentation logic only: it turns events into states by calling use cases.
/// It knows nothing about Dio, caches or the widget tree.
class {{feature_pascal}}Bloc
    extends Bloc<{{feature_pascal}}Event, {{feature_pascal}}State> {
  {{feature_pascal}}Bloc({required this.get{{feature_plural_pascal}}})
      : super(const {{feature_pascal}}Initial()) {
    // droppable: while a load is in flight, further taps are ignored.
    on<Load{{feature_plural_pascal}}>(
      _onLoad{{feature_plural_pascal}},
      transformer: droppable(),
    );
    // restartable: a pull-to-refresh supersedes the one before it.
    on<Refresh{{feature_plural_pascal}}>(
      _onRefresh{{feature_plural_pascal}},
      transformer: restartable(),
    );
  }

  final Get{{feature_plural_pascal}} get{{feature_plural_pascal}};

  Future<void> _onLoad{{feature_plural_pascal}}(
    Load{{feature_plural_pascal}} event,
    Emitter<{{feature_pascal}}State> emit,
  ) async {
    emit(const {{feature_pascal}}Loading());
    await _fetch(emit);
  }

  Future<void> _onRefresh{{feature_plural_pascal}}(
    Refresh{{feature_plural_pascal}} event,
    Emitter<{{feature_pascal}}State> emit,
  ) async {
    // Keep the current list on screen while refreshing underneath it.
    await _fetch(emit);
  }

  Future<void> _fetch(Emitter<{{feature_pascal}}State> emit) async {
    final result = await get{{feature_plural_pascal}}(const NoParams());
    result.fold(
      (failure) => emit({{feature_pascal}}Error(failure)),
      ({{feature_plural_camel}}) =>
          emit({{feature_pascal}}Loaded({{feature_plural_camel}})),
    );
  }
}
''';

  static const String blocEvent = r'''
part of '{{feature_name}}_bloc.dart';

sealed class {{feature_pascal}}Event extends Equatable {
  const {{feature_pascal}}Event();

  @override
  List<Object?> get props => [];
}

/// Initial load - shows the spinner.
class Load{{feature_plural_pascal}} extends {{feature_pascal}}Event {
  const Load{{feature_plural_pascal}}();
}

/// Re-fetch without clearing what is already on screen.
class Refresh{{feature_plural_pascal}} extends {{feature_pascal}}Event {
  const Refresh{{feature_plural_pascal}}();
}
''';

  static const String blocState = r'''
part of '{{feature_name}}_bloc.dart';

sealed class {{feature_pascal}}State extends Equatable {
  const {{feature_pascal}}State();

  @override
  List<Object?> get props => [];
}

class {{feature_pascal}}Initial extends {{feature_pascal}}State {
  const {{feature_pascal}}Initial();
}

class {{feature_pascal}}Loading extends {{feature_pascal}}State {
  const {{feature_pascal}}Loading();
}

class {{feature_pascal}}Loaded extends {{feature_pascal}}State {
  const {{feature_pascal}}Loaded(this.{{feature_plural_camel}});

  final List<{{feature_pascal}}Entity> {{feature_plural_camel}};

  bool get isEmpty => {{feature_plural_camel}}.isEmpty;

  @override
  List<Object?> get props => [{{feature_plural_camel}}];
}

class {{feature_pascal}}Error extends {{feature_pascal}}State {
  const {{feature_pascal}}Error(this.failure);

  final Failure failure;

  String get message => failure.message;

  @override
  List<Object?> get props => [failure];
}
''';

  static const String cubit = r'''
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:{{project_name}}/core/error/failures.dart';
import 'package:{{project_name}}/core/usecases/usecase.dart';
import 'package:{{project_name}}/features/{{feature_name}}/domain/entities/{{feature_name}}_entity.dart';
import 'package:{{project_name}}/features/{{feature_name}}/domain/usecases/get_{{feature_plural}}.dart';

part '{{feature_name}}_state.dart';

class {{feature_pascal}}Cubit extends Cubit<{{feature_pascal}}State> {
  {{feature_pascal}}Cubit({required this.get{{feature_plural_pascal}}})
      : super(const {{feature_pascal}}State());

  final Get{{feature_plural_pascal}} get{{feature_plural_pascal}};

  Future<void> load{{feature_plural_pascal}}() async {
    if (state.status == {{feature_pascal}}Status.loading) return;
    emit(state.copyWith(status: {{feature_pascal}}Status.loading));
    await _fetch();
  }

  /// Re-fetch without clearing what is already on screen.
  Future<void> refresh{{feature_plural_pascal}}() => _fetch();

  Future<void> _fetch() async {
    final result = await get{{feature_plural_pascal}}(const NoParams());
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: {{feature_pascal}}Status.failure,
          failure: failure,
        ),
      ),
      ({{feature_plural_camel}}) => emit(
        state.copyWith(
          status: {{feature_pascal}}Status.success,
          {{feature_plural_camel}}: {{feature_plural_camel}},
        ),
      ),
    );
  }
}
''';

  static const String cubitState = r'''
part of '{{feature_name}}_cubit.dart';

enum {{feature_pascal}}Status { initial, loading, success, failure }

class {{feature_pascal}}State extends Equatable {
  const {{feature_pascal}}State({
    this.status = {{feature_pascal}}Status.initial,
    this.{{feature_plural_camel}} = const [],
    this.failure,
  });

  final {{feature_pascal}}Status status;
  final List<{{feature_pascal}}Entity> {{feature_plural_camel}};
  final Failure? failure;

  String get message => failure?.message ?? '';

  {{feature_pascal}}State copyWith({
    {{feature_pascal}}Status? status,
    List<{{feature_pascal}}Entity>? {{feature_plural_camel}},
    Failure? failure,
  }) {
    return {{feature_pascal}}State(
      status: status ?? this.status,
      {{feature_plural_camel}}:
          {{feature_plural_camel}} ?? this.{{feature_plural_camel}},
      failure: failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [status, {{feature_plural_camel}}, failure];
}
''';

  static const String page = r'''
{{#use_localization}}
import 'package:easy_localization/easy_localization.dart';
{{/use_localization}}
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:{{project_name}}/features/{{feature_name}}/presentation/{{state_dir}}/{{feature_name}}_{{state_dir}}.dart';
import 'package:{{project_name}}/features/{{feature_name}}/presentation/widgets/{{feature_name}}_list_item.dart';

/// The {{state_suffix}} is provided by the route (see AppRouter), so this page
/// only reads state and dispatches {{#use_bloc}}events{{/use_bloc}}{{#use_cubit}}intents{{/use_cubit}}.
class {{feature_pascal}}Page extends StatelessWidget {
  const {{feature_pascal}}Page({super.key});

  static const String routeName = '{{feature_name}}';
  static const String routePath = '/{{feature_name}}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
{{#use_localization}}
        title: Text('{{feature_name}}.title'.tr()),
{{/use_localization}}
{{^use_localization}}
        title: const Text('{{feature_title}}'),
{{/use_localization}}
      ),
      body: const {{feature_pascal}}View(),
    );
  }
}

class {{feature_pascal}}View extends StatelessWidget {
  const {{feature_pascal}}View({super.key});

  Future<void> _refresh(BuildContext context) async {
{{#use_bloc}}
    context
        .read<{{feature_pascal}}Bloc>()
        .add(const Refresh{{feature_plural_pascal}}());
{{/use_bloc}}
{{#use_cubit}}
    await context
        .read<{{feature_pascal}}Cubit>()
        .refresh{{feature_plural_pascal}}();
{{/use_cubit}}
  }

  void _retry(BuildContext context) {
{{#use_bloc}}
    context
        .read<{{feature_pascal}}Bloc>()
        .add(const Load{{feature_plural_pascal}}());
{{/use_bloc}}
{{#use_cubit}}
    context.read<{{feature_pascal}}Cubit>().load{{feature_plural_pascal}}();
{{/use_cubit}}
  }

  @override
  Widget build(BuildContext context) {
{{#use_bloc}}
    return BlocConsumer<{{feature_pascal}}Bloc, {{feature_pascal}}State>(
      // Surface a refresh failure without wiping the list that is showing.
      listenWhen: (previous, current) =>
          current is {{feature_pascal}}Error &&
          previous is {{feature_pascal}}Loaded,
      listener: (context, state) {
        if (state is {{feature_pascal}}Error) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        return switch (state) {
          {{feature_pascal}}Initial() ||
          {{feature_pascal}}Loading() =>
            const Center(child: CircularProgressIndicator()),
          {{feature_pascal}}Error(:final message) => _ErrorView(
              message: message,
              onRetry: () => _retry(context),
            ),
          {{feature_pascal}}Loaded(:final {{feature_plural_camel}}) =>
            {{feature_plural_camel}}.isEmpty
                ? _EmptyView(onRefresh: () => _refresh(context))
                : RefreshIndicator(
                    onRefresh: () => _refresh(context),
                    child: ListView.builder(
                      itemCount: {{feature_plural_camel}}.length,
                      itemBuilder: (context, index) => {{feature_pascal}}ListItem(
                        {{feature_camel}}: {{feature_plural_camel}}[index],
                      ),
                    ),
                  ),
        };
      },
    );
{{/use_bloc}}
{{#use_cubit}}
    return BlocConsumer<{{feature_pascal}}Cubit, {{feature_pascal}}State>(
      listenWhen: (previous, current) =>
          current.status == {{feature_pascal}}Status.failure &&
          current.{{feature_plural_camel}}.isNotEmpty,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.message)));
      },
      builder: (context, state) {
        return switch (state.status) {
          {{feature_pascal}}Status.initial ||
          {{feature_pascal}}Status.loading =>
            const Center(child: CircularProgressIndicator()),
          {{feature_pascal}}Status.failure => _ErrorView(
              message: state.message,
              onRetry: () => _retry(context),
            ),
          {{feature_pascal}}Status.success =>
            state.{{feature_plural_camel}}.isEmpty
                ? _EmptyView(onRefresh: () => _refresh(context))
                : RefreshIndicator(
                    onRefresh: () => _refresh(context),
                    child: ListView.builder(
                      itemCount: state.{{feature_plural_camel}}.length,
                      itemBuilder: (context, index) => {{feature_pascal}}ListItem(
                        {{feature_camel}}: state.{{feature_plural_camel}}[index],
                      ),
                    ),
                  ),
        };
      },
    );
{{/use_cubit}}
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
{{#use_localization}}
              child: Text('common.retry'.tr()),
{{/use_localization}}
{{^use_localization}}
              child: const Text('Retry'),
{{/use_localization}}
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.3),
{{#use_localization}}
          Center(child: Text('{{feature_name}}.empty'.tr())),
{{/use_localization}}
{{^use_localization}}
          const Center(child: Text('No {{feature_plural}} yet.')),
{{/use_localization}}
        ],
      ),
    );
  }
}
''';

  static const String listItem = r'''
import 'package:flutter/material.dart';

import 'package:{{project_name}}/features/{{feature_name}}/domain/entities/{{feature_name}}_entity.dart';

class {{feature_pascal}}ListItem extends StatelessWidget {
  const {{feature_pascal}}ListItem({required this.{{feature_camel}}, super.key});

  final {{feature_pascal}}Entity {{feature_camel}};

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Text({{feature_camel}}.id)),
      title: Text({{feature_camel}}.name),
    );
  }
}
''';

  static const String blocTest = r'''
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:{{project_name}}/core/error/failures.dart';
import 'package:{{project_name}}/features/{{feature_name}}/domain/entities/{{feature_name}}_entity.dart';
import 'package:{{project_name}}/features/{{feature_name}}/domain/repositories/{{feature_name}}_repository.dart';
import 'package:{{project_name}}/features/{{feature_name}}/domain/usecases/get_{{feature_plural}}.dart';
import 'package:{{project_name}}/features/{{feature_name}}/presentation/{{state_dir}}/{{feature_name}}_{{state_dir}}.dart';

class _Fake{{feature_pascal}}Repository implements {{feature_pascal}}Repository {
  const _Fake{{feature_pascal}}Repository(this._result);

  final Either<Failure, List<{{feature_pascal}}Entity>> _result;

  @override
  Future<Either<Failure, List<{{feature_pascal}}Entity>>>
      get{{feature_plural_pascal}}() async => _result;
}

void main() {
  const items = [{{feature_pascal}}Entity(id: '1', name: '{{feature_title}} 1')];
  const failure = ServerFailure('boom');

  {{feature_pascal}}{{state_suffix}} build(
    Either<Failure, List<{{feature_pascal}}Entity>> result,
  ) {
    return {{feature_pascal}}{{state_suffix}}(
      get{{feature_plural_pascal}}: Get{{feature_plural_pascal}}(
        _Fake{{feature_pascal}}Repository(result),
      ),
    );
  }

  group('{{feature_pascal}}{{state_suffix}}', () {
{{#use_bloc}}
    test('starts in {{feature_pascal}}Initial', () async {
      final subject = build(const Right(items));
      expect(subject.state, isA<{{feature_pascal}}Initial>());
      await subject.close();
    });

    test('emits loading then loaded on success', () async {
      final subject = build(const Right(items));
      final expectation = expectLater(
        subject.stream,
        emitsInOrder([
          isA<{{feature_pascal}}Loading>(),
          isA<{{feature_pascal}}Loaded>().having(
            (state) => state.{{feature_plural_camel}},
            '{{feature_plural_camel}}',
            items,
          ),
        ]),
      );

      subject.add(const Load{{feature_plural_pascal}}());
      await expectation;
      await subject.close();
    });

    test('emits loading then error carrying the failure', () async {
      final subject = build(const Left(failure));
      final expectation = expectLater(
        subject.stream,
        emitsInOrder([
          isA<{{feature_pascal}}Loading>(),
          isA<{{feature_pascal}}Error>()
              .having((state) => state.failure, 'failure', failure)
              .having((state) => state.message, 'message', 'boom'),
        ]),
      );

      subject.add(const Load{{feature_plural_pascal}}());
      await expectation;
      await subject.close();
    });

    test('refresh emits loaded without a loading state', () async {
      final subject = build(const Right(items));
      final expectation = expectLater(
        subject.stream,
        emitsInOrder([isA<{{feature_pascal}}Loaded>()]),
      );

      subject.add(const Refresh{{feature_plural_pascal}}());
      await expectation;
      await subject.close();
    });
{{/use_bloc}}
{{#use_cubit}}
    test('starts in the initial status', () async {
      final subject = build(const Right(items));
      expect(subject.state.status, {{feature_pascal}}Status.initial);
      await subject.close();
    });

    test('emits loading then success', () async {
      final subject = build(const Right(items));
      final expectation = expectLater(
        subject.stream,
        emitsInOrder([
          isA<{{feature_pascal}}State>().having(
            (state) => state.status,
            'status',
            {{feature_pascal}}Status.loading,
          ),
          isA<{{feature_pascal}}State>().having(
            (state) => state.{{feature_plural_camel}},
            '{{feature_plural_camel}}',
            items,
          ),
        ]),
      );

      await subject.load{{feature_plural_pascal}}();
      await expectation;
      await subject.close();
    });

    test('carries the failure through to the state', () async {
      final subject = build(const Left(failure));
      await subject.load{{feature_plural_pascal}}();

      expect(subject.state.status, {{feature_pascal}}Status.failure);
      expect(subject.state.failure, failure);
      expect(subject.state.message, 'boom');
      await subject.close();
    });
{{/use_cubit}}
  });
}
''';
}

/// Snippets inserted into existing files when wiring a feature up.
class FeatureWiring {
  const FeatureWiring._();

  static const String imports = r'''
{{#use_remote}}
import 'package:{{project_name}}/features/{{feature_name}}/data/datasources/{{feature_name}}_remote_data_source.dart';
import 'package:{{project_name}}/features/{{feature_name}}/data/datasources/{{feature_name}}_remote_data_source_impl.dart';
{{/use_remote}}
{{#use_local}}
import 'package:{{project_name}}/features/{{feature_name}}/data/datasources/{{feature_name}}_local_data_source.dart';
import 'package:{{project_name}}/features/{{feature_name}}/data/datasources/{{feature_name}}_local_data_source_impl.dart';
{{/use_local}}
import 'package:{{project_name}}/features/{{feature_name}}/data/repositories/{{feature_name}}_repository_impl.dart';
import 'package:{{project_name}}/features/{{feature_name}}/domain/repositories/{{feature_name}}_repository.dart';
import 'package:{{project_name}}/features/{{feature_name}}/domain/usecases/get_{{feature_plural}}.dart';
import 'package:{{project_name}}/features/{{feature_name}}/presentation/{{state_dir}}/{{feature_name}}_{{state_dir}}.dart';
''';

  static const String registrations = r'''

// {{feature_title}} feature
sl.registerFactory(
  () => {{feature_pascal}}{{state_suffix}}(get{{feature_plural_pascal}}: sl()),
);
sl.registerLazySingleton(() => Get{{feature_plural_pascal}}(sl()));
sl.registerLazySingleton<{{feature_pascal}}Repository>(
{{#has_repo_deps}}
  () => {{feature_pascal}}RepositoryImpl(
{{#use_remote}}
    remoteDataSource: sl(),
{{/use_remote}}
{{#use_local}}
    localDataSource: sl(),
{{/use_local}}
{{#use_connectivity}}
    networkInfo: sl(),
{{/use_connectivity}}
  ),
{{/has_repo_deps}}
{{^has_repo_deps}}
  () => const {{feature_pascal}}RepositoryImpl(),
{{/has_repo_deps}}
);
{{#use_remote}}
sl.registerLazySingleton<{{feature_pascal}}RemoteDataSource>(
  () => {{feature_pascal}}RemoteDataSourceImpl(dio: sl()),
);
{{/use_remote}}
{{#use_local}}
sl.registerLazySingleton<{{feature_pascal}}LocalDataSource>(
  () => {{feature_pascal}}LocalDataSourceImpl(preferences: sl()),
);
{{/use_local}}
''';

  static const String providerImport = r'''
import 'package:{{project_name}}/features/{{feature_name}}/presentation/{{state_dir}}/{{feature_name}}_{{state_dir}}.dart';
''';

  static const String serviceLocatorImport = r'''
import 'package:{{project_name}}/injection_container.dart';
''';

  static const String provider = r'''
BlocProvider(
  create: (_) =>
{{#use_bloc}}
      sl<{{feature_pascal}}Bloc>()..add(const Load{{feature_plural_pascal}}()),
{{/use_bloc}}
{{#use_cubit}}
      sl<{{feature_pascal}}Cubit>()..load{{feature_plural_pascal}}(),
{{/use_cubit}}
),
''';

  static const String routeImport = r'''
import 'package:{{project_name}}/features/{{feature_name}}/presentation/{{state_dir}}/{{feature_name}}_{{state_dir}}.dart';
import 'package:{{project_name}}/features/{{feature_name}}/presentation/pages/{{feature_name}}_page.dart';
''';

  static const String route = r'''
GoRoute(
  path: {{feature_pascal}}Page.routePath,
  name: {{feature_pascal}}Page.routeName,
  builder: (context, state) => BlocProvider(
    create: (_) =>
{{#use_bloc}}
        sl<{{feature_pascal}}Bloc>()..add(const Load{{feature_plural_pascal}}()),
{{/use_bloc}}
{{#use_cubit}}
        sl<{{feature_pascal}}Cubit>()..load{{feature_plural_pascal}}(),
{{/use_cubit}}
    child: const {{feature_pascal}}Page(),
  ),
),
''';

  static const String translationKeys = r'''
  "{{feature_name}}": {
    "title": "{{feature_title}}",
    "empty": "Tap refresh to load {{feature_plural}}."
  },
''';
}
