import '../models/example_model.dart';

abstract class ExampleRemoteDataSource {
  Future<List<ExampleModel>> getExamples();
}
