import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/example_bloc.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(
        child: BlocBuilder<ExampleBloc, ExampleState>(
          builder: (context, state) {
            if (state is ExampleInitial) {
              return Text('Press the button to load examples');
            } else if (state is ExampleLoading) {
              return CircularProgressIndicator();
            } else if (state is ExampleLoaded) {
              return ListView.builder(
                itemCount: state.examples.length,
                itemBuilder: (context, index) {
                  return ListTile(title: Text(state.examples[index].name));
                },
              );
            } else if (state is ExampleError) {
              return Text('Error loading examples');
            }
            return Container();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<ExampleBloc>().add(GetExamplesEvent());
        },
        child: Icon(Icons.refresh),
      ),
    );
  }
}
