import 'dart:io';

/// Small stdin helpers for the interactive setup.
class Prompts {
  Prompts({this.enabled = true});

  final bool enabled;

  String ask(
    String label, {
    required String defaultValue,
    String? Function(String value)? validate,
  }) {
    if (!enabled) return defaultValue;

    while (true) {
      stdout.write('  $label ${_hint(defaultValue)}: ');
      final input = stdin.readLineSync()?.trim() ?? '';
      final value = input.isEmpty ? defaultValue : input;
      final error = validate?.call(value);
      if (error == null) return value;
      stdout.writeln('    ! $error');
    }
  }

  bool confirm(String label, {required bool defaultValue}) {
    if (!enabled) return defaultValue;

    final hint = defaultValue ? 'Y/n' : 'y/N';
    while (true) {
      stdout.write('  $label [$hint]: ');
      final input = (stdin.readLineSync() ?? '').trim().toLowerCase();
      if (input.isEmpty) return defaultValue;
      if (input == 'y' || input == 'yes') return true;
      if (input == 'n' || input == 'no') return false;
      stdout.writeln('    ! Answer y or n.');
    }
  }

  String choose(
    String label,
    List<String> options, {
    required String defaultValue,
  }) {
    if (!enabled) return defaultValue;

    while (true) {
      stdout.write('  $label (${options.join('/')}) '
          '${_hint(defaultValue)}: ');
      final input = (stdin.readLineSync() ?? '').trim().toLowerCase();
      if (input.isEmpty) return defaultValue;
      if (options.contains(input)) return input;
      stdout.writeln('    ! Choose one of ${options.join(', ')}.');
    }
  }

  List<String> askList(
    String label, {
    required List<String> defaultValue,
    String? Function(String value)? validateItem,
  }) {
    if (!enabled) return defaultValue;

    while (true) {
      stdout.write('  $label ${_hint(defaultValue.join(','))}: ');
      final input = (stdin.readLineSync() ?? '').trim();
      final values = input.isEmpty
          ? defaultValue
          : input
              .split(RegExp(r'[,\s]+'))
              .where((value) => value.isNotEmpty)
              .toList();

      final errors = values
          .map((value) => validateItem?.call(value))
          .whereType<String>()
          .toList();
      if (errors.isEmpty) return values;
      for (final error in errors) {
        stdout.writeln('    ! $error');
      }
    }
  }

  void section(String title) {
    if (!enabled) return;
    stdout
      ..writeln()
      ..writeln(title)
      ..writeln('-' * title.length);
  }

  static String _hint(String value) => value.isEmpty ? '' : '[$value]';
}
