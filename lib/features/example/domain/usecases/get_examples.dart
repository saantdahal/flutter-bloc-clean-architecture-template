import 'package:dartz/dartz.dart';

import 'package:flutter_bloc_clean_architecture_template/core/error/failures.dart';
import 'package:flutter_bloc_clean_architecture_template/core/usecases/usecase.dart';
import 'package:flutter_bloc_clean_architecture_template/features/example/domain/entities/example_entity.dart';
import 'package:flutter_bloc_clean_architecture_template/features/example/domain/repositories/example_repository.dart';

class GetExamples implements UseCase<List<ExampleEntity>, NoParams> {
  final ExampleRepository repository;

  GetExamples(this.repository);

  @override
  Future<Either<Failure, List<ExampleEntity>>> call(NoParams params) async {
    return await repository.getExamples();
  }
}
