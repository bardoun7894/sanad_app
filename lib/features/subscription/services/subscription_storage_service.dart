import 'package:hive_flutter/hive_flutter.dart';
import '../models/subscription_status.dart';

/// Service for storing subscription status locally
class SubscriptionStorageService {
  static const String _boxName = 'subscription';
  static const String _statusKey = 'subscription_status';

  late Box<String> _box;

  /// Initialize the service
  Future<void> initialize() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  /// Save subscription status
  Future<void> saveStatus(SubscriptionStatus status) async {
    final json = status.toJson();
    await _box.put(_statusKey, _jsonEncode(json));
  }

  /// Get stored subscription status
  Future<SubscriptionStatus> getStatus() async {
    final jsonString = _box.get(_statusKey);
    if (jsonString == null) {
      return SubscriptionStatus.free();
    }

    try {
      final json = _jsonDecode(jsonString);
      return SubscriptionStatus.fromJson(json);
    } catch (e) {
      // If parsing fails, return free status
      return SubscriptionStatus.free();
    }
  }

  /// Clear stored status
  Future<void> clearStatus() async {
    await _box.delete(_statusKey);
  }

  /// Check if any subscription data exists
  bool hasStoredStatus() {
    return _box.containsKey(_statusKey);
  }

  /// Helper to encode JSON to string
  String _jsonEncode(Map<String, dynamic> json) {
    // Simple JSON encoding without external dependency
    final buffer = StringBuffer('{');
    final entries = json.entries.toList();
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      buffer.write('"${entry.key}":');

      final value = entry.value;
      if (value == null) {
        buffer.write('null');
      } else if (value is String) {
        buffer.write('"${value.replaceAll('"', '\\"')}"');
      } else if (value is bool) {
        buffer.write(value ? 'true' : 'false');
      } else if (value is num) {
        buffer.write(value);
      } else {
        buffer.write('null');
      }

      if (i < entries.length - 1) {
        buffer.write(',');
      }
    }
    buffer.write('}');
    return buffer.toString();
  }

  /// Helper to decode JSON from string
  Map<String, dynamic> _jsonDecode(String jsonString) {
    // Simple JSON decoding - for production use json package
    // This is a basic implementation to avoid external dependencies
    final result = <String, dynamic>{};

    // Remove outer braces
    String content = jsonString.trim();
    if (content.startsWith('{')) content = content.substring(1);
    if (content.endsWith('}')) content = content.substring(0, content.length - 1);

    if (content.isEmpty) return result;

    // Parse key-value pairs
    final pairs = _splitJsonPairs(content);
    for (final pair in pairs) {
      final colonIndex = pair.indexOf(':');
      if (colonIndex == -1) continue;

      final keyPart = pair.substring(0, colonIndex).trim();
      final valuePart = pair.substring(colonIndex + 1).trim();

      // Remove quotes from key
      final key =
          keyPart.startsWith('"') && keyPart.endsWith('"')
              ? keyPart.substring(1, keyPart.length - 1)
              : keyPart;

      // Parse value
      dynamic value;
      if (valuePart == 'null') {
        value = null;
      } else if (valuePart == 'true') {
        value = true;
      } else if (valuePart == 'false') {
        value = false;
      } else if (valuePart.startsWith('"') && valuePart.endsWith('"')) {
        value = valuePart.substring(1, valuePart.length - 1);
      } else {
        value = num.tryParse(valuePart);
      }

      result[key] = value;
    }

    return result;
  }

  /// Helper to split JSON pairs
  List<String> _splitJsonPairs(String content) {
    final pairs = <String>[];
    final current = StringBuffer();
    bool inQuotes = false;
    int braceDepth = 0;
    int bracketDepth = 0;

    for (int i = 0; i < content.length; i++) {
      final char = content[i];

      if (char == '"' && (i == 0 || content[i - 1] != '\\')) {
        inQuotes = !inQuotes;
      }

      if (!inQuotes) {
        if (char == '{') braceDepth++;
        if (char == '}') braceDepth--;
        if (char == '[') bracketDepth++;
        if (char == ']') bracketDepth--;

        if (char == ',' && braceDepth == 0 && bracketDepth == 0) {
          pairs.add(current.toString());
          current.clear();
          continue;
        }
      }

      current.write(char);
    }

    if (current.isNotEmpty) {
      pairs.add(current.toString());
    }

    return pairs;
  }
}
