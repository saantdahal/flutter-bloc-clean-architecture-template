import 'dart:io';

/// Writes generated files, honouring `--dry-run` and `--force`, and records a
/// summary so the CLI can report exactly what happened.
class ProjectWriter {
  ProjectWriter({
    required this.root,
    this.dryRun = false,
    this.force = false,
    this.quiet = false,
  });

  final String root;
  final bool dryRun;
  final bool force;
  final bool quiet;

  final List<String> created = [];
  final List<String> overwritten = [];
  final List<String> skipped = [];
  final List<String> patched = [];

  String pathFor(String relativePath) =>
      '$root${Platform.pathSeparator}${relativePath.replaceAll('/', Platform.pathSeparator)}';

  bool exists(String relativePath) => File(pathFor(relativePath)).existsSync();

  void write(String relativePath, String content) {
    final file = File(pathFor(relativePath));
    final alreadyExists = file.existsSync();

    if (alreadyExists && !force) {
      skipped.add(relativePath);
      _log('  skip      $relativePath (exists, use --force to overwrite)');
      return;
    }

    if (!dryRun) {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(_normalize(content));
    }

    if (alreadyExists) {
      overwritten.add(relativePath);
      _log('  overwrite $relativePath');
    } else {
      created.add(relativePath);
      _log('  create    $relativePath');
    }
  }

  void copyBytes(String relativePath, List<int> bytes) {
    final file = File(pathFor(relativePath));
    if (file.existsSync() && !force) {
      skipped.add(relativePath);
      return;
    }
    if (!dryRun) {
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(bytes);
    }
    created.add(relativePath);
    _log('  create    $relativePath');
  }

  /// Inserts [insertion] immediately above the line containing [marker].
  ///
  /// No-op when the file is missing, the marker is absent, or the insertion is
  /// already present - so re-running the generator stays safe.
  PatchResult insertBefore(
    String relativePath,
    String marker,
    String insertion, {
    String? uniqueBy,
  }) {
    final file = File(pathFor(relativePath));
    if (!file.existsSync()) {
      return PatchResult.missingFile;
    }

    final content = file.readAsStringSync();
    if (content.contains(uniqueBy ?? insertion.trim())) {
      return PatchResult.alreadyPresent;
    }
    final markerIndex = content.indexOf(marker);
    if (markerIndex == -1) {
      return PatchResult.missingMarker;
    }

    final lineStart = content.lastIndexOf('\n', markerIndex) + 1;
    final indent = RegExp(r'^[ \t]*')
        .stringMatch(content.substring(lineStart, markerIndex))!;
    final block = insertion
        .trimRight()
        .split('\n')
        .map((line) => line.isEmpty ? line : '$indent$line')
        .join('\n');

    final updated = content.replaceRange(lineStart, lineStart, '$block\n');
    if (!dryRun) {
      file.writeAsStringSync(updated);
    }
    patched.add(relativePath);
    _log('  update    $relativePath');
    return PatchResult.applied;
  }

  String summary() {
    final parts = <String>[];
    if (created.isNotEmpty) parts.add('${created.length} created');
    if (overwritten.isNotEmpty) parts.add('${overwritten.length} overwritten');
    if (patched.isNotEmpty) parts.add('${patched.length} updated');
    if (skipped.isNotEmpty) parts.add('${skipped.length} skipped');
    return parts.isEmpty ? 'nothing to do' : parts.join(', ');
  }

  static String _normalize(String content) {
    var text = content.replaceAll('\r\n', '\n');
    // Collapse the blank-line runs that conditional blocks can leave behind.
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    text = text.replaceAll(RegExp(r'[ \t]+\n'), '\n');
    if (!text.endsWith('\n')) text += '\n';
    return text;
  }

  void _log(String message) {
    if (!quiet) stdout.writeln(message);
  }
}

enum PatchResult { applied, alreadyPresent, missingMarker, missingFile }
