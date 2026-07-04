import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/homie_controller.dart';
import '../widgets/homie_widgets.dart';

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homieControllerProvider);
    final controller = ref.read(homieControllerProvider.notifier);
    return GradientScaffold(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded), alignment: Alignment.centerLeft),
          Text('Checkout', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Mock Swiggy MCP checkout'),
                const SizedBox(height: 12),
                _CheckoutTile(icon: Icons.restaurant_rounded, title: state.selectedRestaurant.name, subtitle: 'Restaurant, menu, prices, checkout, payment, and delivery remain Swiggy-owned.'),
                const Divider(),
                _CheckoutTile(icon: Icons.receipt_long_rounded, title: money.format(state.grandTotal), subtitle: '${state.cart.length} cart lines • automatic owner split included'),
                const Divider(),
                const _CheckoutTile(icon: Icons.security_rounded, title: 'No sensitive transaction storage', subtitle: 'Homie stores room collaboration data only.'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    await controller.checkout();
                    if (context.mounted) context.go('/tracking');
                  },
                  icon: const Icon(Icons.local_shipping_rounded),
                  label: const Text('Place mock order through Swiggy'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutTile extends StatelessWidget {
  const _CheckoutTile({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: const Color(0xFFFF6D21)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(subtitle),
    );
  }
}
