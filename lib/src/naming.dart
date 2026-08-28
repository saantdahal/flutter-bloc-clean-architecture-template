/// Name casing helpers shared by the project and feature generators.
class Naming {
  const Naming._();

  static final RegExp _separators = RegExp(r'[\s\-_.]+');
  static final RegExp _camelBoundary = RegExp(r'(?<=[a-z0-9])(?=[A-Z])');

  static List<String> words(String input) {
    return input
        .split(_separators)
        .expand((part) => part.split(_camelBoundary))
        .where((part) => part.isNotEmpty)
        .map((part) => part.toLowerCase())
        .toList();
  }

  static String snake(String input) => words(input).join('_');

  static String pascal(String input) =>
      words(input).map(_capitalize).join();

  static String camel(String input) {
    final p = pascal(input);
    return p.isEmpty ? p : p[0].toLowerCase() + p.substring(1);
  }

  static String title(String input) =>
      words(input).map(_capitalize).join(' ');

  static String kebab(String input) => words(input).join('-');

  /// Naive English pluralisation - good enough for identifiers like
  /// `getProducts` / `getCategories`.
  static String plural(String singular) {
    if (singular.isEmpty) return singular;
    const vowels = 'aeiou';
    final last = singular[singular.length - 1];
    final beforeLast =
        singular.length > 1 ? singular[singular.length - 2] : '';

    if (last == 'y' && !vowels.contains(beforeLast)) {
      return '${singular.substring(0, singular.length - 1)}ies';
    }
    if (singular.endsWith('s') ||
        singular.endsWith('x') ||
        singular.endsWith('z') ||
        singular.endsWith('ch') ||
        singular.endsWith('sh')) {
      return '${singular}es';
    }
    return '${singular}s';
  }

  static String _capitalize(String word) =>
      word.isEmpty ? word : word[0].toUpperCase() + word.substring(1);

  /// Dart package / directory names must be valid lower_snake_case identifiers.
  static String? validateIdentifier(String value, String label) {
    if (value.isEmpty) return '$label must not be empty.';
    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(value)) {
      return '$label "$value" must be lower_snake_case '
          '(letters, digits and underscores, starting with a letter).';
    }
    const reserved = {
      'abstract', 'as', 'assert', 'async', 'await', 'break', 'case', 'catch',
      'class', 'const', 'continue', 'default', 'deferred', 'do', 'dynamic',
      'else', 'enum', 'export', 'extends', 'extension', 'external', 'factory',
      'false', 'final', 'finally', 'for', 'function', 'get', 'hide', 'if',
      'implements', 'import', 'in', 'interface', 'is', 'library', 'mixin',
      'new', 'null', 'on', 'operator', 'part', 'rethrow', 'return', 'set',
      'show', 'static', 'super', 'switch', 'sync', 'this', 'throw', 'true',
      'try', 'typedef', 'var', 'void', 'while', 'with', 'yield', 'test',
      'flutter',
    };
    if (reserved.contains(value)) {
      return '$label "$value" is a reserved word.';
    }
    return null;
  }

  /// Android `applicationId` / `namespace` rules: dot separated segments,
  /// each starting with a letter, no dashes.
  static String? validateAndroidPackage(String value) {
    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$')
        .hasMatch(value)) {
      return 'Android package "$value" must be dot separated, with each '
          'segment starting with a letter and containing only letters, '
          'digits or underscores (e.g. com.example.my_app).';
    }
    return null;
  }

  /// iOS/macOS bundle identifiers allow dashes but not underscores.
  static String? validateBundleId(String value) {
    if (!RegExp(r'^[A-Za-z][A-Za-z0-9-]*(\.[A-Za-z0-9-]+)+$')
        .hasMatch(value)) {
      return 'iOS bundle id "$value" must be dot separated using letters, '
          'digits or dashes (e.g. com.example.myApp).';
    }
    if (value.contains('_')) {
      return 'iOS bundle id "$value" must not contain underscores; '
          'Xcode rejects them.';
    }
    return null;
  }

  static String? validateOrg(String value) {
    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$')
        .hasMatch(value)) {
      return 'Organisation "$value" must look like a reverse domain, '
          'e.g. com.example.';
    }
    return null;
  }
}
