import 'package:package_info_plus/package_info_plus.dart';

class AppPackageInfo {
  late final PackageInfo packageInfo;
  late final String changelog;
  late final String newestVersion;

  static final AppPackageInfo _instance = AppPackageInfo._internal();

  factory AppPackageInfo() {
    return _instance;
  }

  AppPackageInfo._internal();

  bool _initSuccess = false;

  Future<void> init() async {
    packageInfo = await PackageInfo.fromPlatform();
    // 使用本地版本信息，避免部署时因 Supabase app 表不存在导致 404
    changelog = '';
    newestVersion = packageInfo.version;
    _initSuccess = true;
  }

  bool get appIsUpToDate {
    if (!_initSuccess) return true;
    return packageInfo.version == newestVersion;
  }
}
