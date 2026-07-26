import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc_clean_architecture_template/core/error/failures.dart';
import 'package:flutter_bloc_clean_architecture_template/core/network/network_info.dart';
import '../../domain/entities/example_entity.dart';
import '../../domain/repositories/example_repository.dart';
import '../datasources/example_remote_datasource.dart';

class ExampleRepositoryImpl implements ExampleRepository {
  final ExampleRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ExampleRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<ExampleEntity>>> getExamples() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteExamples = await remoteDataSource.getExamples();
        return Right(remoteExamples);
      } on DioException catch (e) {
        return Left(
          ServerFailure(
            message: e.message ?? 'Failed to load examples from server.',
          ),
        );
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}
