import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/pref_keys.dart';

/// A saved snippet. Mirrors `QuickText` in android/.../texts/QuickTexts.kt.
class QuickText extends Equatable {
  const QuickText({required this.id, required this.title, required this.text});

  factory QuickText.fromJson(Map<String, Object?> json) => QuickText(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        text: json['text'] as String? ?? '',
      );

  final String id;

  /// Optional; the first line of [text] is shown when empty.
  final String title;
  final String text;

  String get displayTitle {
    if (title.trim().isNotEmpty) return title.trim();
    final firstLine = text.trim().split('\n').first;
    return firstLine.length > 60 ? '${firstLine.substring(0, 60)}…' : firstLine;
  }

  Map<String, Object?> toJson() => {'id': id, 'title': title, 'text': text};

  @override
  List<Object?> get props => [id, title, text];
}

/// Stores snippets where the Quick texts tile reads them.
class QuickTextsRepository {
  const QuickTextsRepository();

  /// Shown until the user saves their own list (deleting it saves an empty list, so it stays gone).
  /// Keep in sync with `QuickTexts.DEFAULTS` in QuickTexts.kt.
  static const defaults = [QuickText(id: 'welcome', title: 'Welcome', text: 'Welcome to Switchly')];

  Future<List<QuickText>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(PrefKeys.quickTexts);
    if (raw == null) return defaults;
    try {
      return [for (final t in jsonDecode(raw) as List) QuickText.fromJson(t as Map<String, Object?>)];
    } on Object {
      return const [];
    }
  }

  Future<void> save(List<QuickText> texts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.quickTexts, jsonEncode([for (final t in texts) t.toJson()]));
  }
}
