import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_links/app_links.dart';
import '../config/routes.dart';

final deepLinkServiceProvider = Provider((ref) => DeepLinkService(ref));

class DeepLinkService {
  final Ref _ref;
  final _appLinks = AppLinks();
  StreamSubscription? _sub;

  DeepLinkService(this._ref);

  Future<void> init() async {
    // 1. Handle link when app is opened from closed state
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleUri(initialUri);
      }
    } catch (e) {
      debugPrint('Failed to receive initial link: $e');
    }

    // 2. Handle link when app is in background/running
    _sub = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleUri(uri);
      }
    }, onError: (err) {
      debugPrint('Deep Link Stream Error: $err');
    });
  }

  void _handleUri(Uri uri) {
    debugPrint('Processing Deep Link: ${uri.toString()}');
    try {
      // Target: cmsapp://app/reset-password?token=XYZ
      if (uri.scheme == 'cmsapp' && uri.host == 'app' && uri.path == '/reset-password') {
        final token = uri.queryParameters['token'];
        if (token != null) {
          final router = _ref.read(routerProvider);
          router.push('/reset-password?token=$token');
        }
      }
    } catch (e) {
      debugPrint('Deep Link Parsing Error: $e');
    }
  }

  void dispose() {
    _sub?.cancel();
  }
}
