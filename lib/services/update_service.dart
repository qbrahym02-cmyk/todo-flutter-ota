import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config.dart';
import 'reload_stub.dart' if (dart.library.js_interop) 'reload_web.dart';

/// معلومات آخر إصدار منشور (update.json يولّده GitHub Actions)
class ReleaseInfo {
  final String version;
  final int build;
  final int minBuild;
  final String apkUrl;
  final String changelog;
  final String? sha256;

  ReleaseInfo({
    required this.version,
    required this.build,
    required this.minBuild,
    required this.apkUrl,
    required this.changelog,
    this.sha256,
  });

  factory ReleaseInfo.fromJson(Map<String, dynamic> j) => ReleaseInfo(
        version: j['version'] as String? ?? '0.0.0',
        build: (j['build'] as num?)?.toInt() ?? 0,
        minBuild: (j['min_build'] as num?)?.toInt() ?? 0,
        apkUrl: j['apk_url'] as String? ?? '',
        changelog: j['changelog'] as String? ?? '',
        sha256: j['sha256'] as String?,
      );
}

enum UpdateState { idle, checking, available, downloading, installing, error, upToDate }

/// يفحص وجود إصدار جديد ويثبّته من داخل التطبيق
class UpdateService extends ChangeNotifier {
  UpdateState state = UpdateState.idle;
  ReleaseInfo? latest;
  String currentVersion = '';
  int currentBuild = 0;
  double progress = 0;
  String? error;
  StreamSubscription<OtaEvent>? _sub;

  bool get isAvailable => latest != null && latest!.build > currentBuild;
  bool get isForced => latest != null && currentBuild < latest!.minBuild;

  Future<void> check() async {
    state = UpdateState.checking;
    notifyListeners();
    try {
      final info = await PackageInfo.fromPlatform();
      currentVersion = info.version;
      currentBuild = int.tryParse(info.buildNumber) ?? 0;

      final uri = Uri.parse(
          '${AppLinks.versionUrl}?t=${DateTime.now().millisecondsSinceEpoch}');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) throw 'HTTP ${res.statusCode}';
      latest = ReleaseInfo.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
      state = isAvailable ? UpdateState.available : UpdateState.upToDate;
    } catch (e) {
      error = '$e';
      state = UpdateState.error;
    }
    notifyListeners();
  }

  /// تنزيل وتثبيت التحديث
  void install() {
    final rel = latest;
    if (rel == null) return;

    // على الويب: النسخة الجديدة موجودة على السيرفر، يكفي إعادة تحميل الصفحة
    if (kIsWeb) {
      reloadPage();
      return;
    }

    if (defaultTargetPlatform != TargetPlatform.android || rel.apkUrl.isEmpty) {
      error = 'التحديث التلقائي مدعوم على أندرويد والويب فقط';
      state = UpdateState.error;
      notifyListeners();
      return;
    }

    _sub?.cancel();
    progress = 0;
    state = UpdateState.downloading;
    notifyListeners();

    _sub = OtaUpdate()
        .execute(
          rel.apkUrl,
          destinationFilename: 'todo-update.apk',
          sha256checksum: rel.sha256, // للتحقق من سلامة الملف
        )
        .listen((event) {
      switch (event.status) {
        case OtaStatus.DOWNLOADING:
          progress = (double.tryParse(event.value ?? '0') ?? 0) / 100;
          state = UpdateState.downloading;
          break;
        case OtaStatus.INSTALLING:
        case OtaStatus.INSTALLATION_DONE:
          state = UpdateState.installing;
          break;
        default:
          error = '${event.status.name}: ${event.value ?? ''}';
          state = UpdateState.error;
      }
      notifyListeners();
    }, onError: (e) {
      error = '$e';
      state = UpdateState.error;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
