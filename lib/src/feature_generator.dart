import 'dart:io';

import 'config.dart';
import 'engine.dart';
import 'templates/feature_templates.dart';
import 'writer.dart';

/// Generates one feature slice and wires it into the app.
class FeatureGenerator {
  FeatureGenerator({
    required this.writer,
    required this.project,
    required this.feature,
  });

  final ProjectWriter writer;
  final ProjectConfig project;
  final FeatureConfig feature;

  final List<String> warnings = [];

  void generate() {
    final vars = feature.toTemplateVars(project: project);
    // A feature can only talk to the network / cache if the project has them.
    vars['use_remote'] = feature.remote && project.use('network');
    vars['use_local'] = feature.local && project.use('prefs');
    vars['has_repo_deps'] = vars['use_remote'] == true ||
        vars['use_local'] == true ||
        project.use('connectivity');

    final name = vars['feature_name']! as String;
    final base = 'lib/features/$name';

    void emit(String path, String template) =>
        writer.write(path, TemplateEngine.render(template, vars));

    emit('$base/domain/entities/${name}_entity.dart',
        FeatureTemplates.entity);
    emit('$base/domain/repositories/${name}_repository.dart',
        FeatureTemplates.repositoryContract);
    emit('$base/domain/usecases/get_${vars['feature_plural']}.dart',
        FeatureTemplates.useCase);
    emit('$base/data/models/${name}_model.dart', FeatureTemplates.model);

    if (vars['use_remote'] == true) {
      emit('$base/data/datasources/${name}_remote_data_source.dart',
          FeatureTemplates.remoteDataSource);
      emit('$base/data/datasources/${name}_remote_data_source_impl.dart',
          FeatureTemplates.remoteDataSourceImpl);
    }
    if (vars['use_local'] == true) {
      emit('$base/data/datasources/${name}_local_data_source.dart',
          FeatureTemplates.localDataSource);
      emit('$base/data/datasources/${name}_local_data_source_impl.dart',
          FeatureTemplates.localDataSourceImpl);
    }

    emit('$base/data/repositories/${name}_repository_impl.dart',
        FeatureTemplates.repositoryImpl);

    final stateDir = vars['state_dir']! as String;
    if (feature.stateManagement == 'bloc') {
      emit('$base/presentation/bloc/${name}_bloc.dart', FeatureTemplates.bloc);
      emit('$base/presentation/bloc/${name}_event.dart',
          FeatureTemplates.blocEvent);
      emit('$base/presentation/bloc/${name}_state.dart',
          FeatureTemplates.blocState);
    } else {
      emit('$base/presentation/cubit/${name}_cubit.dart',
          FeatureTemplates.cubit);
      emit('$base/presentation/cubit/${name}_state.dart',
          FeatureTemplates.cubitState);
    }

    if (feature.withPage) {
      emit('$base/presentation/pages/${name}_page.dart',
          FeatureTemplates.page);
      emit('$base/presentation/widgets/${name}_list_item.dart',
          FeatureTemplates.listItem);
    }

    if (feature.withTests) {
      emit('test/features/$name/${name}_${stateDir}_test.dart',
          FeatureTemplates.blocTest);
    }

    if (feature.wire) {
      _wire(vars);
    }
  }

  void _wire(Map<String, Object?> vars) {
    String render(String template) => TemplateEngine.render(template, vars);

    _apply(
      'lib/injection_container.dart',
      'clean_bloc:imports',
      render(FeatureWiring.imports),
      label: 'dependency imports',
    );
    _apply(
      'lib/injection_container.dart',
      'clean_bloc:registrations',
      render(FeatureWiring.registrations),
      label: 'dependency registrations',
      uniqueBy: '${vars['feature_pascal']}RepositoryImpl(',
    );

    // With a router, each feature bloc is provided by its own route; without
    // one, app.dart is the only place that can host it.
    if (!project.use('routing') && feature.withPage) {
      _apply(
        'lib/app.dart',
        'clean_bloc:imports',
        render(FeatureWiring.providerImport),
        label: 'app import',
      );
      // Separate insertion so it dedupes on its own line.
      _apply(
        'lib/app.dart',
        'clean_bloc:imports',
        render(FeatureWiring.serviceLocatorImport),
        label: 'service locator import',
      );
      _apply(
        'lib/app.dart',
        'clean_bloc:providers',
        render(FeatureWiring.provider),
        label: 'bloc provider',
        uniqueBy: 'sl<${vars['feature_pascal']}${vars['state_suffix']}>()',
      );
    }

    if (project.use('routing') && feature.withPage) {
      _apply(
        'lib/core/router/app_router.dart',
        'clean_bloc:imports',
        render(FeatureWiring.routeImport),
        label: 'route import',
      );
      _apply(
        'lib/core/router/app_router.dart',
        'clean_bloc:routes',
        render(FeatureWiring.route),
        label: 'route',
        uniqueBy: '${vars['feature_pascal']}Page.routeName',
      );
    }

    if (project.use('localization') && feature.withPage) {
      _addTranslations(render(FeatureWiring.translationKeys));
    }
  }

  void _apply(
    String path,
    String marker,
    String snippet, {
    required String label,
    String? uniqueBy,
  }) {
    final result = writer.insertBefore(
      path,
      marker,
      snippet,
      uniqueBy: uniqueBy,
    );
    switch (result) {
      case PatchResult.applied:
      case PatchResult.alreadyPresent:
        break;
      case PatchResult.missingFile:
        warnings.add('Could not add $label: $path not found.');
      case PatchResult.missingMarker:
        warnings.add(
          'Could not add $label: marker "// $marker" missing in $path.',
        );
    }
  }

  void _addTranslations(String block) {
    for (final locale in project.locales) {
      final path = 'assets/translations/$locale.json';
      final file = File(writer.pathFor(path));
      if (!file.existsSync()) continue;

      final content = file.readAsStringSync();
      if (content.contains('"${feature.name}"')) continue;

      final open = content.indexOf('{');
      if (open == -1) continue;
      final updated = content.replaceRange(open + 1, open + 1, '\n$block'.trimRight());
      if (!writer.dryRun) file.writeAsStringSync(updated);
      writer.patched.add(path);
    }
  }
}
