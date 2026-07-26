import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_bloc_clean_architecture_template/features/example/data/datasources/example_remote_datasource.dart';
import 'package:flutter_bloc_clean_architecture_template/features/example/data/datasources/example_remote_datasource_impl.dart';
import 'package:flutter_bloc_clean_architecture_template/features/example/data/repositories/example_repository_impl.dart';
import 'package:flutter_bloc_clean_architecture_template/features/example/domain/repositories/example_repository.dart';
import 'package:flutter_bloc_clean_architecture_template/features/example/domain/usecases/get_examples.dart';
import 'package:flutter_bloc_clean_architecture_template/features/example/presentation/blocs/example_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'core/network/network_info.dart';
import 'core/network/network_info_impl.dart';

final sl = GetIt.instance;

Future<void> init() async {
  sl.registerFactory(() => ExampleBloc(getExamples: sl()));

  sl.registerLazySingleton(() => GetExamples(sl()));

  sl.registerLazySingleton<ExampleRepository>(
    () => ExampleRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  sl.registerLazySingleton<ExampleRemoteDataSource>(
    () => ExampleRemoteDataSourceImpl(dio: sl()),
  );

  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  sl.registerLazySingleton(() {
    final dio = Dio(
      BaseOptions(baseUrl: dotenv.env['API_BASE_URL'] ?? ''),
    );
    dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
      ),
    );
    return dio;
  });
  sl.registerLazySingleton(() => InternetConnectionChecker());
}
