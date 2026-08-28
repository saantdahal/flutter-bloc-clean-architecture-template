/// One pub package the generated project can depend on.
class PubPackage {
  const PubPackage(
    this.name,
    this.constraint, {
    this.dev = false,
    this.sdk,
    this.reason = '',
  });

  final String name;

  /// Version constraint, e.g. `^5.7.0`. Ignored when [sdk] is set.
  final String constraint;
  final bool dev;

  /// Set for `sdk: flutter` style dependencies.
  final String? sdk;

  /// Shown in `clean_bloc packages` output.
  final String reason;
}

/// Maps modules to the packages they pull in, so the generated pubspec only
/// ever contains dependencies the generated code actually uses.
class PackageRegistry {
  const PackageRegistry._();

  static const List<PubPackage> always = [
    PubPackage('flutter', '', sdk: 'flutter', reason: 'Flutter SDK'),
    PubPackage('flutter_bloc', '^9.1.1', reason: 'State management'),
    PubPackage(
      'bloc_concurrency',
      '^0.3.0',
      reason: 'Event transformers (droppable / restartable)',
    ),
    PubPackage('equatable', '^2.0.5', reason: 'Value equality'),
    PubPackage('get_it', '^7.7.0', reason: 'Service locator'),
    PubPackage('dartz', '^0.10.1', reason: 'Either / functional helpers'),
    PubPackage('cupertino_icons', '^1.0.8', reason: 'Default icon font'),
    PubPackage('flutter_test', '', sdk: 'flutter', dev: true),
    PubPackage('flutter_lints', '^4.0.0', dev: true, reason: 'Lint rules'),
  ];

  static const Map<String, List<PubPackage>> byModule = {
    'network': [
      PubPackage('dio', '^5.7.0', reason: 'HTTP client'),
      PubPackage('pretty_dio_logger', '^1.4.0', reason: 'Request logging'),
    ],
    'connectivity': [
      PubPackage(
        'internet_connection_checker',
        '^1.0.0+1',
        reason: 'NetworkInfo implementation',
      ),
    ],
    'env': [
      PubPackage('flutter_dotenv', '^6.0.0', reason: '.env loading'),
    ],
    'routing': [
      PubPackage('go_router', '^14.2.8', reason: 'Declarative routing'),
    ],
    'localization': [
      PubPackage(
        'easy_localization',
        '^3.0.7',
        reason: 'Translations and locale switching',
      ),
      PubPackage(
        'flutter_localizations',
        '',
        sdk: 'flutter',
        reason: 'Material/Cupertino localizations',
      ),
      PubPackage('intl', 'any', reason: 'Date and number formatting'),
    ],
    'responsive': [
      PubPackage('flutter_screenutil', '^5.9.3', reason: 'Responsive sizing'),
    ],
    'logger': [
      PubPackage('logger', '^2.4.0', reason: 'Structured logging'),
    ],
    'prefs': [
      PubPackage('shared_preferences', '^2.3.2', reason: 'Local cache'),
    ],
    'secure_storage': [
      PubPackage(
        'flutter_secure_storage',
        '^9.2.2',
        reason: 'Encrypted key/value storage',
      ),
    ],
    'firebase': [
      PubPackage('firebase_core', '^4.1.1', reason: 'Firebase bootstrap'),
      PubPackage('firebase_messaging', '^16.0.2', reason: 'Push messages'),
      PubPackage(
        'flutter_local_notifications',
        '^17.2.3',
        reason: 'Foreground notifications',
      ),
    ],
    'flavors': [
      PubPackage(
        'flutter_flavorizr',
        '^2.2.3',
        dev: true,
        reason: 'Flavor scaffolding',
      ),
    ],
  };

  /// Every package for the enabled [modules], with [overrides] applied and
  /// [extra] / [extraDev] appended.
  static List<PubPackage> resolve({
    required Map<String, bool> modules,
    Map<String, String> overrides = const {},
    Map<String, String> extra = const {},
    Map<String, String> extraDev = const {},
  }) {
    final selected = <String, PubPackage>{};

    void add(PubPackage package) {
      final constraint = overrides[package.name] ?? package.constraint;
      selected[package.name] = PubPackage(
        package.name,
        constraint,
        dev: package.dev,
        sdk: package.sdk,
        reason: package.reason,
      );
    }

    for (final package in always) {
      add(package);
    }
    byModule.forEach((module, packages) {
      if (modules[module] == true) {
        for (final package in packages) {
          add(package);
        }
      }
    });
    extra.forEach((name, constraint) {
      selected[name] = PubPackage(name, constraint, reason: 'Custom');
    });
    extraDev.forEach((name, constraint) {
      selected[name] =
          PubPackage(name, constraint, dev: true, reason: 'Custom');
    });

    return selected.values.toList();
  }

  /// The module that owns [packageName], if any - used by `packages --why`.
  static String? moduleFor(String packageName) {
    for (final entry in byModule.entries) {
      if (entry.value.any((p) => p.name == packageName)) return entry.key;
    }
    return always.any((p) => p.name == packageName) ? 'core' : null;
  }
}
