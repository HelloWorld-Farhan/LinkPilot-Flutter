import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'data/models/link_item.dart';
import 'data/models/history_item.dart';
import 'presentation/providers/database_provider.dart';

import 'presentation/screens/splash_screen.dart';
import 'core/services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  BackgroundService.initialize();
  
  // Init SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  
  // Init Isar
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [LinkItemSchema, HistoryItemSchema],
    directory: dir.path,
  );

  runApp(
    ProviderScope(
      overrides: [

        isarProvider.overrideWithValue(isar),
      ],
      child: const LinkPilotApp(),
    ),
  );
}

class LinkPilotApp extends ConsumerWidget {
  const LinkPilotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
