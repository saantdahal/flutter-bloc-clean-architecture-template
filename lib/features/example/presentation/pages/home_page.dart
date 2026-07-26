import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_bloc_clean_architecture_template/features/example/presentation/blocs/example_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('home_title'.tr())),
      body: Center(
        child: BlocBuilder<ExampleBloc, ExampleState>(
          builder: (context, state) {
            if (state is ExampleInitial) {
              return Text('press_button_to_load'.tr());
            } else if (state is ExampleLoading) {
              return const CircularProgressIndicator();
            } else if (state is ExampleLoaded) {
              return ListView.builder(
                itemCount: state.examples.length,
                itemBuilder: (context, index) {
                  return ListTile(title: Text(state.examples[index].name));
                },
              );
            } else if (state is ExampleError) {
              return Text('${'error_loading'.tr()}: ${state.message}');
            }
            return Container();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<ExampleBloc>().add(GetExamplesEvent());
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
