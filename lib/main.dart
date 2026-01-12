import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/providers/game_provider.dart';
import 'core/providers/gacha_provider.dart';
import 'core/providers/user_progress_provider.dart';
import 'core/services/storage_service.dart';
import 'core/services/privacy_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Hive.initFlutter();
    await StorageService.init();
    await PrivacyService.initialize();
  } catch (e) {
    print('Storage initialization failed, continuing without local storage: $e');
  }
  
  // Set preferred orientations (skip on web)
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  } catch (e) {
    // Skip system UI settings on web
    print('System UI settings skipped on web: $e');
  }
  
  runApp(const YokaiGachaApp());
}

class YokaiGachaApp extends StatelessWidget {
  const YokaiGachaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => GachaProvider()),
        ChangeNotifierProvider(create: (_) => UserProgressProvider()),
      ],
      child: MaterialApp(
        title: 'Yokai Gacha',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
