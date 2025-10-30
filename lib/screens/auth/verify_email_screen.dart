import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('We sent a verification link to your email. Please verify to continue.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async => auth.sendVerification(),
              child: const Text('Resend Email'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async => await auth.currentUser?.reload(),
              child: const Text('I Verified — Refresh'),
            ),
            const Spacer(),
            TextButton(onPressed: () async => auth.signOut(), child: const Text('Sign Out')),
          ],
        ),
      ),
    );
  }
}