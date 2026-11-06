/// Adult and kids category detection from provider category names
/// (brief section 6). Names are free text, so this is a keyword match on
/// word boundaries ("Essex" is not adult, "XXX" is).
library;

final _adult = RegExp(
  r'(\badult|\bxxx|18\s*\+|\+\s*18|\bporn|\berotic|\berotik|\bsex\b|'
  r'\bsexy\b|\bplayboy|\bhustler|\bbrazzers|\bnsfw|\badulte|\badulto|'
  r'\bfor adults|\bhot\s?club|\bred\s?light)',
  caseSensitive: false,
  unicode: true,
);

final _kids = RegExp(
  r'(\bkids?\b|\bchild|\bcartoon|\banime\b|\bfamily\b|\bjunior|\bdisney|'
  r'\bnick|\btoon|\bbaby|\binfantil|\benfant|\bkinder|\bbambini|'
  r'\bçocuk|\bcocuk|\bniños|\bninos)',
  caseSensitive: false,
  unicode: true,
);

bool isAdultCategory(String name) => _adult.hasMatch(name);

bool isKidsCategory(String name) =>
    !isAdultCategory(name) && _kids.hasMatch(name);

/// What a profile is allowed to see.
class ContentFilter {
  const ContentFilter({this.hideAdult = true, this.kidsOnly = false});

  /// Adult categories hidden (default; a PIN-protected setting reveals).
  final bool hideAdult;

  /// Kids profiles: only kids-appropriate categories where the provider's
  /// names allow it.
  final bool kidsOnly;

  static const standard = ContentFilter();
  static const kids = ContentFilter(kidsOnly: true);
}
