import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/homie_widgets.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            Text('Homie', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Text(
              'Create a live food room, vote on restaurants, split the bill, and checkout through Swiggy.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 28),
            const GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.verified_user_rounded, color: Color(0xFFFF6D21)),
                    title: Text('Swiggy OAuth placeholder'),
                    subtitle: Text('Callback: https://api.humanslop.in/auth/callback'),
                  ),
                  Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.groups_2_rounded, color: Color(0xFF2D6A4F)),
                    title: Text('Realtime collaboration'),
                    subtitle: Text('Rooms, chat, voting, carts, presence, and tracking.'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.login_rounded),
              label: const Text('Continue with Swiggy'),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}
