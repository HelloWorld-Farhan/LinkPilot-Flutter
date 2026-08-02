import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: settings.isDarkMode,
            onChanged: (val) => settingsNotifier.toggleDarkMode(val),
          ),
          SwitchListTile(
            title: const Text('Notifications'),
            value: settings.notificationsEnabled,
            onChanged: (val) => settingsNotifier.toggleNotifications(val),
          ),
          ListTile(
            title: const Text('Sender Email'),
            subtitle: Text(settings.senderEmail.isEmpty ? 'Not set' : settings.senderEmail),
            onTap: () {
              // TODO: show dialog to set email
            },
          ),
          ListTile(
            title: const Text('About App'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
