import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/example_entity.dart';

abstract class ExampleRepository {
  Future<Either<Failure, List<ExampleEntity>>> getExamples();
}
