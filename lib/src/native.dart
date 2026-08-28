import 'dart:io';

/// Rewrites the platform identifiers of a Flutter project: Android
/// `namespace`/`applicationId`, the Kotlin/Java package of `MainActivity`, the
/// iOS/macOS bundle identifier and the user visible app name.
///
/// It reads the current values out of the project first, so it works both on a
/// freshly created project and on an existing one (`clean_bloc rename`).
class NativeConfigurator {
  NativeConfigurator({
    required this.root,
    required this.androidPackage,
    required this.iosBundleId,
    required this.displayName,
    required this.projectName,
    this.minSdkVersion = 0,
    this.iosDeploymentTarget = '',
    this.dryRun = false,
  });

  final String root;
  final String androidPackage;
  final String iosBundleId;
  final String displayName;
  final String projectName;
  final int minSdkVersion;
  final String iosDeploymentTarget;
  final bool dryRun;

  final List<String> changes = [];

  void _record(String path) {
    if (!changes.contains(path)) changes.add(path);
  }

  void apply() {
    _android();
    _ios();
    _macos();
    _web();
    _linux();
  }

  // ---------------------------------------------------------------- android

  void _android() {
    final gradle = _firstExisting([
      'android/app/build.gradle.kts',
      'android/app/build.gradle',
    ]);
    if (gradle == null) return;

    final previous = readAndroidPackage() ?? 'com.example.$projectName';

    _edit(gradle, (content) {
      var updated = content
          .replaceAll(
            RegExp(r'namespace\s*=\s*"[^"]*"'),
            'namespace = "$androidPackage"',
          )
          .replaceAll(
            RegExp(r'namespace\s+"[^"]*"'),
            'namespace "$androidPackage"',
          )
          .replaceAll(
            RegExp(r'applicationId\s*=\s*"[^"]*"'),
            'applicationId = "$androidPackage"',
          )
          .replaceAll(
            RegExp(r'applicationId\s+"[^"]*"'),
            'applicationId "$androidPackage"',
          );

      if (minSdkVersion > 0) {
        updated = updated
            .replaceAll(
              RegExp(r'minSdk\s*=\s*[^\n]+'),
              'minSdk = $minSdkVersion',
            )
            .replaceAll(
              RegExp(r'minSdkVersion\s+[^\n]+'),
              'minSdkVersion $minSdkVersion',
            );
      }
      return updated;
    });

    // Manifests: display name and the legacy package attribute.
    for (final manifest in const [
      'android/app/src/main/AndroidManifest.xml',
      'android/app/src/debug/AndroidManifest.xml',
      'android/app/src/profile/AndroidManifest.xml',
    ]) {
      _edit(manifest, (content) {
        return content
            .replaceAll(
              RegExp('android:label="[^"]*"'),
              'android:label="$displayName"',
            )
            .replaceAll('package="$previous"', 'package="$androidPackage"');
      });
    }

    _moveMainActivity(previous);

    // Anything else still mentioning the old package (tests, plugins, ...).
    if (previous != androidPackage) {
      final directory = Directory(_path('android/app'));
      if (directory.existsSync()) {
        for (final entity in directory.listSync(recursive: true)) {
          if (entity is! File) continue;
          if (!RegExp(r'\.(kt|java|xml|gradle|kts|pro)$')
              .hasMatch(entity.path)) {
            continue;
          }
          final content = entity.readAsStringSync();
          if (!content.contains(previous)) continue;
          if (!dryRun) {
            entity.writeAsStringSync(
              content.replaceAll(previous, androidPackage),
            );
          }
          _record(_relative(entity.path));
        }
      }
    }
  }

  void _moveMainActivity(String previousPackage) {
    for (final language in const ['kotlin', 'java']) {
      final sourceRoot = Directory(_path('android/app/src/main/$language'));
      if (!sourceRoot.existsSync()) continue;

      final activities = sourceRoot
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('MainActivity.kt') ||
              file.path.endsWith('MainActivity.java'))
          .toList();

      for (final activity in activities) {
        final content = activity.readAsStringSync();
        final declared = RegExp(r'^package\s+([\w.]+)', multiLine: true)
            .firstMatch(content)
            ?.group(1);
        final oldPackage = declared ?? previousPackage;
        final updated = content.replaceFirst(
          RegExp(r'^package\s+[\w.]+', multiLine: true),
          'package $androidPackage',
        );

        final target = File(
          '${sourceRoot.path}/${androidPackage.replaceAll('.', '/')}'
          '/${activity.uri.pathSegments.last}',
        );

        if (target.path == activity.path) {
          if (updated != content && !dryRun) {
            activity.writeAsStringSync(updated);
          }
          if (updated != content) changes.add(_relative(activity.path));
          continue;
        }

        if (!dryRun) {
          target.parent.createSync(recursive: true);
          target.writeAsStringSync(updated);
          activity.deleteSync();
          _pruneEmptyDirs(sourceRoot, oldPackage);
        }
        _record('${_relative(target.path)} (moved)');
      }
    }
  }

  void _pruneEmptyDirs(Directory sourceRoot, String package) {
    var current = Directory('${sourceRoot.path}/${package.replaceAll('.', '/')}');
    while (current.existsSync() &&
        current.path.startsWith(sourceRoot.path) &&
        current.path != sourceRoot.path &&
        current.listSync().isEmpty) {
      current.deleteSync();
      current = current.parent;
    }
  }

  // -------------------------------------------------------------------- ios

  void _ios() {
    _edit('ios/Runner.xcodeproj/project.pbxproj', (content) {
      var updated = content.replaceAllMapped(
        RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);'),
        (match) {
          final current = match.group(1)!;
          final suffix = current.contains('.RunnerTests')
              ? '.RunnerTests'
              : current.contains('.RunnerUITests')
                  ? '.RunnerUITests'
                  : '';
          return 'PRODUCT_BUNDLE_IDENTIFIER = $iosBundleId$suffix;';
        },
      );
      if (iosDeploymentTarget.isNotEmpty) {
        updated = updated.replaceAll(
          RegExp(r'IPHONEOS_DEPLOYMENT_TARGET = [^;]+;'),
          'IPHONEOS_DEPLOYMENT_TARGET = $iosDeploymentTarget;',
        );
      }
      return updated;
    });

    _editPlist('ios/Runner/Info.plist', {
      'CFBundleDisplayName': displayName,
      'CFBundleName': projectName,
    });

    if (iosDeploymentTarget.isNotEmpty) {
      _edit('ios/Podfile', (content) {
        return content.replaceAll(
          RegExp(r"platform :ios, '[^']+'"),
          "platform :ios, '$iosDeploymentTarget'",
        );
      });
    }
  }

  // ------------------------------------------------------------------ macos

  void _macos() {
    _edit('macos/Runner/Configs/AppInfo.xcconfig', (content) {
      return content
          .replaceAll(
            RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = .*'),
            'PRODUCT_BUNDLE_IDENTIFIER = $iosBundleId',
          )
          .replaceAll(
            RegExp(r'PRODUCT_NAME = .*'),
            'PRODUCT_NAME = $displayName',
          );
    });

    _edit('macos/Runner.xcodeproj/project.pbxproj', (content) {
      return content.replaceAllMapped(
        RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);'),
        (match) {
          final current = match.group(1)!;
          final suffix = current.contains('.RunnerTests')
              ? '.RunnerTests'
              : current.contains('.RunnerUITests')
                  ? '.RunnerUITests'
                  : '';
          return 'PRODUCT_BUNDLE_IDENTIFIER = $iosBundleId$suffix;';
        },
      );
    });
  }

  // -------------------------------------------------------------------- web

  void _web() {
    _edit('web/index.html', (content) {
      return content
          .replaceAll(
            RegExp(r'<title>.*?</title>', dotAll: true),
            '<title>$displayName</title>',
          )
          .replaceAll(
            RegExp(r'<meta name="apple-mobile-web-app-title" content="[^"]*">'),
            '<meta name="apple-mobile-web-app-title" '
                'content="$displayName">',
          )
          .replaceAll(
            RegExp(r'<meta name="description" content="[^"]*">'),
            '<meta name="description" content="$displayName">',
          );
    });

    _edit('web/manifest.json', (content) {
      return content
          .replaceAll(
            RegExp(r'"name":\s*"[^"]*"'),
            '"name": "$displayName"',
          )
          .replaceAll(
            RegExp(r'"short_name":\s*"[^"]*"'),
            '"short_name": "$displayName"',
          );
    });
  }

  // ------------------------------------------------------------------ linux

  void _linux() {
    _edit('linux/CMakeLists.txt', (content) {
      return content.replaceAll(
        RegExp(r'set\(APPLICATION_ID "[^"]*"\)'),
        'set(APPLICATION_ID "$androidPackage")',
      );
    });
  }

  // ----------------------------------------------------------------- shared

  /// Current Android package, read from the gradle build file.
  String? readAndroidPackage() {
    final gradle = _firstExisting([
      'android/app/build.gradle.kts',
      'android/app/build.gradle',
    ]);
    if (gradle == null) return null;
    final content = File(_path(gradle)).readAsStringSync();
    final match = RegExp(r'applicationId\s*=?\s*"([^"]+)"').firstMatch(content) ??
        RegExp(r'namespace\s*=?\s*"([^"]+)"').firstMatch(content);
    return match?.group(1);
  }

  /// Current iOS bundle identifier, read from the Xcode project.
  String? readIosBundleId() {
    final file = File(_path('ios/Runner.xcodeproj/project.pbxproj'));
    if (!file.existsSync()) return null;
    for (final match in RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);')
        .allMatches(file.readAsStringSync())) {
      final value = match.group(1)!;
      if (!value.contains('RunnerTests') && !value.contains('RunnerUITests')) {
        return value;
      }
    }
    return null;
  }

  void _editPlist(String relativePath, Map<String, String> values) {
    _edit(relativePath, (content) {
      var updated = content;
      values.forEach((key, value) {
        updated = updated.replaceAllMapped(
          RegExp('<key>$key</key>\\s*\\n\\s*<string>[^<]*</string>'),
          (_) => '<key>$key</key>\n\t<string>$value</string>',
        );
      });
      return updated;
    });
  }

  void _edit(String relativePath, String Function(String) transform) {
    final file = File(_path(relativePath));
    if (!file.existsSync()) return;
    final content = file.readAsStringSync();
    final updated = transform(content);
    if (updated == content) return;
    if (!dryRun) file.writeAsStringSync(updated);
    _record(relativePath);
  }

  String? _firstExisting(List<String> candidates) {
    for (final candidate in candidates) {
      if (File(_path(candidate)).existsSync()) return candidate;
    }
    return null;
  }

  String _path(String relativePath) =>
      '$root${Platform.pathSeparator}'
      '${relativePath.replaceAll('/', Platform.pathSeparator)}';

  String _relative(String absolutePath) {
    final prefix = '$root${Platform.pathSeparator}';
    return absolutePath.startsWith(prefix)
        ? absolutePath.substring(prefix.length).replaceAll(r'\', '/')
        : absolutePath;
  }
}
