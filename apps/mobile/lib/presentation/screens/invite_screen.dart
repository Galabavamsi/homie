import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../state/homie_controller.dart';
import '../widgets/homie_widgets.dart';

class InviteScreen extends ConsumerWidget {
  const InviteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(homieControllerProvider).room;
    return GradientScaffold(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded), alignment: Alignment.centerLeft),
          Text('Invite friends', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 18),
          GlassPanel(
            child: Column(
              children: [
                QrImageView(data: room.inviteLink, size: 210, backgroundColor: Colors.white),
                const SizedBox(height: 18),
                Text(room.code, style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 2)),
                const SizedBox(height: 6),
                Text(room.inviteLink, textAlign: TextAlign.center),
                const SizedBox(height: 18),
                FilledButton.icon(onPressed: () => context.go('/room'), icon: const Icon(Icons.arrow_forward_rounded), label: const Text('Enter room')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
