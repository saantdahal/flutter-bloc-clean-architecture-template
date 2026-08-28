/// Minimal command-line parser: `--flag`, `--no-flag`, `--key value`,
/// `--key=value`, short aliases and positional arguments.
class ArgResults {
  ArgResults(this.command, this.rest, this._options, this._flags);

  final String? command;
  final List<String> rest;
  final Map<String, String> _options;
  final Map<String, bool> _flags;

  String? option(String name) => _options[name];

  bool? flag(String name) => _flags[name];

  bool has(String name) =>
      _options.containsKey(name) || _flags.containsKey(name);

  Map<String, String> get options => Map.unmodifiable(_options);

  Map<String, bool> get flags => Map.unmodifiable(_flags);
}

class ArgParser {
  ArgParser({
    required this.valueOptions,
    required this.booleanFlags,
    this.aliases = const {},
  });

  /// Options that consume the following argument as their value.
  final Set<String> valueOptions;

  /// Options usable as `--x` / `--no-x`.
  final Set<String> booleanFlags;

  /// Short or alternative spellings mapped to canonical names.
  final Map<String, String> aliases;

  ArgResults parse(List<String> args) {
    final options = <String, String>{};
    final flags = <String, bool>{};
    final positional = <String>[];

    for (var i = 0; i < args.length; i++) {
      final arg = args[i];

      if (arg == '--') {
        positional.addAll(args.sublist(i + 1));
        break;
      }

      if (!arg.startsWith('-')) {
        positional.add(arg);
        continue;
      }

      var name = arg.replaceFirst(RegExp('^--?'), '');
      String? inlineValue;
      final eq = name.indexOf('=');
      if (eq != -1) {
        inlineValue = name.substring(eq + 1);
        name = name.substring(0, eq);
      }
      name = aliases[name] ?? name;

      var negated = false;
      if (name.startsWith('no-') && booleanFlags.contains(name.substring(3))) {
        negated = true;
        name = name.substring(3);
      }

      if (booleanFlags.contains(name)) {
        if (inlineValue != null) {
          flags[name] = inlineValue.toLowerCase() != 'false';
        } else {
          flags[name] = !negated;
        }
        continue;
      }

      if (valueOptions.contains(name)) {
        if (inlineValue != null) {
          options[name] = inlineValue;
        } else if (i + 1 < args.length) {
          options[name] = args[++i];
        } else {
          throw FormatException('Option --$name expects a value.');
        }
        continue;
      }

      throw FormatException('Unknown option "$arg".');
    }

    final command = positional.isEmpty ? null : positional.first;
    final rest = positional.isEmpty
        ? const <String>[]
        : positional.sublist(1);
    return ArgResults(command, rest, options, flags);
  }
}
