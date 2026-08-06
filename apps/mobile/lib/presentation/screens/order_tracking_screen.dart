import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/homie_controller.dart';
import '../widgets/homie_widgets.dart';

class OrderTrackingScreen extends ConsumerWidget {
  const OrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homieControllerProvider);
    return GradientScaffold(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          IconButton(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.close_rounded),
              alignment: Alignment.centerLeft),
          Text('Order tracking',
              style: Theme.of(context)
                  .textTheme
                  .headlineLarge
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Swiggy delivery timeline'),
                const SizedBox(height: 12),
                for (final entry in state.orderSteps.asMap().entries)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Icon(
                              entry.value.isComplete
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: entry.value.isComplete
                                  ? const Color(0xFF2D6A4F)
                                  : const Color(0xFFFF6D21)),
                          if (entry.key != state.orderSteps.length - 1)
                            Container(
                                width: 2,
                                height: 46,
                                color: Theme.of(context).dividerColor),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.value.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900)),
                              Text(entry.value.subtitle),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                const Divider(),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.notifications_active_rounded,
                      color: Color(0xFFFF6D21)),
                  title: Text('Push notification mock'),
                  subtitle: Text(
                      'All room participants receive tracking updates together.'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
