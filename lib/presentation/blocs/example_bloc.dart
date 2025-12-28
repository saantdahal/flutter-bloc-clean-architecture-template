import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../core/usecases/usecase.dart';
import '../../domain/entities/example_entity.dart';
import '../../domain/usecases/get_examples.dart';

part 'example_event.dart';
part 'example_state.dart';

class ExampleBloc extends Bloc<ExampleEvent, ExampleState> {
  final GetExamples getExamples;

  ExampleBloc({required this.getExamples}) : super(ExampleInitial()) {
    on<GetExamplesEvent>((event, emit) async {
      emit(ExampleLoading());
      final result = await getExamples(NoParams());
      result.fold(
        (failure) => emit(ExampleError()),
        (examples) => emit(ExampleLoaded(examples)),
      );
    });
  }
}
