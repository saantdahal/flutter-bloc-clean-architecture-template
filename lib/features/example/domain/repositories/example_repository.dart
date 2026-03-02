import 'package:dartz/dartz.dart';

import 'package:flutter_bloc_clean_architecture_template/core/error/failures.dart';
import 'package:flutter_bloc_clean_architecture_template/features/example/domain/entities/example_entity.dart';

abstract class ExampleRepository {
  Future<Either<Failure, List<ExampleEntity>>> getExamples();
}
