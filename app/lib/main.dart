import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/config/routes.dart';
import 'core/theme/app_theme.dart';
import 'core/network/dio_client.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/update_service.dart';
import 'shared/widgets/update_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  await dotenv.load(fileName: 'assets/.env');
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    _checkHealth();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deepLinkServiceProvider).init();
      // Check for app updates after first frame is rendered
      _checkForUpdates();
    });
  }

  Future<void> _checkHealth() async {
    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.get('/health');
      debugPrint('Health Check Response: ${response.data}');
    } catch (e) {
      debugPrint('Health Check Error: $e');
    }
  }

  Future<void> _checkForUpdates() async {
    try {
      final dio = ref.read(dioClientProvider);
      final updateInfo = await UpdateService(dio).checkForUpdate();
      if (updateInfo == null) return;
      if (!mounted) return;

      // Small delay so the app UI is fully settled before showing dialog
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isDismissible: !updateInfo.forceUpdate,
        enableDrag: !updateInfo.forceUpdate,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => UpdateDialog(updateInfo: updateInfo, dio: dio),
      );
    } catch (_) {
      // Never crash the app for a failed update check
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'CMS App',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
