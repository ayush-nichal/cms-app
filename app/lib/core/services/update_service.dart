import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  final String latestVersion;
  final String currentVersion;
  final String releaseNotes;
  final String apkUrl;
  final bool forceUpdate;

  const UpdateInfo({
    required this.latestVersion,
    required this.currentVersion,
    required this.releaseNotes,
    required this.apkUrl,
    required this.forceUpdate,
  });
}

class UpdateService {
  final Dio _dio;

  UpdateService(this._dio);

  /// Compares two semver strings. Returns true if [a] > [b].
  static bool _isNewer(String a, String b) {
    try {
      final aParts = a.split('.').map(int.parse).toList();
      final bParts = b.split('.').map(int.parse).toList();
      while (aParts.length < 3) { aParts.add(0); }
      while (bParts.length < 3) { bParts.add(0); }
      for (int i = 0; i < 3; i++) {
        if (aParts[i] > bParts[i]) return true;
        if (aParts[i] < bParts[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Checks the backend for the latest app version.
  /// Returns [UpdateInfo] if an update is available, null otherwise.
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // e.g. "1.0.0"

      final response = await _dio.get('/api/version');
      final data = response.data as Map<String, dynamic>;

      final latestVersion = (data['version'] as String? ?? '0.0.0').trim();
      final apkUrl = data['apk_url'] as String? ?? '';
      final releaseNotes = data['release_notes'] as String? ?? '';
      final forceUpdate = data['force_update'] as bool? ?? false;

      if (apkUrl.isEmpty) return null;
      if (!_isNewer(latestVersion, currentVersion)) return null;

      return UpdateInfo(
        latestVersion: latestVersion,
        currentVersion: currentVersion,
        releaseNotes: releaseNotes,
        apkUrl: apkUrl,
        forceUpdate: forceUpdate,
      );
    } catch (e) {
      // Silently fail — update checks should never crash the app
      return null;
    }
  }
}
