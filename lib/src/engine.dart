/// A tiny mustache-flavoured template engine.
///
/// Supported syntax:
///   {{name}}            variable substitution
///   {{#flag}}...{{/flag}}   render when the value is truthy (or repeat a list)
///   {{^flag}}...{{/flag}}   render when the value is falsy
///   {{.}}               the current item inside a list section
///
/// Section tags that sit alone on a line consume the whole line, so templates
/// stay readable without leaking blank lines into the generated files.
class TemplateEngine {
  const TemplateEngine._();

  static final RegExp _sectionTag = RegExp(r'\{\{([#^/])([\w.]+)\}\}');
  static final RegExp _varTag = RegExp(r'\{\{([\w.]+)\}\}');

  static String render(String template, Map<String, Object?> vars) {
    final buffer = StringBuffer();
    var pos = 0;

    while (pos < template.length) {
      final match = _sectionTag.firstMatch(template.substring(pos));
      if (match == null) {
        buffer.write(_renderVars(template.substring(pos), vars));
        break;
      }

      final tagStart = pos + match.start;
      final tagEnd = pos + match.end;
      final kind = match.group(1)!;
      final name = match.group(2)!;

      if (kind == '/') {
        throw FormatException('Unexpected closing tag {{/$name}}');
      }

      var before = template.substring(pos, tagStart);
      var bodyStart = tagEnd;
      if (_isStandalone(template, tagStart, tagEnd)) {
        before = _trimInlineTrailing(before);
        bodyStart = _skipLineBreak(template, tagEnd);
      }
      buffer.write(_renderVars(before, vars));

      final close = _findClose(template, bodyStart, name);
      final body = template.substring(bodyStart, close.bodyEnd);
      final value = vars[name];

      if (kind == '^') {
        if (!_truthy(value)) buffer.write(render(body, vars));
      } else if (value is List) {
        for (final item in value) {
          final scope = Map<String, Object?>.from(vars);
          if (item is Map) {
            scope.addAll(item.map((k, v) => MapEntry(k.toString(), v)));
          }
          scope['.'] = item;
          buffer.write(render(body, scope));
        }
      } else if (_truthy(value)) {
        buffer.write(render(body, vars));
      }

      pos = close.resumeAt;
    }

    return buffer.toString();
  }

  static String _renderVars(String text, Map<String, Object?> vars) {
    return text.replaceAllMapped(_varTag, (m) {
      final key = m.group(1)!;
      if (!vars.containsKey(key)) {
        throw FormatException('Unknown template variable {{$key}}');
      }
      final value = vars[key];
      return value == null ? '' : value.toString();
    });
  }

  static _Close _findClose(String template, int from, String name) {
    var depth = 1;
    var cursor = from;

    while (cursor < template.length) {
      final match = _sectionTag.firstMatch(template.substring(cursor));
      if (match == null) break;

      final tagStart = cursor + match.start;
      final tagEnd = cursor + match.end;
      final kind = match.group(1)!;
      final tagName = match.group(2)!;

      if (tagName == name) {
        depth += kind == '/' ? -1 : 1;
        if (depth == 0) {
          var bodyEnd = tagStart;
          var resumeAt = tagEnd;
          if (_isStandalone(template, tagStart, tagEnd)) {
            bodyEnd = tagStart - (_trimmedInlineLength(template, tagStart));
            resumeAt = _skipLineBreak(template, tagEnd);
          }
          return _Close(bodyEnd, resumeAt);
        }
      }
      cursor = tagEnd;
    }

    throw FormatException('Missing closing tag {{/$name}}');
  }

  /// A tag is "standalone" when only whitespace precedes it on its line and a
  /// line break follows it.
  static bool _isStandalone(String template, int start, int end) {
    var i = start - 1;
    while (i >= 0 && (template[i] == ' ' || template[i] == '\t')) {
      i--;
    }
    final atLineStart = i < 0 || template[i] == '\n';

    var j = end;
    while (j < template.length &&
        (template[j] == ' ' || template[j] == '\t')) {
      j++;
    }
    final atLineEnd = j >= template.length ||
        template[j] == '\n' ||
        (template[j] == '\r' &&
            j + 1 < template.length &&
            template[j + 1] == '\n');

    return atLineStart && atLineEnd;
  }

  static int _skipLineBreak(String template, int end) {
    var j = end;
    while (j < template.length &&
        (template[j] == ' ' || template[j] == '\t')) {
      j++;
    }
    if (j < template.length && template[j] == '\r') j++;
    if (j < template.length && template[j] == '\n') j++;
    return j;
  }

  static String _trimInlineTrailing(String text) {
    var end = text.length;
    while (end > 0 && (text[end - 1] == ' ' || text[end - 1] == '\t')) {
      end--;
    }
    return text.substring(0, end);
  }

  static int _trimmedInlineLength(String template, int tagStart) {
    var count = 0;
    var i = tagStart - 1;
    while (i >= 0 && (template[i] == ' ' || template[i] == '\t')) {
      count++;
      i--;
    }
    return count;
  }

  static bool _truthy(Object? value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value.isNotEmpty;
    if (value is Iterable) return value.isNotEmpty;
    if (value is Map) return value.isNotEmpty;
    return true;
  }
}

class _Close {
  const _Close(this.bodyEnd, this.resumeAt);

  final int bodyEnd;
  final int resumeAt;
}
