import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import 'core/network/network_info.dart';
import 'core/network/network_info_impl.dart';
import 'data/datasources/example_remote_datasource.dart';
import 'data/datasources/example_remote_datasource_impl.dart';
import 'data/repositories/example_repository_impl.dart';
import 'domain/repositories/example_repository.dart';
import 'domain/usecases/get_examples.dart';
import 'presentation/blocs/example_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Bloc
  sl.registerFactory(() => ExampleBloc(getExamples: sl()));

  // Use cases
  sl.registerLazySingleton(() => GetExamples(sl()));

  // Repository
  sl.registerLazySingleton<ExampleRepository>(
    () => ExampleRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Data sources
  sl.registerLazySingleton<ExampleRemoteDataSource>(
    () => ExampleRemoteDataSourceImpl(dio: sl()),
  );

  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // External
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => InternetConnectionChecker());
}
