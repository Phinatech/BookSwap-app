import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notif = true;
  bool email = true;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final user = auth.currentUser!;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('Profile'),
            subtitle: Text('${user.email}\nUID: ${user.uid}'),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: notif,
            onChanged: (v) => setState(() => notif = v),
            title: const Text('Notification reminders'),
          ),
          SwitchListTile(
            value: email,
            onChanged: (v) => setState(() => email = v),
            title: const Text('Email Updates'),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('About'),
            subtitle: const Text('BookSwap • Flutter + Firebase'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: () => auth.signOut(), child: const Text('Log out')),
        ],
      ),
    );
  }
}
