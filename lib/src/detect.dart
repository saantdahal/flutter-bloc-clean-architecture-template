import 'dart:io';

import 'config.dart';
import 'native.dart';
import 'yaml_lite.dart';

/// Recovers a [ProjectConfig] for an existing project so `feature` and
/// `rename` behave consistently with how the project was generated.
///
/// Prefers the `clean_bloc.yaml` written by `create`; otherwise it infers the
/// settings from `pubspec.yaml` and the native folders.
class ProjectDetector {
  const ProjectDetector(this.root);

  final String root;

  bool get isFlutterProject => File(_path('pubspec.yaml')).existsSync();

  ProjectConfig detect() {
    final configFile = File(_path('clean_bloc.yaml'));
    if (configFile.existsSync()) {
      final fromFile = ProjectConfig.fromYamlFile(_path('clean_bloc.yaml'));
      return _withNativeOverrides(fromFile).resolved();
    }
    return _withNativeOverrides(_fromPubspec()).resolved();
  }

  ProjectConfig _fromPubspec() {
    final pubspec = File(_path('pubspec.yaml'));
    if (!pubspec.existsSync()) {
      throw FormatException('No pubspec.yaml found in $root.');
    }
    final content = pubspec.readAsStringSync();

    final name = RegExp(r'^name:\s*(\S+)', multiLine: true)
            .firstMatch(content)
            ?.group(1) ??
        'app';
    final description =
        RegExp(r'^description:\s*"?([^"\n]+)"?', multiLine: true)
                .firstMatch(content)
                ?.group(1)
                ?.trim() ??
            '';
    final version = RegExp(r'^version:\s*(\S+)', multiLine: true)
            .firstMatch(content)
            ?.group(1) ??
        '1.0.0+1';

    bool hasPackage(String package) =>
        RegExp('^\\s{2}$package:', multiLine: true).hasMatch(content);

    final modules = ProjectConfig.defaultModules()
      ..['network'] = hasPackage('dio')
      ..['connectivity'] = hasPackage('internet_connection_checker')
      ..['env'] = hasPackage('flutter_dotenv')
      ..['routing'] = hasPackage('go_router')
      ..['localization'] = hasPackage('easy_localization')
      ..['responsive'] = hasPackage('flutter_screenutil')
      ..['logger'] = hasPackage('logger')
      ..['prefs'] = hasPackage('shared_preferences')
      ..['secure_storage'] = hasPackage('flutter_secure_storage')
      ..['firebase'] = hasPackage('firebase_messaging')
      ..['flavors'] = hasPackage('flutter_flavorizr')
      ..['theming'] =
          File(_path('lib/core/theme/app_theme.dart')).existsSync()
      ..['example_feature'] =
          Directory(_path('lib/features/example')).existsSync()
      ..['tests'] = Directory(_path('test')).existsSync();

    final locales = _detectLocales();
    final stateManagement =
        Directory(_path('lib/features')).existsSync() && _usesCubit()
            ? 'cubit'
            : 'bloc';

    return ProjectConfig.defaults(name: name).copyWith(
      description: description.isEmpty ? 'A Flutter app.' : description,
      version: version,
      modules: modules,
      locales: locales,
      stateManagement: stateManagement,
    );
  }

  bool _usesCubit() {
    final features = Directory(_path('lib/features'));
    if (!features.existsSync()) return false;
    return features
        .listSync(recursive: true)
        .whereType<Directory>()
        .any((dir) => dir.path.endsWith('presentation/cubit'));
  }

  List<String> _detectLocales() {
    final directory = Directory(_path('assets/translations'));
    if (!directory.existsSync()) return const ['en'];
    final locales = directory
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .map((file) => file.uri.pathSegments.last.replaceAll('.json', ''))
        .toList()
      ..sort();
    return locales.isEmpty ? const ['en'] : locales;
  }

  /// The native folders are the source of truth for the identifiers.
  ProjectConfig _withNativeOverrides(ProjectConfig config) {
    final native = NativeConfigurator(
      root: root,
      androidPackage: config.androidPackage,
      iosBundleId: config.iosBundleId,
      displayName: config.displayName,
      projectName: config.name,
    );
    return config.copyWith(
      androidPackage: native.readAndroidPackage() ?? config.androidPackage,
      iosBundleId: native.readIosBundleId() ?? config.iosBundleId,
    );
  }

  /// Locales listed in an existing `clean_bloc.yaml`, if any.
  static List<String>? localesFromConfigFile(String path) {
    final file = File(path);
    if (!file.existsSync()) return null;
    final map = YamlLite.parse(file.readAsStringSync());
    final locales = map['locales'];
    if (locales is List) return locales.map((e) => e.toString()).toList();
    return null;
  }

  String _path(String relative) =>
      '$root${Platform.pathSeparator}'
      '${relative.replaceAll('/', Platform.pathSeparator)}';
}
