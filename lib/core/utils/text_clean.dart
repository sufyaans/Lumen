/// Cleaning for copy-pasted input (brief section 5.2).
library;

/// Zero-width and invisible formatting characters that sneak in through
/// copy-paste from chat apps, PDFs and web pages.
const _zeroWidth = {
  0x200B, // zero width space
  0x200C, // zero width non-joiner
  0x200D, // zero width joiner
  0x2060, // word joiner
  0xFEFF, // BOM / zero width no-break space
  0x00AD, // soft hyphen
  0x200E, // LRM
  0x200F, // RLM
};

/// Space-like characters that should behave like a normal space.
const _spaceLike = {0x00A0, 0x2007, 0x202F, 0x3000};

bool _isTrimmable(int c) =>
    c == 0x20 ||
    c == 0x09 ||
    c == 0x0A ||
    c == 0x0D ||
    c == 0x0B ||
    c == 0x0C ||
    _spaceLike.contains(c) ||
    _zeroWidth.contains(c);

/// Cleans a pasted address or link: removes invisible characters anywhere,
/// turns no-break spaces into spaces, straightens smart quotes, trims, and
/// removes quotes or angle brackets wrapped around the whole value.
String cleanPastedAddress(String raw) {
  final b = StringBuffer();
  for (final r in raw.runes) {
    if (_zeroWidth.contains(r)) continue;
    if (_spaceLike.contains(r)) {
      b.write(' ');
    } else if (r == 0x201C || r == 0x201D || r == 0x201E || r == 0x2033) {
      b.write('"');
    } else if (r == 0x2018 || r == 0x2019 || r == 0x201A || r == 0x2032) {
      b.write("'");
    } else {
      b.writeCharCode(r);
    }
  }
  var s = b.toString().trim();
  // Strip one layer of wrapping quotes / brackets: "http://x", <http://x>.
  for (final (open, close) in const [
    ('"', '"'),
    ("'", "'"),
    ('<', '>'),
    ('(', ')'),
    ('[', ']'),
  ]) {
    if (s.length >= 2 && s.startsWith(open) && s.endsWith(close)) {
      final inner = s.substring(1, s.length - 1).trim();
      // Don't strip brackets from a bare IPv6 literal like [::1]:8080.
      if (open == '[' && inner.contains(':')) break;
      s = inner;
      break;
    }
  }
  return s;
}

/// Trims whitespace, newlines and zero-width characters from both ends of a
/// username or password. Inner characters are never changed (brief 5.2).
String cleanCredential(String raw) {
  final runes = raw.runes.toList();
  var start = 0;
  var end = runes.length;
  while (start < end && _isTrimmable(runes[start])) {
    start++;
  }
  while (end > start && _isTrimmable(runes[end - 1])) {
    end--;
  }
  return String.fromCharCodes(runes.sublist(start, end));
}

/// True when a credential still contains whitespace after trimming, which
/// is usually a copy-paste mistake. The app shows a gentle hint but still
/// sends the value as typed.
bool hasInnerWhitespace(String cleaned) =>
    cleaned.runes.any((r) => r == 0x20 || r == 0x09 || _spaceLike.contains(r));

/// Decodes the common HTML entities providers leave in names.
String decodeHtmlEntities(String s) {
  if (!s.contains('&')) return s;
  return s.replaceAllMapped(
    RegExp(r'&(#x[0-9a-fA-F]+|#[0-9]+|amp|lt|gt|quot|apos|nbsp|#039);'),
    (m) {
      final e = m.group(1)!;
      switch (e) {
        case 'amp':
          return '&';
        case 'lt':
          return '<';
        case 'gt':
          return '>';
        case 'quot':
          return '"';
        case 'apos':
        case '#039':
          return "'";
        case 'nbsp':
          return ' ';
      }
      final code = e.startsWith('#x')
          ? int.tryParse(e.substring(2), radix: 16)
          : int.tryParse(e.substring(1));
      if (code == null || code <= 0 || code > 0x10FFFF) return m.group(0)!;
      return String.fromCharCode(code);
    },
  );
}
