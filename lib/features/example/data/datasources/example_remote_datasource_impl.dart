import 'package:dio/dio.dart';

import '../models/example_model.dart';
import 'example_remote_datasource.dart';

class ExampleRemoteDataSourceImpl implements ExampleRemoteDataSource {
  final Dio dio;

  ExampleRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<ExampleModel>> getExamples() async {
    final response =
        await dio.get('https://jsonplaceholder.typicode.com/posts');

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = response.data;
      return jsonList.map((json) => ExampleModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load examples');
    }
  }
}
