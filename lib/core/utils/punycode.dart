/// Minimal RFC 3492 Punycode encoder for internationalised host names.
/// Dart's [Uri] percent-encodes non-ASCII hosts instead of converting them
/// to `xn--` labels, which servers and DNS don't understand.
library;

const _base = 36;
const _tMin = 1;
const _tMax = 26;
const _skew = 38;
const _damp = 700;
const _initialBias = 72;
const _initialN = 128;

int _adapt(int delta, int numPoints, bool firstTime) {
  var d = firstTime ? delta ~/ _damp : delta >> 1;
  d += d ~/ numPoints;
  var k = 0;
  while (d > ((_base - _tMin) * _tMax) >> 1) {
    d ~/= _base - _tMin;
    k += _base;
  }
  return k + (_base - _tMin + 1) * d ~/ (d + _skew);
}

String _digit(int d) => String.fromCharCode(d < 26 ? 97 + d : 22 + d);

/// Encodes one label (no dots). Throws [FormatException] on overflow.
String punycodeEncodeLabel(String label) {
  final input = label.runes.toList();
  final out = StringBuffer();
  for (final c in input) {
    if (c < 0x80) out.writeCharCode(c);
  }
  final basicLength = out.length;
  var h = basicLength;
  if (basicLength > 0) out.write('-');

  var n = _initialN;
  var delta = 0;
  var bias = _initialBias;
  while (h < input.length) {
    var m = 0x7FFFFFFF;
    for (final c in input) {
      if (c >= n && c < m) m = c;
    }
    delta += (m - n) * (h + 1);
    if (delta < 0) throw const FormatException('punycode overflow');
    n = m;
    for (final c in input) {
      if (c < n) delta++;
      if (c == n) {
        var q = delta;
        for (var k = _base; ; k += _base) {
          final t = k <= bias ? _tMin : (k >= bias + _tMax ? _tMax : k - bias);
          if (q < t) break;
          out.write(_digit(t + (q - t) % (_base - t)));
          q = (q - t) ~/ (_base - t);
        }
        out.write(_digit(q));
        bias = _adapt(delta, h + 1, h == basicLength);
        delta = 0;
        h++;
      }
    }
    delta++;
    n++;
  }
  return out.toString();
}

/// Converts a Unicode host to its ASCII (IDNA) form, label by label.
/// ASCII labels are only lowercased.
String hostToAscii(String host) {
  return host
      .split('.')
      .map((label) {
        final lower = label.toLowerCase();
        if (lower.runes.every((r) => r < 0x80)) return lower;
        return 'xn--${punycodeEncodeLabel(lower)}';
      })
      .join('.');
}
