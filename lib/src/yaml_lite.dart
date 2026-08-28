/// A deliberately small YAML reader/writer covering the subset used by
/// `clean_bloc.yaml`: nested maps (two levels), scalars and inline/blocked
/// string lists. Keeping it in-tree means the generator has zero dependencies.
class YamlLite {
  const YamlLite._();

  static Map<String, Object?> parse(String source) {
    final root = <String, Object?>{};
    final stack = <_Level>[_Level(-1, root)];
    List<Object?>? pendingList;
    var pendingListIndent = -1;

    for (final rawLine in source.split('\n')) {
      final line = rawLine.replaceAll('\r', '');
      final withoutComment = _stripComment(line);
      if (withoutComment.trim().isEmpty) continue;

      final indent = withoutComment.length - withoutComment.trimLeft().length;
      final content = withoutComment.trim();

      if (content.startsWith('- ')) {
        if (pendingList == null || indent < pendingListIndent) {
          throw FormatException('Unexpected list item: "$content"');
        }
        pendingList.add(_scalar(content.substring(2).trim()));
        continue;
      }

      pendingList = null;
      pendingListIndent = -1;

      final colon = content.indexOf(':');
      if (colon == -1) {
        throw FormatException('Expected "key: value" but found "$content"');
      }
      final key = content.substring(0, colon).trim();
      final value = content.substring(colon + 1).trim();

      while (stack.length > 1 && indent <= stack.last.indent) {
        stack.removeLast();
      }
      final parent = stack.last.map;

      if (value.isEmpty) {
        final child = <String, Object?>{};
        parent[key] = child;
        stack.add(_Level(indent, child));
        // The block may turn out to be a list instead of a map.
        pendingList = <Object?>[];
        pendingListIndent = indent;
        parent[key] = _PendingBlock(child, pendingList);
      } else if (value.startsWith('[') && value.endsWith(']')) {
        final inner = value.substring(1, value.length - 1).trim();
        parent[key] = inner.isEmpty
            ? <Object?>[]
            : inner.split(',').map((e) => _scalar(e.trim())).toList();
      } else {
        parent[key] = _scalar(value);
      }
    }

    return _resolve(root);
  }

  static Map<String, Object?> _resolve(Map<String, Object?> map) {
    final result = <String, Object?>{};
    map.forEach((key, value) {
      if (value is _PendingBlock) {
        result[key] =
            value.list.isNotEmpty ? value.list : _resolve(value.map);
      } else if (value is Map<String, Object?>) {
        result[key] = _resolve(value);
      } else {
        result[key] = value;
      }
    });
    return result;
  }

  static String _stripComment(String line) {
    var inSingle = false;
    var inDouble = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == "'" && !inDouble) inSingle = !inSingle;
      if (ch == '"' && !inSingle) inDouble = !inDouble;
      if (ch == '#' && !inSingle && !inDouble) {
        final prev = i > 0 ? line[i - 1] : ' ';
        if (prev == ' ' || i == 0) return line.substring(0, i);
      }
    }
    return line;
  }

  static Object? _scalar(String raw) {
    if (raw.isEmpty) return '';
    if ((raw.startsWith('"') && raw.endsWith('"')) ||
        (raw.startsWith("'") && raw.endsWith("'"))) {
      return raw.substring(1, raw.length - 1);
    }
    final lower = raw.toLowerCase();
    if (lower == 'true' || lower == 'yes') return true;
    if (lower == 'false' || lower == 'no') return false;
    if (lower == 'null' || lower == '~') return null;
    final asInt = int.tryParse(raw);
    if (asInt != null) return asInt;
    return raw;
  }
}

class _Level {
  _Level(this.indent, this.map);

  final int indent;
  final Map<String, Object?> map;
}

class _PendingBlock {
  _PendingBlock(this.map, this.list);

  final Map<String, Object?> map;
  final List<Object?> list;
}
