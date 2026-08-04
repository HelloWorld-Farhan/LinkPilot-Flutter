import 'dart:io';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/link_item.dart';
import '../../data/models/history_item.dart';

const fetchBackground = "fetchBackground";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final isar = await Isar.open(
        [LinkItemSchema, HistoryItemSchema],
        directory: dir.path,
      );

      final pendingCount = await isar.linkItems.where().filter().isCompletedEqualTo(false).count();

      if (pendingCount > 0) {
        FlutterLocalNotificationsPlugin flip = FlutterLocalNotificationsPlugin();
        var android = const AndroidInitializationSettings('@mipmap/ic_launcher');
        var ios = const DarwinInitializationSettings();
        var settings = InitializationSettings(android: android, iOS: ios);
        await flip.initialize(settings: settings);

        var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
            'linkpilot_channel',
            'LinkPilot Reminders',
            importance: Importance.max,
            priority: Priority.high,
        );
        var platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
        
        await flip.show(
            id: 0,
            title: 'LinkPilot Reminder',
            body: 'You have $pendingCount pending links to complete today.',
            notificationDetails: platformChannelSpecifics,
            payload: 'Default_Sound'
        );
      }
      return Future.value(true);
    } catch (e) {
      return Future.value(false);
    }
  });
}

class BackgroundService {
  static void initialize() {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

    // Register to run daily
    Workmanager().registerPeriodicTask(
      "1",
      fetchBackground,
      frequency: const Duration(days: 1),
      initialDelay: _getDelayUntilMidnight(), // Start exactly at next 12:00 AM
    );
  }

  static Duration _getDelayUntilMidnight() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    return nextMidnight.difference(now);
  }
}
