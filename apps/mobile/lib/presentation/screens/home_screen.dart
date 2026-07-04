import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/homie_controller.dart';
import '../widgets/homie_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homieControllerProvider);
    return GradientScaffold(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              const Icon(Icons.local_dining_rounded, color: Color(0xFFFF6D21)),
              const SizedBox(width: 10),
              Text('Homie', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const Spacer(),
              ParticipantStack(participants: state.room.participants.take(3).toList()),
            ],
          ),
          const SizedBox(height: 26),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order together without the group chat chaos', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                const Text('Rooms combine Swiggy discovery and checkout with live chat, restaurant voting, shared carts, bill splitting, and AI recommendations.'),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: () => context.go('/create-room'),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create ordering room'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => context.go('/room'),
                  icon: const Icon(Icons.meeting_room_rounded),
                  label: const Text('Join demo room HOMIE42'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeader(title: 'Recent rooms'),
          const SizedBox(height: 12),
          for (final title in ['Friday House Party', 'Office Lunch Pod', 'Hostel Room 302'])
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassPanel(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history_rounded, color: Color(0xFFFF6D21)),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: const Text('Swiggy Food • shared cart • split enabled'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.go('/room'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
