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

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildAvatar({String? email, String? photoURL}) {
    final initials = (email != null && email.isNotEmpty)
        ? email.trim().substring(0, 1).toUpperCase()
        : '?';
    return CircleAvatar(
      radius: 28,
      backgroundColor: const Color(0xFFFFC107).withOpacity(.2),
      foregroundColor: const Color(0xFF0A0A23),
      backgroundImage: (photoURL != null && photoURL.isNotEmpty) ? NetworkImage(photoURL) : null,
      child: (photoURL == null || photoURL.isEmpty)
          ? Text(initials, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final user = auth.currentUser!;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildAvatar(email: user.email, photoURL: user.photoURL),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.email ?? 'No email',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Account created: ${_formatDate(user.metadata.creationTime)}',
                          style: const TextStyle(
                            color: Color.fromARGB(255, 62, 184, 5),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: (user.emailVerified) ? Colors.green.withOpacity(.12) : Colors.red.withOpacity(.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      user.emailVerified ? 'Verified' : 'Unverified',
                      style: TextStyle(
                        color: user.emailVerified ? Colors.green.shade700 : Colors.red.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
          const ListTile(
            title: Text('About'),
            subtitle: Text(
              'BookSwap helps students exchange textbooks easily. '
              'Browse listings, post your books with cover images, and initiate swaps. '
              'Real-time updates, optional chat, and email verification keep things safe.\n'
            ),
          ),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              await auth.signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}
