/// روابط التحديث عن بُعد.
///
/// - [remoteConfigUrl]: ملف الإعدادات الحيّة (ألوان، نصوص، ميزات، إعلان...)
///   تعدّله من GitHub مباشرة ويصل للتطبيق خلال دقائق بدون أي بناء.
/// - [versionUrl]: معلومات آخر إصدار (يولّده GitHub Actions تلقائياً).
class AppLinks {
  static const githubUser = 'qbrahym02-cmyk';
  static const repo = 'todo-flutter-ota';

  static const remoteConfigUrl =
      'https://raw.githubusercontent.com/$githubUser/$repo/main/remote/config.json';

  static const versionUrl = 'https://$githubUser.github.io/$repo/update.json';
}
