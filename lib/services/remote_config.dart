import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

/// الإعدادات القادمة من السيرفر — أي تعديل على remote/config.json
/// في المستودع يغيّر شكل وسلوك التطبيق بدون تحديث.
class RemoteConfig {
  final int configVersion;
  final String appTitle;
  final Color primaryColor;
  final bool darkMode;
  final bool announcementEnabled;
  final String announcementText;
  final Color announcementColor;
  final bool featurePriorities;
  final bool featureDueDates;
  final bool featureCategories;
  final bool featureStats;
  final List<String> categories;
  final String emptyMessage;
  final String addHint;

  const RemoteConfig({
    this.configVersion = 0,
    this.appTitle = 'مهامي',
    this.primaryColor = const Color(0xFF4F46E5),
    this.darkMode = false,
    this.announcementEnabled = false,
    this.announcementText = '',
    this.announcementColor = const Color(0xFF0EA5E9),
    this.featurePriorities = true,
    this.featureDueDates = true,
    this.featureCategories = true,
    this.featureStats = true,
    this.categories = const ['عام', 'عمل', 'شخصي', 'دراسة'],
    this.emptyMessage = 'لا توجد مهام بعد ✨',
    this.addHint = 'ماذا تريد أن تنجز اليوم؟',
  });

  static Color _color(dynamic v, Color fallback) {
    if (v is! String) return fallback;
    var hex = v.replaceAll('#', '').trim();
    if (hex.length == 6) hex = 'FF$hex';
    final n = int.tryParse(hex, radix: 16);
    return n == null ? fallback : Color(n);
  }

  factory RemoteConfig.fromJson(Map<String, dynamic> j) {
    const d = RemoteConfig();
    final ann = (j['announcement'] as Map?)?.cast<String, dynamic>() ?? {};
    final f = (j['features'] as Map?)?.cast<String, dynamic>() ?? {};
    final cats = (j['categories'] as List?)?.whereType<String>().toList();
    return RemoteConfig(
      configVersion: (j['config_version'] as num?)?.toInt() ?? 0,
      appTitle: j['app_title'] as String? ?? d.appTitle,
      primaryColor: _color(j['primary_color'], d.primaryColor),
      darkMode: j['dark_mode'] as bool? ?? d.darkMode,
      announcementEnabled: ann['enabled'] as bool? ?? false,
      announcementText: ann['text'] as String? ?? '',
      announcementColor: _color(ann['color'], d.announcementColor),
      featurePriorities: f['priorities'] as bool? ?? true,
      featureDueDates: f['due_dates'] as bool? ?? true,
      featureCategories: f['categories'] as bool? ?? true,
      featureStats: f['stats'] as bool? ?? true,
      categories: (cats == null || cats.isEmpty) ? d.categories : cats,
      emptyMessage: j['empty_message'] as String? ?? d.emptyMessage,
      addHint: j['add_hint'] as String? ?? d.addHint,
    );
  }
}

/// يجلب الإعدادات من السيرفر ويحفظ آخر نسخة ناجحة للعمل بدون إنترنت.
class RemoteConfigService extends ChangeNotifier {
  static const _cacheKey = 'remote_config_cache';

  RemoteConfig _config = const RemoteConfig();
  RemoteConfig get config => _config;

  Future<void> init() async {
    // 1) حمّل النسخة المحفوظة فوراً (تشغيل سريع وبدون إنترنت)
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      try {
        _config = RemoteConfig.fromJson(jsonDecode(cached));
        notifyListeners();
      } catch (_) {}
    }
    // 2) ثم اجلب الأحدث من السيرفر في الخلفية
    await refresh();
  }

  Future<bool> refresh() async {
    try {
      // نضيف timestamp لتجاوز الكاش
      final uri = Uri.parse(
          '${AppLinks.remoteConfigUrl}?t=${DateTime.now().millisecondsSinceEpoch}');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return false;
      final body = utf8.decode(res.bodyBytes);
      final json = jsonDecode(body) as Map<String, dynamic>;
      _config = RemoteConfig.fromJson(json);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, body);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('RemoteConfig refresh failed: $e');
      return false;
    }
  }
}
