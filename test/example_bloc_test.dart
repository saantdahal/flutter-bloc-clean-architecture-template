import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_bloc_clean_architecture_template/core/error/failures.dart';
import 'package:flutter_bloc_clean_architecture_template/features/example/domain/entities/example_entity.dart';
import 'package:flutter_bloc_clean_architecture_template/features/example/domain/repositories/example_repository.dart';
import 'package:flutter_bloc_clean_architecture_template/features/example/domain/usecases/get_examples.dart';
import 'package:flutter_bloc_clean_architecture_template/features/example/presentation/blocs/example_bloc.dart';

class _FakeExampleRepository implements ExampleRepository {
  _FakeExampleRepository(this._result);

  final Either<Failure, List<ExampleEntity>> _result;

  @override
  Future<Either<Failure, List<ExampleEntity>>> getExamples() async => _result;
}

void main() {
  const tExamples = [ExampleEntity(id: '1', name: 'Example 1')];

  group('ExampleBloc', () {
    test('initial state is ExampleInitial', () {
      final bloc = ExampleBloc(
        getExamples: GetExamples(
          _FakeExampleRepository(const Right(tExamples)),
        ),
      );
      expect(bloc.state, isA<ExampleInitial>());
      bloc.close();
    });

    test('emits [ExampleLoading, ExampleLoaded] when data is fetched '
        'successfully', () async {
      final bloc = ExampleBloc(
        getExamples: GetExamples(
          _FakeExampleRepository(const Right(tExamples)),
        ),
      );

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ExampleLoading>(),
          isA<ExampleLoaded>().having(
            (s) => s.examples,
            'examples',
            tExamples,
          ),
        ]),
      );

      bloc.add(GetExamplesEvent());
      await expectation;
      await bloc.close();
    });

    test('emits [ExampleLoading, ExampleError] with the failure message '
        'when fetching fails', () async {
      final bloc = ExampleBloc(
        getExamples: GetExamples(
          _FakeExampleRepository(const Left(ServerFailure(message: 'boom'))),
        ),
      );

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ExampleLoading>(),
          isA<ExampleError>().having((s) => s.message, 'message', 'boom'),
        ]),
      );

      bloc.add(GetExamplesEvent());
      await expectation;
      await bloc.close();
    });
  });
}
