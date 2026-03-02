part of 'example_bloc.dart';

abstract class ExampleEvent extends Equatable {
  const ExampleEvent();

  @override
  List<Object> get props => [];
}

class GetExamplesEvent extends ExampleEvent {}
