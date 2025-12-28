import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/example_entity.dart';
import '../repositories/example_repository.dart';

class GetExamples implements UseCase<List<ExampleEntity>, NoParams> {
  final ExampleRepository repository;

  GetExamples(this.repository);

  @override
  Future<Either<Failure, List<ExampleEntity>>> call(NoParams params) async {
    return await repository.getExamples();
  }
}
