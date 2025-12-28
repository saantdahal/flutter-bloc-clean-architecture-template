import '../../domain/entities/example_entity.dart';

class ExampleModel extends ExampleEntity {
  const ExampleModel({required super.id, required super.name});

  factory ExampleModel.fromJson(Map<String, dynamic> json) {
    return ExampleModel(id: json['id'], name: json['name']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
