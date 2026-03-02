import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_bloc_clean_architecture_template/features/example/presentation/blocs/example_bloc.dart';
import 'package:flutter_bloc_clean_architecture_template/features/example/presentation/pages/home_page.dart';
import 'package:flutter_bloc_clean_architecture_template/injection_container.dart'
    as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider(create: (_) => di.sl<ExampleBloc>())],
      child: MaterialApp(
        title: 'Flutter BLoC Clean Architecture',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const HomePage(),
      ),
    );
  }
}
