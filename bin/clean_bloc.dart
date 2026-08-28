import 'dart:io';

import 'package:clean_bloc_gen/src/args.dart';
import 'package:clean_bloc_gen/src/config.dart';
import 'package:clean_bloc_gen/src/detect.dart';
import 'package:clean_bloc_gen/src/feature_generator.dart';
import 'package:clean_bloc_gen/src/naming.dart';
import 'package:clean_bloc_gen/src/native.dart';
import 'package:clean_bloc_gen/src/packages.dart';
import 'package:clean_bloc_gen/src/project_generator.dart';
import 'package:clean_bloc_gen/src/prompts.dart';
import 'package:clean_bloc_gen/src/writer.dart';

const String _usage = '''
clean_bloc - Flutter Clean Architecture + BLoC generator

Usage: clean_bloc <command> [options]

Commands:
  create [name]      Scaffold a new project (interactive unless -y/--config).
  feature <name>     Add a feature slice to an existing project and wire it up.
  rename             Change the Android package / iOS bundle id / app name.
  config [path]      Write a clean_bloc.yaml you can edit and reuse.
  packages           Show the packages the current configuration selects.
  help               Show this message.

Project options (create):
  --name <n>                 Dart package name (lower_snake_case).
  --display-name <n>         Name shown on the launcher and in the app bar.
  --description <text>       pubspec description.
  --org <com.example>        Reverse-domain organisation.
  --android-package <id>     Android applicationId + namespace.
                             Default: <org>.<name>
  --ios-bundle-id <id>       iOS/macOS PRODUCT_BUNDLE_IDENTIFIER.
                             Default: <org>.<nameInCamelCase>
  --platforms <list>         android,ios,web,macos,linux,windows
  --min-sdk <int>            Android minSdk (0 keeps the Flutter default).
  --ios-target <version>     iOS deployment target, e.g. 13.0.
  --version <1.0.0+1>        App version.
  --state <bloc|cubit>       State management style.
  --locales <en,ne>          Supported locales (first one is the fallback).
  --base-url <url>           Default API base url.
  --output <dir>             Where to create the project. Default: ./<name>
  --config <file>            Read settings from a clean_bloc.yaml.
  --add <pkg:constraint>     Extra dependency (repeatable, comma separated).
  --add-dev <pkg:constraint> Extra dev dependency.
  --pin <pkg:constraint>     Override a bundled package version.

Module flags (create), use --no-<flag> to disable:
  --network --connectivity --env --routing --localization --responsive
  --theming --logger --prefs --secure-storage --firebase --flavors
  --example-feature --tests

Feature options:
  --state <bloc|cubit>       Override the project default.
  --path <dir>               Project root. Default: current directory.
  --no-remote                Skip the remote data source.
  --no-local                 Skip the cached local data source.
  --no-page                  Generate state management only (no UI).
  --no-tests                 Skip the generated test.
  --no-wire                  Do not touch injection_container/app/router.

Common options:
  -y, --yes                  Accept defaults, never prompt.
  --dry-run                  Show what would change without writing.
  --force                    Overwrite existing files.
  --no-flutter-create        Do not run "flutter create" (no platform folders).
  --pub-get                  Run "flutter pub get" when done.
''';

final ArgParser _parser = ArgParser(
  valueOptions: {
    'name',
    'display-name',
    'description',
    'org',
    'android-package',
    'ios-bundle-id',
    'platforms',
    'min-sdk',
    'ios-target',
    'version',
    'state',
    'locales',
    'base-url',
    'output',
    'config',
    'path',
    'add',
    'add-dev',
    'pin',
  },
  booleanFlags: {
    'yes',
    'dry-run',
    'force',
    'flutter-create',
    'pub-get',
    'remote',
    'local',
    'page',
    'wire',
    'help',
    for (final module in kModules) module.key.replaceAll('_', '-'),
  },
  aliases: {'y': 'yes', 'h': 'help', 'v': 'version'},
);

Future<int> main(List<String> arguments) async {
  try {
    return await _run(arguments);
  } on FormatException catch (error) {
    stderr.writeln('error: ${error.message}');
    return 64;
  } on ProcessException catch (error) {
    stderr.writeln('error: ${error.executable} failed.\n${error.message}');
    return 70;
  }
}

Future<int> _run(List<String> arguments) async {
  final args = _parser.parse(arguments);

  if (args.flag('help') == true || args.command == null) {
    stdout.writeln(_usage);
    return args.command == null ? 64 : 0;
  }

  switch (args.command) {
    case 'create':
      return _create(args);
    case 'feature':
      return _feature(args);
    case 'rename':
      return _rename(args);
    case 'config':
      return _config(args);
    case 'packages':
      return _packages(args);
    case 'help':
      stdout.writeln(_usage);
      return 0;
    default:
      stderr.writeln('error: unknown command "${args.command}".\n');
      stdout.writeln(_usage);
      return 64;
  }
}

// --------------------------------------------------------------------- create

Future<int> _create(ArgResults args) async {
  final interactive = args.flag('yes') != true && stdin.hasTerminal;
  final prompts = Prompts(enabled: interactive);

  var config = args.option('config') != null
      ? ProjectConfig.fromYamlFile(args.option('config')!)
      : ProjectConfig.defaults();

  final positionalName = args.rest.isNotEmpty ? args.rest.first : null;
  if (positionalName != null) {
    config = config.copyWith(name: Naming.snake(positionalName));
  }

  config = _applyProjectFlags(config, args);

  if (interactive) {
    config = _promptForProject(config, prompts);
  }

  config = config.resolved();

  stdout
    ..writeln()
    ..writeln('Configuration')
    ..writeln('-------------')
    ..writeln(config.summary())
    ..writeln();

  if (interactive && !prompts.confirm('Generate?', defaultValue: true)) {
    stdout.writeln('Aborted.');
    return 0;
  }

  final output = args.option('output') ?? config.name;
  final directory = Directory(output);
  if (directory.existsSync() &&
      directory.listSync().isNotEmpty &&
      args.flag('force') != true &&
      args.flag('dry-run') != true) {
    stdout.writeln(
      'note: $output already exists; existing files are kept '
      '(use --force to overwrite).',
    );
  }
  if (args.flag('dry-run') != true) {
    directory.createSync(recursive: true);
  }

  final writer = ProjectWriter(
    root: directory.absolute.path,
    dryRun: args.flag('dry-run') == true,
    force: args.flag('force') == true,
  );

  final generator = ProjectGenerator(
    config: config,
    writer: writer,
    runFlutterCreate: args.flag('flutter-create') != false,
    runPubGet: args.flag('pub-get') == true,
  );
  await generator.generate();

  stdout
    ..writeln()
    ..writeln('Done: ${writer.summary()}.');
  if (generator.nativeChanges.isNotEmpty) {
    stdout.writeln(
      'Native identifiers applied to '
      '${generator.nativeChanges.length} file(s): '
      '${config.androidPackage} / ${config.iosBundleId}',
    );
  }
  _printWarnings(generator.warnings);

  stdout
    ..writeln()
    ..writeln('Next steps:')
    ..writeln('  cd $output')
    ..writeln('  flutter pub get')
    ..writeln('  flutter run');
  return 0;
}

ProjectConfig _applyProjectFlags(ProjectConfig config, ArgResults args) {
  final modules = Map<String, bool>.from(config.modules);
  for (final module in kModules) {
    final flag = args.flag(module.key.replaceAll('_', '-'));
    if (flag != null) modules[module.key] = flag;
  }

  final locales = args.option('locales')?.split(RegExp(r'[,\s]+'))
      .where((value) => value.isNotEmpty)
      .toList();

  return config.copyWith(
    name: args.option('name') == null
        ? null
        : Naming.snake(args.option('name')!),
    displayName: args.option('display-name'),
    description: args.option('description'),
    org: args.option('org'),
    version: args.option('version'),
    androidPackage: args.option('android-package'),
    iosBundleId: args.option('ios-bundle-id'),
    platforms: args.option('platforms')?.split(RegExp(r'[,\s]+')),
    minSdkVersion: args.option('min-sdk') == null
        ? null
        : int.tryParse(args.option('min-sdk')!),
    iosDeploymentTarget: args.option('ios-target'),
    stateManagement: args.option('state'),
    modules: modules,
    locales: locales,
    baseUrl: args.option('base-url'),
    dependencyOverrides: _parsePackages(args.option('pin')),
    extraDependencies: _parsePackages(args.option('add')),
    extraDevDependencies: _parsePackages(args.option('add-dev')),
  );
}

Map<String, String>? _parsePackages(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final result = <String, String>{};
  for (final entry in raw.split(',')) {
    final trimmed = entry.trim();
    if (trimmed.isEmpty) continue;
    final separator = trimmed.indexOf(':');
    if (separator == -1) {
      result[trimmed] = 'any';
    } else {
      result[trimmed.substring(0, separator)] =
          trimmed.substring(separator + 1);
    }
  }
  return result;
}

ProjectConfig _promptForProject(ProjectConfig config, Prompts prompts) {
  prompts.section('Project');
  final name = Naming.snake(
    prompts.ask(
      'Package name',
      defaultValue: config.name,
      validate: (value) =>
          Naming.validateIdentifier(Naming.snake(value), 'Project name'),
    ),
  );
  final displayName = prompts.ask(
    'Display name',
    defaultValue: config.displayName.isEmpty
        ? Naming.title(name)
        : config.displayName,
  );
  final description =
      prompts.ask('Description', defaultValue: config.description);
  final org = prompts.ask(
    'Organisation',
    defaultValue: config.org,
    validate: Naming.validateOrg,
  );
  final version = prompts.ask('Version', defaultValue: config.version);

  prompts.section('Platforms and identifiers');
  final platforms = prompts.askList(
    'Platforms',
    defaultValue: config.platforms,
    validateItem: (value) => kPlatforms.contains(value)
        ? null
        : 'Unknown platform "$value" '
            '(choose from ${kPlatforms.join(', ')}).',
  );
  final androidPackage = prompts.ask(
    'Android package (applicationId)',
    defaultValue: ProjectConfig.defaultAndroidPackage(org, name),
    validate: Naming.validateAndroidPackage,
  );
  final iosBundleId = prompts.ask(
    'iOS bundle identifier',
    defaultValue: ProjectConfig.defaultIosBundleId(org, name),
    validate: Naming.validateBundleId,
  );
  final minSdk = int.tryParse(
        prompts.ask(
          'Android minSdk (0 = Flutter default)',
          defaultValue: '${config.minSdkVersion}',
        ),
      ) ??
      config.minSdkVersion;
  final iosTarget = prompts.ask(
    'iOS deployment target (empty = Flutter default)',
    defaultValue: config.iosDeploymentTarget,
  );

  prompts.section('Architecture');
  final state = prompts.choose(
    'State management',
    const ['bloc', 'cubit'],
    defaultValue: config.stateManagement,
  );

  prompts.section('Packages / modules');
  final modules = Map<String, bool>.from(config.modules);
  for (final module in kModules) {
    modules[module.key] = prompts.confirm(
      '${module.label.padRight(34)} ${module.description}',
      defaultValue: modules[module.key] ?? module.defaultValue,
    );
  }

  var locales = config.locales;
  if (modules['localization'] == true) {
    locales = prompts.askList(
      'Locales (first is the fallback)',
      defaultValue: config.locales,
      validateItem: (value) =>
          RegExp(r'^[a-z]{2}(_[A-Z]{2})?$').hasMatch(value)
              ? null
              : 'Locale "$value" must look like "en" or "en_US".',
    );
  }

  var baseUrl = config.baseUrl;
  if (modules['network'] == true) {
    baseUrl = prompts.ask('API base url', defaultValue: config.baseUrl);
  }

  return config.copyWith(
    name: name,
    displayName: displayName,
    description: description,
    org: org,
    version: version,
    platforms: platforms,
    androidPackage: androidPackage,
    iosBundleId: iosBundleId,
    minSdkVersion: minSdk,
    iosDeploymentTarget: iosTarget,
    stateManagement: state,
    modules: modules,
    locales: locales,
    baseUrl: baseUrl,
  );
}

// -------------------------------------------------------------------- feature

Future<int> _feature(ArgResults args) async {
  if (args.rest.isEmpty) {
    stderr.writeln('error: feature name is required, e.g. '
        '"clean_bloc feature product".');
    return 64;
  }

  final root = args.option('path') ?? '.';
  final detector = ProjectDetector(Directory(root).absolute.path);
  if (!detector.isFlutterProject) {
    stderr.writeln('error: no pubspec.yaml in $root - run this inside a '
        'Flutter project (or pass --path).');
    return 66;
  }

  final project = detector.detect();
  final name = Naming.snake(args.rest.first);
  final nameError = Naming.validateIdentifier(name, 'Feature name');
  if (nameError != null) {
    stderr.writeln('error: $nameError');
    return 64;
  }

  final feature = FeatureConfig(
    name: name,
    stateManagement: args.option('state') ?? project.stateManagement,
    remote: args.flag('remote') != false,
    local: args.flag('local') != false,
    withTests: args.flag('tests') != false,
    withPage: args.flag('page') != false,
    wire: args.flag('wire') != false,
  );

  if (feature.stateManagement != 'bloc' &&
      feature.stateManagement != 'cubit') {
    stderr.writeln('error: --state must be "bloc" or "cubit".');
    return 64;
  }

  final writer = ProjectWriter(
    root: detector.root,
    dryRun: args.flag('dry-run') == true,
    force: args.flag('force') == true,
  );

  final generator = FeatureGenerator(
    writer: writer,
    project: project,
    feature: feature,
  )..generate();

  stdout
    ..writeln()
    ..writeln('Done: ${writer.summary()}.');
  _printWarnings(generator.warnings);
  return 0;
}

// --------------------------------------------------------------------- rename

Future<int> _rename(ArgResults args) async {
  final root = Directory(args.option('path') ?? '.').absolute.path;
  final detector = ProjectDetector(root);
  if (!detector.isFlutterProject) {
    stderr.writeln('error: no pubspec.yaml in $root.');
    return 66;
  }

  final current = detector.detect();
  final interactive = args.flag('yes') != true && stdin.hasTerminal;
  final prompts = Prompts(enabled: interactive);

  final androidPackage = args.option('android-package') ??
      prompts.ask(
        'Android package',
        defaultValue: current.androidPackage,
        validate: Naming.validateAndroidPackage,
      );
  final iosBundleId = args.option('ios-bundle-id') ??
      prompts.ask(
        'iOS bundle id',
        defaultValue: current.iosBundleId,
        validate: Naming.validateBundleId,
      );
  final displayName = args.option('display-name') ??
      prompts.ask('Display name', defaultValue: current.displayName);

  final androidError = Naming.validateAndroidPackage(androidPackage);
  final iosError = Naming.validateBundleId(iosBundleId);
  if (androidError != null || iosError != null) {
    stderr.writeln('error: ${androidError ?? iosError}');
    return 64;
  }

  final configurator = NativeConfigurator(
    root: root,
    androidPackage: androidPackage,
    iosBundleId: iosBundleId,
    displayName: displayName,
    projectName: current.name,
    minSdkVersion: int.tryParse(args.option('min-sdk') ?? '') ?? 0,
    iosDeploymentTarget: args.option('ios-target') ?? '',
    dryRun: args.flag('dry-run') == true,
  )..apply();

  if (configurator.changes.isEmpty) {
    stdout.writeln('Nothing to change.');
    return 0;
  }

  stdout.writeln('Updated:');
  for (final change in configurator.changes) {
    stdout.writeln('  $change');
  }
  stdout
    ..writeln()
    ..writeln('Android: $androidPackage')
    ..writeln('iOS    : $iosBundleId')
    ..writeln('Name   : $displayName')
    ..writeln()
    ..writeln('Run "flutter clean" before the next build.');
  return 0;
}

// --------------------------------------------------------------------- config

Future<int> _config(ArgResults args) async {
  final path = args.rest.isNotEmpty ? args.rest.first : 'clean_bloc.yaml';
  final file = File(path);
  if (file.existsSync() && args.flag('force') != true) {
    stderr.writeln('error: $path already exists (use --force to replace).');
    return 73;
  }

  final config = _applyProjectFlags(ProjectConfig.defaults(), args).resolved();
  file.writeAsStringSync(config.toYaml());
  stdout
    ..writeln('Wrote $path')
    ..writeln('Edit it, then run: clean_bloc create --config $path');
  return 0;
}

// ------------------------------------------------------------------- packages

Future<int> _packages(ArgResults args) async {
  final config = args.option('config') != null
      ? ProjectConfig.fromYamlFile(args.option('config')!).resolved()
      : _applyProjectFlags(ProjectConfig.defaults(), args).resolved();

  final packages = PackageRegistry.resolve(
    modules: config.modules,
    overrides: config.dependencyOverrides,
    extra: config.extraDependencies,
    extraDev: config.extraDevDependencies,
  )..sort((a, b) => a.name.compareTo(b.name));

  stdout
    ..writeln('Packages for the current configuration:')
    ..writeln();
  for (final package in packages) {
    final constraint = package.sdk != null
        ? 'sdk: ${package.sdk}'
        : package.constraint;
    final origin = PackageRegistry.moduleFor(package.name) ?? 'custom';
    stdout.writeln(
      '  ${package.name.padRight(30)} '
      '${constraint.padRight(14)} '
      '${package.dev ? 'dev ' : '    '}'
      '$origin',
    );
  }
  return 0;
}

void _printWarnings(List<String> warnings) {
  if (warnings.isEmpty) return;
  stdout.writeln();
  for (final warning in warnings) {
    stdout.writeln('warning: $warning');
  }
}
