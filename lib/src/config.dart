import 'dart:io';

import 'naming.dart';
import 'yaml_lite.dart';

/// One configurable module of the generated project.
class Module {
  const Module({
    required this.key,
    required this.label,
    required this.description,
    required this.defaultValue,
    this.requires = const [],
  });

  final String key;
  final String label;
  final String description;
  final bool defaultValue;

  /// Other module keys that must be enabled for this one to work.
  final List<String> requires;
}

const List<Module> kModules = [
  Module(
    key: 'network',
    label: 'Networking (dio)',
    description: 'Dio client, interceptors and remote data sources.',
    defaultValue: true,
  ),
  Module(
    key: 'connectivity',
    label: 'Connectivity checks',
    description: 'NetworkInfo backed by internet_connection_checker.',
    defaultValue: true,
    requires: ['network'],
  ),
  Module(
    key: 'env',
    label: 'Environment file (.env)',
    description: 'flutter_dotenv with a committed .env.example.',
    defaultValue: true,
  ),
  Module(
    key: 'routing',
    label: 'Routing (go_router)',
    description: 'Declarative router with named routes.',
    defaultValue: true,
  ),
  Module(
    key: 'localization',
    label: 'Localization (easy_localization)',
    description: 'JSON translations and locale switching.',
    defaultValue: true,
  ),
  Module(
    key: 'responsive',
    label: 'Responsive sizing (flutter_screenutil)',
    description: 'Design-size based scaling.',
    defaultValue: true,
  ),
  Module(
    key: 'theming',
    label: 'Light/dark theme',
    description: 'AppTheme with Material 3 colour schemes.',
    defaultValue: true,
  ),
  Module(
    key: 'logger',
    label: 'Logger',
    description: 'AppLogger wrapper around package:logger.',
    defaultValue: true,
  ),
  Module(
    key: 'prefs',
    label: 'Shared preferences cache',
    description: 'Local data sources and CacheFailure handling.',
    defaultValue: true,
  ),
  Module(
    key: 'secure_storage',
    label: 'Secure storage',
    description: 'Token storage via flutter_secure_storage.',
    defaultValue: false,
  ),
  Module(
    key: 'firebase',
    label: 'Firebase messaging',
    description: 'firebase_core, messaging and local notifications.',
    defaultValue: false,
  ),
  Module(
    key: 'flavors',
    label: 'Flavors',
    description: 'flutter_flavorizr configuration for dev/stg/prod.',
    defaultValue: false,
  ),
  Module(
    key: 'example_feature',
    label: 'Example feature',
    description: 'A ready-made feature demonstrating every layer.',
    defaultValue: true,
  ),
  Module(
    key: 'tests',
    label: 'Tests',
    description: 'Unit tests for the generated blocs and repositories.',
    defaultValue: true,
  ),
];

/// Platform folders `flutter create` can produce.
const List<String> kPlatforms = [
  'android',
  'ios',
  'web',
  'macos',
  'linux',
  'windows',
];

/// Full configuration for a generated project.
class ProjectConfig {
  ProjectConfig({
    required this.name,
    required this.displayName,
    required this.description,
    required this.org,
    required this.version,
    required this.androidPackage,
    required this.iosBundleId,
    required this.platforms,
    required this.minSdkVersion,
    required this.iosDeploymentTarget,
    required this.dependencyOverrides,
    required this.extraDependencies,
    required this.extraDevDependencies,
    required this.stateManagement,
    required this.modules,
    required this.locales,
    required this.baseUrl,
    required this.designWidth,
    required this.designHeight,
  });

  final String name;

  /// Human readable name shown on the launcher / app bar.
  final String displayName;
  final String description;
  final String org;
  final String version;

  /// Android `applicationId` and `namespace`.
  final String androidPackage;

  /// iOS `PRODUCT_BUNDLE_IDENTIFIER`.
  final String iosBundleId;

  /// Platform folders to create, e.g. `[android, ios]`.
  final List<String> platforms;

  /// `0` keeps the Flutter default.
  final int minSdkVersion;

  /// Empty keeps the Flutter default.
  final String iosDeploymentTarget;

  /// Version constraint overrides keyed by package name.
  final Map<String, String> dependencyOverrides;

  /// Extra packages to add on top of the selected modules.
  final Map<String, String> extraDependencies;
  final Map<String, String> extraDevDependencies;

  /// `bloc` or `cubit`.
  final String stateManagement;

  final Map<String, bool> modules;
  final List<String> locales;
  final String baseUrl;
  final double designWidth;
  final double designHeight;

  bool use(String key) => modules[key] ?? false;

  static Map<String, bool> defaultModules() => {
        for (final m in kModules) m.key: m.defaultValue,
      };

  static ProjectConfig defaults({String name = 'my_app'}) => ProjectConfig(
        name: name,
        displayName: '',
        description: 'A Flutter app built on Clean Architecture and BLoC.',
        org: 'com.example',
        version: '1.0.0+1',
        // Empty means "derive from org + project name" in [resolved].
        androidPackage: '',
        iosBundleId: '',
        platforms: const ['android', 'ios'],
        minSdkVersion: 0,
        iosDeploymentTarget: '',
        dependencyOverrides: const {},
        extraDependencies: const {},
        extraDevDependencies: const {},
        stateManagement: 'bloc',
        modules: defaultModules(),
        locales: const ['en'],
        baseUrl: 'https://jsonplaceholder.typicode.com',
        designWidth: 375,
        designHeight: 812,
      );

  ProjectConfig copyWith({
    String? name,
    String? displayName,
    String? description,
    String? org,
    String? version,
    String? androidPackage,
    String? iosBundleId,
    List<String>? platforms,
    int? minSdkVersion,
    String? iosDeploymentTarget,
    Map<String, String>? dependencyOverrides,
    Map<String, String>? extraDependencies,
    Map<String, String>? extraDevDependencies,
    String? stateManagement,
    Map<String, bool>? modules,
    List<String>? locales,
    String? baseUrl,
    double? designWidth,
    double? designHeight,
  }) {
    return ProjectConfig(
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      org: org ?? this.org,
      version: version ?? this.version,
      androidPackage: androidPackage ?? this.androidPackage,
      iosBundleId: iosBundleId ?? this.iosBundleId,
      platforms: platforms ?? this.platforms,
      minSdkVersion: minSdkVersion ?? this.minSdkVersion,
      iosDeploymentTarget: iosDeploymentTarget ?? this.iosDeploymentTarget,
      dependencyOverrides: dependencyOverrides ?? this.dependencyOverrides,
      extraDependencies: extraDependencies ?? this.extraDependencies,
      extraDevDependencies:
          extraDevDependencies ?? this.extraDevDependencies,
      stateManagement: stateManagement ?? this.stateManagement,
      modules: modules ?? this.modules,
      locales: locales ?? this.locales,
      baseUrl: baseUrl ?? this.baseUrl,
      designWidth: designWidth ?? this.designWidth,
      designHeight: designHeight ?? this.designHeight,
    );
  }

  /// Reads a `clean_bloc.yaml` style configuration file.
  static ProjectConfig fromYamlFile(String path, {ProjectConfig? base}) {
    final file = File(path);
    if (!file.existsSync()) {
      throw FormatException('Config file not found: $path');
    }
    return fromMap(YamlLite.parse(file.readAsStringSync()), base: base);
  }

  static ProjectConfig fromMap(
    Map<String, Object?> map, {
    ProjectConfig? base,
  }) {
    final start = base ?? ProjectConfig.defaults();
    final project = _asMap(map['project']);
    final architecture = _asMap(map['architecture']);
    final moduleMap = _asMap(map['modules']);
    final app = _asMap(map['app']);
    final platformSection = _asMap(map['platforms']);
    final android = _asMap(platformSection['android']);
    final ios = _asMap(platformSection['ios']);

    final modules = Map<String, bool>.from(start.modules);
    moduleMap.forEach((key, value) {
      if (!modules.containsKey(key)) {
        throw FormatException('Unknown module "$key" in config.');
      }
      modules[key] = value == true;
    });

    final locales = map['locales'] is List
        ? (map['locales'] as List).map((e) => e.toString()).toList()
        : start.locales;

    final platforms = platformSection['targets'] is List
        ? (platformSection['targets'] as List)
            .map((e) => e.toString())
            .toList()
        : start.platforms;

    final overrides = _asStringMap(_asMap(map['dependencies'])['overrides']);
    final extras = _asStringMap(_asMap(map['dependencies'])['extra']);
    final devExtras =
        _asStringMap(_asMap(map['dev_dependencies'])['extra']);

    return start.copyWith(
      name: project['name']?.toString(),
      displayName: project['display_name']?.toString(),
      description: project['description']?.toString(),
      org: project['org']?.toString(),
      version: project['version']?.toString(),
      androidPackage: android['package']?.toString(),
      iosBundleId: ios['bundle_id']?.toString(),
      platforms: platforms,
      minSdkVersion: _asInt(android['min_sdk_version']),
      iosDeploymentTarget: ios['deployment_target']?.toString(),
      dependencyOverrides: overrides.isEmpty ? null : overrides,
      extraDependencies: extras.isEmpty ? null : extras,
      extraDevDependencies: devExtras.isEmpty ? null : devExtras,
      stateManagement: architecture['state_management']?.toString(),
      modules: modules,
      locales: locales,
      baseUrl: app['base_url']?.toString(),
      designWidth: _asDouble(app['design_width']),
      designHeight: _asDouble(app['design_height']),
    );
  }

  static Map<String, Object?> _asMap(Object? value) =>
      value is Map<String, Object?> ? value : const {};

  static Map<String, String> _asStringMap(Object? value) {
    if (value is! Map) return const {};
    return {
      for (final entry in value.entries)
        entry.key.toString(): entry.value?.toString() ?? 'any',
    };
  }

  static int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static String defaultAndroidPackage(String org, String name) =>
      '$org.${Naming.snake(name)}';

  /// Matches what `flutter create` produces for iOS.
  static String defaultIosBundleId(String org, String name) =>
      '$org.${Naming.camel(name)}';

  static double? _asDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  /// Applies module resolution rules and validates the whole configuration.
  ProjectConfig resolved() {
    final resolvedModules = Map<String, bool>.from(modules);

    // Turn off modules whose prerequisites are disabled.
    var changed = true;
    while (changed) {
      changed = false;
      for (final module in kModules) {
        if (resolvedModules[module.key] != true) continue;
        for (final requirement in module.requires) {
          if (resolvedModules[requirement] != true) {
            resolvedModules[module.key] = false;
            changed = true;
          }
        }
      }
    }

    // Derive anything the user left blank.
    final resolvedAndroid = androidPackage.isEmpty
        ? defaultAndroidPackage(org, name)
        : androidPackage;
    final resolvedIos =
        iosBundleId.isEmpty ? defaultIosBundleId(org, name) : iosBundleId;
    final resolvedDisplayName =
        displayName.isEmpty ? Naming.title(name) : displayName;

    final errors = <String>[];
    final nameError = Naming.validateIdentifier(name, 'Project name');
    if (nameError != null) errors.add(nameError);
    final orgError = Naming.validateOrg(org);
    if (orgError != null) errors.add(orgError);
    final androidError =
        Naming.validateAndroidPackage(resolvedAndroid);
    if (androidError != null) errors.add(androidError);
    final iosError = Naming.validateBundleId(resolvedIos);
    if (iosError != null) errors.add(iosError);
    if (platforms.isEmpty) {
      errors.add('At least one platform target is required.');
    }
    for (final platform in platforms) {
      if (!kPlatforms.contains(platform)) {
        errors.add('Unknown platform "$platform". '
            'Choose from ${kPlatforms.join(', ')}.');
      }
    }
    if (minSdkVersion != 0 && (minSdkVersion < 16 || minSdkVersion > 40)) {
      errors.add('android.min_sdk_version "$minSdkVersion" looks wrong.');
    }
    if (stateManagement != 'bloc' && stateManagement != 'cubit') {
      errors.add('state_management must be "bloc" or "cubit" '
          '(got "$stateManagement").');
    }
    if (locales.isEmpty) {
      errors.add('At least one locale is required.');
    }
    for (final locale in locales) {
      if (!RegExp(r'^[a-z]{2}(_[A-Z]{2})?$').hasMatch(locale)) {
        errors.add('Locale "$locale" must look like "en" or "en_US".');
      }
    }
    if (!RegExp(r'^\d+\.\d+\.\d+(\+\d+)?$').hasMatch(version)) {
      errors.add('Version "$version" must look like 1.0.0+1.');
    }
    if (errors.isNotEmpty) {
      throw FormatException(errors.join('\n'));
    }

    return copyWith(
      modules: resolvedModules,
      androidPackage: resolvedAndroid,
      iosBundleId: resolvedIos,
      displayName: resolvedDisplayName,
    );
  }

  /// Variables handed to the template engine.
  Map<String, Object?> toTemplateVars() {
    final localeVars = [
      for (final locale in locales)
        {
          'code': locale,
          'language': locale.split('_').first,
          'country': locale.contains('_') ? locale.split('_').last : '',
          'is_default': locale == locales.first,
        }
    ];

    return {
      'project_name': name,
      'project_name_pascal': Naming.pascal(name),
      'project_name_title': Naming.title(name),
      'app_class': Naming.pascal(name).endsWith('App')
          ? Naming.pascal(name)
          : '${Naming.pascal(name)}App',
      'display_name': displayName.isEmpty ? Naming.title(name) : displayName,
      'android_package': androidPackage,
      'ios_bundle_id': iosBundleId,
      'description': description,
      'org': org,
      'app_version': version,
      'base_url': baseUrl,
      'design_width': _num(designWidth),
      'design_height': _num(designHeight),
      'use_bloc': stateManagement == 'bloc',
      'use_cubit': stateManagement == 'cubit',
      'state_suffix': stateManagement == 'bloc' ? 'Bloc' : 'Cubit',
      'state_dir': stateManagement == 'bloc' ? 'bloc' : 'cubit',
      'use_network': use('network'),
      'use_connectivity': use('connectivity'),
      'has_repo_deps':
          use('network') || use('prefs') || use('connectivity'),
      // dotenv is only read by the DI when there is a base url to resolve.
      'use_env_network': use('env') && use('network'),
      'use_env': use('env'),
      'use_routing': use('routing'),
      'use_localization': use('localization'),
      'use_responsive': use('responsive'),
      'use_theming': use('theming'),
      'use_logger': use('logger'),
      'use_prefs': use('prefs'),
      'use_secure_storage': use('secure_storage'),
      'use_firebase': use('firebase'),
      'use_flavors': use('flavors'),
      'use_example': use('example_feature'),
      'use_tests': use('tests'),
      'locales': localeVars,
      'default_locale': locales.first,
      'multi_locale': locales.length > 1,
    };
  }

  static String _num(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : '$value';

  String toYaml() {
    final buffer = StringBuffer()
      ..writeln('# Configuration for the clean_bloc project generator.')
      ..writeln('# Run: clean_bloc create --config clean_bloc.yaml')
      ..writeln()
      ..writeln('project:')
      ..writeln('  name: $name')
      ..writeln('  display_name: "$displayName"')
      ..writeln('  description: "$description"')
      ..writeln('  org: $org')
      ..writeln('  version: $version')
      ..writeln()
      ..writeln('platforms:')
      ..writeln('  targets: [${platforms.join(', ')}]')
      ..writeln('  android:')
      ..writeln('    package: $androidPackage')
      ..writeln('    min_sdk_version: $minSdkVersion '
          '# 0 keeps the Flutter default')
      ..writeln('  ios:')
      ..writeln('    bundle_id: $iosBundleId')
      ..writeln('    deployment_target: "$iosDeploymentTarget" '
          '# empty keeps the Flutter default')
      ..writeln()
      ..writeln('architecture:')
      ..writeln('  state_management: $stateManagement '
          '# bloc | cubit')
      ..writeln()
      ..writeln('app:')
      ..writeln('  base_url: $baseUrl')
      ..writeln('  design_width: ${_num(designWidth)}')
      ..writeln('  design_height: ${_num(designHeight)}')
      ..writeln()
      ..writeln('locales: [${locales.join(', ')}]')
      ..writeln()
      ..writeln('modules:');
    for (final module in kModules) {
      buffer.writeln('  ${module.key}: ${use(module.key)} '
          '# ${module.description}');
    }

    buffer
      ..writeln()
      ..writeln('# Package selection on top of the modules above.')
      ..writeln('dependencies:')
      ..writeln('  overrides:');
    if (dependencyOverrides.isEmpty) {
      buffer.writeln('    # dio: ^5.7.0');
    } else {
      dependencyOverrides.forEach((name, constraint) {
        buffer.writeln('    $name: $constraint');
      });
    }
    buffer.writeln('  extra:');
    if (extraDependencies.isEmpty) {
      buffer.writeln('    # freezed_annotation: ^2.4.4');
    } else {
      extraDependencies.forEach((name, constraint) {
        buffer.writeln('    $name: $constraint');
      });
    }
    buffer
      ..writeln()
      ..writeln('dev_dependencies:')
      ..writeln('  extra:');
    if (extraDevDependencies.isEmpty) {
      buffer.writeln('    # bloc_test: ^9.1.7');
    } else {
      extraDevDependencies.forEach((name, constraint) {
        buffer.writeln('    $name: $constraint');
      });
    }

    return buffer.toString();
  }

  String summary() {
    final enabled = kModules
        .where((m) => use(m.key))
        .map((m) => m.key)
        .join(', ');
    final disabled = kModules
        .where((m) => !use(m.key))
        .map((m) => m.key)
        .join(', ');
    return [
      '  name             : $name',
      '  display name     : $displayName',
      '  org              : $org',
      '  android package  : $androidPackage',
      '  ios bundle id    : $iosBundleId',
      '  platforms        : ${platforms.join(', ')}',
      '  version          : $version',
      '  state management : $stateManagement',
      '  locales          : ${locales.join(', ')}',
      '  base url         : $baseUrl',
      '  enabled modules  : ${enabled.isEmpty ? '(none)' : enabled}',
      '  disabled modules : ${disabled.isEmpty ? '(none)' : disabled}',
    ].join('\n');
  }
}

/// Configuration for a single generated feature.
class FeatureConfig {
  FeatureConfig({
    required this.name,
    required this.stateManagement,
    required this.remote,
    required this.local,
    required this.withTests,
    required this.withPage,
    required this.wire,
  });

  final String name;
  final String stateManagement;
  final bool remote;
  final bool local;
  final bool withTests;
  final bool withPage;

  /// Whether to patch injection_container / router / app widget.
  final bool wire;

  Map<String, Object?> toTemplateVars({required ProjectConfig project}) {
    final snake = Naming.snake(name);
    final pascal = Naming.pascal(name);
    final camel = Naming.camel(name);
    final pluralSnake = Naming.plural(snake);
    return {
      ...project.toTemplateVars(),
      'feature_name': snake,
      'feature_pascal': pascal,
      'feature_camel': camel,
      'feature_title': Naming.title(name),
      'feature_plural': pluralSnake,
      'feature_plural_pascal': Naming.pascal(pluralSnake),
      'feature_plural_camel': Naming.camel(pluralSnake),
      'use_bloc': stateManagement == 'bloc',
      'use_cubit': stateManagement == 'cubit',
      'state_suffix': stateManagement == 'bloc' ? 'Bloc' : 'Cubit',
      'state_dir': stateManagement == 'bloc' ? 'bloc' : 'cubit',
      'use_remote': remote,
      'use_local': local,
      'use_tests': withTests,
      'use_page': withPage,
    };
  }
}
