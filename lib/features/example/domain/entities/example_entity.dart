import 'package:equatable/equatable.dart';

class ExampleEntity extends Equatable {
  final String id;
  final String name;

  const ExampleEntity({required this.id, required this.name});

  @override
  List<Object> get props => [id, name];
}
