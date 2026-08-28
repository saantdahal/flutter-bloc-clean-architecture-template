import 'dart:io';

import 'config.dart';
import 'engine.dart';
import 'feature_generator.dart';
import 'native.dart';
import 'packages.dart';
import 'templates/project_templates.dart';
import 'writer.dart';

/// Generates a complete Flutter project: platform folders, pubspec, core layer,
/// the optional example feature and the native identifiers.
class ProjectGenerator {
  ProjectGenerator({
    required this.config,
    required this.writer,
    this.runFlutterCreate = true,
    this.runPubGet = false,
    this.flutterExecutable = 'flutter',
  });

  final ProjectConfig config;
  final ProjectWriter writer;
  final bool runFlutterCreate;
  final bool runPubGet;
  final String flutterExecutable;

  final List<String> warnings = [];
  final List<String> nativeChanges = [];

  Future<void> generate() async {
    final vars = config.toTemplateVars();

    if (runFlutterCreate) {
      await _flutterCreate();
    }

    _writeProjectFiles(vars);
    _writeCoreFiles(vars);
    _writeAssets(vars);

    if (config.use('example_feature')) {
      final generator = FeatureGenerator(
        writer: writer,
        project: config,
        feature: FeatureConfig(
          name: 'example',
          stateManagement: config.stateManagement,
          remote: config.use('network'),
          local: config.use('prefs'),
          withTests: config.use('tests'),
          withPage: true,
          // The generated core files already reference the example feature.
          wire: false,
        ),
      );
      generator.generate();
      warnings.addAll(generator.warnings);
    }

    _applyNativeIdentifiers();

    if (runPubGet) {
      await _pubGet();
    }
  }

  // ------------------------------------------------------------------ files

  void _writeProjectFiles(Map<String, Object?> vars) {
    final pubspecVars = Map<String, Object?>.from(vars)
      ..['dependencies'] = _dependencyBlock(dev: false)
      ..['dev_dependencies'] = _dependencyBlock(dev: true);

    _emit('pubspec.yaml', ProjectTemplates.pubspec, pubspecVars);
    _emit('analysis_options.yaml', ProjectTemplates.analysisOptions, vars);
    _emit('.gitignore', ProjectTemplates.gitignore, vars);
    _emit('README.md', ProjectTemplates.readme, vars);
    _emit('lib/main.dart', ProjectTemplates.main, vars);
    _emit('lib/app.dart', ProjectTemplates.app, vars);
    _emit(
      'lib/injection_container.dart',
      ProjectTemplates.injectionContainer,
      vars,
    );

    // Record the configuration so `feature` and `rename` can reuse it.
    writer.write('clean_bloc.yaml', config.toYaml());

    if (config.use('env')) {
      _emit('.env.example', ProjectTemplates.envExample, vars);
      _emit('.env', ProjectTemplates.envExample, vars);
    }
  }

  void _writeCoreFiles(Map<String, Object?> vars) {
    _emit('lib/core/error/exceptions.dart', ProjectTemplates.exceptions, vars);
    _emit('lib/core/error/failures.dart', ProjectTemplates.failures, vars);
    _emit('lib/core/usecases/usecase.dart',
        ProjectTemplates.useCaseContract, vars);
    _emit('lib/core/constants/app_constants.dart',
        ProjectTemplates.appConstants, vars);

    _emit('lib/core/bloc/app_bloc_observer.dart',
        ProjectTemplates.blocObserver, vars);

    if (config.use('network')) {
      _emit('lib/core/network/api_client.dart',
          ProjectTemplates.dioClient, vars);
      _emit('lib/core/network/api_endpoints.dart',
          ProjectTemplates.apiEndpoints, vars);
      _emit('lib/core/network/interceptors/error_interceptor.dart',
          ProjectTemplates.errorInterceptor, vars);
      _emit('lib/core/network/interceptors/retry_interceptor.dart',
          ProjectTemplates.retryInterceptor, vars);
      if (config.use('localization')) {
        _emit('lib/core/network/interceptors/headers_interceptor.dart',
            ProjectTemplates.headersInterceptor, vars);
      }
      if (config.use('secure_storage')) {
        _emit('lib/core/network/interceptors/auth_interceptor.dart',
            ProjectTemplates.authInterceptor, vars);
      }
    }
    if (config.use('connectivity')) {
      _emit('lib/core/network/network_info.dart',
          ProjectTemplates.networkInfo, vars);
      _emit('lib/core/network/network_info_impl.dart',
          ProjectTemplates.networkInfoImpl, vars);
    }
    if (config.use('routing')) {
      _emit('lib/core/router/app_router.dart',
          ProjectTemplates.appRouter, vars);
    }
    if (config.use('theming')) {
      _emit('lib/core/theme/app_theme.dart', ProjectTemplates.appTheme, vars);
    }
    if (config.use('logger')) {
      _emit('lib/core/utils/app_logger.dart', ProjectTemplates.appLogger, vars);
    }
    if (config.use('secure_storage')) {
      _emit('lib/core/storage/secure_storage_service.dart',
          ProjectTemplates.secureStorageService, vars);
    }
    if (config.use('firebase')) {
      _emit('lib/core/notifications/push_notification_service.dart',
          ProjectTemplates.pushNotificationService, vars);
    }
  }

  void _writeAssets(Map<String, Object?> vars) {
    writer.write('assets/images/.gitkeep', '');
    if (config.use('localization')) {
      for (final locale in config.locales) {
        _emit(
          'assets/translations/$locale.json',
          ProjectTemplates.translations,
          vars,
        );
      }
    }
  }

  void _emit(String path, String template, Map<String, Object?> vars) {
    writer.write(path, TemplateEngine.render(template, vars));
  }

  String _dependencyBlock({required bool dev}) {
    final packages = PackageRegistry.resolve(
      modules: config.modules,
      overrides: config.dependencyOverrides,
      extra: config.extraDependencies,
      extraDev: config.extraDevDependencies,
    ).where((package) => package.dev == dev).toList()
      ..sort((a, b) {
        // sdk dependencies first, then alphabetical.
        if ((a.sdk != null) != (b.sdk != null)) return a.sdk != null ? -1 : 1;
        return a.name.compareTo(b.name);
      });

    final buffer = StringBuffer();
    for (final package in packages) {
      if (package.sdk != null) {
        buffer
          ..writeln('  ${package.name}:')
          ..writeln('    sdk: ${package.sdk}');
      } else {
        buffer.writeln('  ${package.name}: ${package.constraint}');
      }
    }
    return buffer.toString();
  }

  // ----------------------------------------------------------------- native

  void _applyNativeIdentifiers() {
    final configurator = NativeConfigurator(
      root: writer.root,
      androidPackage: config.androidPackage,
      iosBundleId: config.iosBundleId,
      displayName: config.displayName,
      projectName: config.name,
      minSdkVersion: config.minSdkVersion,
      iosDeploymentTarget: config.iosDeploymentTarget,
      dryRun: writer.dryRun,
    )..apply();

    nativeChanges.addAll(configurator.changes);
    if (configurator.changes.isEmpty && !writer.dryRun) {
      warnings.add(
        'No native files were updated - platform folders are missing. '
        'Run "flutter create ." inside the project, then '
        '"clean_bloc rename" to apply the identifiers.',
      );
    }
  }

  // ---------------------------------------------------------------- flutter

  Future<void> _flutterCreate() async {
    if (writer.dryRun) {
      stdout.writeln('  (dry run) flutter create '
          '--platforms=${config.platforms.join(',')}');
      return;
    }

    stdout.writeln('  running flutter create...');
    final result = await Process.run(
      flutterExecutable,
      [
        'create',
        '--no-pub',
        '--org', config.org,
        '--project-name', config.name,
        '--platforms=${config.platforms.join(',')}',
        '--description', config.description,
        '.',
      ],
      workingDirectory: writer.root,
    );

    if (result.exitCode != 0) {
      throw ProcessException(
        flutterExecutable,
        ['create'],
        '${result.stdout}\n${result.stderr}',
        result.exitCode,
      );
    }

    _removeFlutterCreateArtifacts();
  }

  /// `flutter create` writes its own starter files; drop the ones the
  /// generator replaces so nothing is left half-overwritten.
  void _removeFlutterCreateArtifacts() {
    const artifacts = [
      'lib/main.dart',
      'test/widget_test.dart',
      'pubspec.yaml',
      'README.md',
      'analysis_options.yaml',
      '.gitignore',
      '.metadata',
    ];
    for (final artifact in artifacts) {
      if (artifact == '.metadata') continue;
      final file = File(writer.pathFor(artifact));
      if (file.existsSync()) file.deleteSync();
    }
  }

  Future<void> _pubGet() async {
    if (writer.dryRun) return;
    stdout.writeln('  running flutter pub get...');
    final result = await Process.run(
      flutterExecutable,
      ['pub', 'get'],
      workingDirectory: writer.root,
    );
    if (result.exitCode != 0) {
      warnings.add('flutter pub get failed:\n${result.stderr}');
    }
  }
}
