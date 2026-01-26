/// HTML Utility Functions
///
/// Provides utilities for cleaning and processing HTML content
/// for display in the mobile app.

/// Removes HTML tags from text and returns clean plain text.
///
/// Example:
/// ```dart
/// String dirty = '<div class="ql-editor"><p>Hello <b>World</b></p></div>';
/// String clean = stripHtmlTags(dirty);  // Returns: "Hello World"
/// ```
String stripHtmlTags(String? htmlText) {
  if (htmlText == null || htmlText.isEmpty) {
    return '';
  }

  String text = htmlText;

  // Remove all HTML tags
  text = text.replaceAll(RegExp(r'<[^>]*>'), '');

  // Decode common HTML entities
  text = _decodeHtmlEntities(text);

  // Remove extra whitespace
  text = text.replaceAll(RegExp(r'\s+'), ' ');

  // Trim leading and trailing whitespace
  return text.trim();
}

/// Decodes common HTML entities to their character equivalents.
String _decodeHtmlEntities(String text) {
  final entities = {
    '&nbsp;': ' ',
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&#39;': "'",
    '&apos;': "'",
    '&cent;': '¢',
    '&pound;': '£',
    '&yen;': '¥',
    '&euro;': '€',
    '&copy;': '©',
    '&reg;': '®',
  };

  String result = text;
  entities.forEach((entity, replacement) {
    result = result.replaceAll(entity, replacement);
  });

  return result;
}

/// Truncates HTML text to a specified length and adds ellipsis.
/// Strips HTML tags before truncating.
///
/// Example:
/// ```dart
/// String long = '<p>This is a very long description...</p>';
/// String short = truncateHtmlText(long, 50);  // "This is a very long description..."
/// ```
String truncateHtmlText(String? htmlText, int maxLength) {
  if (htmlText == null || htmlText.isEmpty) {
    return '';
  }

  final cleanText = stripHtmlTags(htmlText);

  if (cleanText.length <= maxLength) {
    return cleanText;
  }

  return '${cleanText.substring(0, maxLength)}...';
}

/// Checks if a string contains HTML tags.
bool containsHtml(String? text) {
  if (text == null || text.isEmpty) {
    return false;
  }

  return RegExp(r'<[^>]*>').hasMatch(text);
}

/// Sanitizes HTML text for safe display.
/// Removes script tags and dangerous content.
String sanitizeHtml(String? htmlText) {
  if (htmlText == null || htmlText.isEmpty) {
    return '';
  }

  String text = htmlText;

  // Remove script tags and their content
  text = text.replaceAll(
    RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false),
    '',
  );

  // Remove style tags and their content
  text = text.replaceAll(
    RegExp(r'<style[^>]*>.*?</style>', caseSensitive: false),
    '',
  );

  // Remove iframe tags
  text = text.replaceAll(
    RegExp(r'<iframe[^>]*>.*?</iframe>', caseSensitive: false),
    '',
  );

  return text;
}
