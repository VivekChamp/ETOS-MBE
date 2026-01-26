# 🛠️ HTML Utils - Flutter Utility Functions

## 📦 Location
`lib/core/utils/html_utils.dart`

## 🎯 Purpose
Reusable utility functions for cleaning HTML content anywhere in the Flutter app.

---

## 📋 Available Functions

### **1. stripHtmlTags()**
Removes all HTML tags from text and returns clean plain text.

#### Usage:
```dart
import 'package:e_scooter/core/utils/html_utils.dart';

String dirty = '<div class="ql-editor"><p>Hello <b>World</b></p></div>';
String clean = stripHtmlTags(dirty);
print(clean);  // Output: "Hello World"
```

#### Features:
- ✅ Removes all HTML tags
- ✅ Decodes HTML entities (&nbsp;, &amp;, etc.)
- ✅ Removes extra whitespace
- ✅ Returns empty string for null input

---

### **2. truncateHtmlText()**
Strips HTML and truncates text to specified length with ellipsis.

#### Usage:
```dart
String long = '<p>This is a very long description that needs to be shortened</p>';
String short = truncateHtmlText(long, 30);
print(short);  // Output: "This is a very long descrip..."
```

---

### **3. containsHtml()**
Checks if a string contains HTML tags.

#### Usage:
```dart
String text = '<p>Hello</p>';
bool hasHtml = containsHtml(text);
print(hasHtml);  // Output: true
```

---

### **4. sanitizeHtml()**
Removes dangerous HTML content (scripts, iframes).

#### Usage:
```dart
String dangerous = '<script>alert("XSS")</script><p>Safe content</p>';
String safe = sanitizeHtml(dangerous);
print(safe);  // Output: "<p>Safe content</p>"
```

---

## 🎨 Example Usage in Widgets

### **Example 1: Clean task description**
```dart
import 'package:e_scooter/core/utils/html_utils.dart';

class TaskCard extends StatelessWidget {
  final String description;
  
  @override
  Widget build(BuildContext context) {
    return Text(
      stripHtmlTags(description),  // ✅ Clean HTML
      style: TextStyle(fontSize: 14),
    );
  }
}
```

### **Example 2: Display truncated note**
```dart
import 'package:e_scooter/core/utils/html_utils.dart';

ListTile(
  title: Text(task.subject),
  subtitle: Text(
    truncateHtmlText(task.description, 100),  // ✅ Clean & truncate
  ),
)
```

### **Example 3: Conditional cleaning**
```dart
import 'package:e_scooter/core/utils/html_utils.dart';

String displayText(String text) {
  if (containsHtml(text)) {
    return stripHtmlTags(text);  // Clean if has HTML
  }
  return text;  // Return as-is
}
```

---

## 🔄 Easy Import

Instead of importing the full path, use the barrel export:

```dart
// ✅ Easy way
import 'package:e_scooter/core/utils/utils.dart';

String clean = stripHtmlTags(dirty);
```

---

## 📊 Supported HTML Entities

The utility decodes these common entities:

| Entity | Character |
|--------|-----------|
| `&nbsp;` | (space) |
| `&amp;` | & |
| `&lt;` | < |
| `&gt;` | > |
| `&quot;` | " |
| `&#39;` | ' |
| `&copy;` | © |
| `&reg;` | ® |
| `&euro;` | € |

---

## ✅ Best Practices

1. **Always clean user-generated content:**
   ```dart
   Text(stripHtmlTags(userInput))
   ```

2. **Use in repositories for consistency:**
   ```dart
   task['description'] = stripHtmlTags(task['description']);
   ```

3. **Combine with null safety:**
   ```dart
   String cleanDesc = stripHtmlTags(task.description ?? '');
   ```

---

## 🎯 When to Use

| Scenario | Function |
|----------|----------|
| Display task description | `stripHtmlTags()` |
| Show lead notes | `stripHtmlTags()` |
| Preview long text | `truncateHtmlText()` |
| Validate input | `containsHtml()` |
| Security filtering | `sanitizeHtml()` |

---

## 🚀 Performance

- ✅ **Fast**: Pure Dart regex, no external dependencies
- ✅ **Safe**: Null-safe, handles edge cases
- ✅ **Reusable**: Use anywhere in the app

---

**இப்ப எங்க வேணும்னாலும் use பண்ணலாம்!** 🎉
