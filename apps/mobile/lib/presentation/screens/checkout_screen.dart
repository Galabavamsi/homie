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
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
            alignment: Alignment.centerLeft,
          ),
          Text(
            'Checkout',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Mock Swiggy MCP checkout'),
                const SizedBox(height: 12),
                _CheckoutTile(
                  icon: Icons.restaurant_rounded,
                  title: state.selectedRestaurant.name,
                  subtitle: 'Restaurant, menu, prices, checkout, payment, and delivery remain Swiggy-owned.',
                ),
                const Divider(),
                _CheckoutTile(
                  icon: Icons.receipt_long_rounded,
                  title: money.format(state.grandTotal),
                  subtitle: '${state.cart.length} cart lines - automatic owner split included',
                ),
                const Divider(),
                const _CheckoutTile(
                  icon: Icons.payments_rounded,
                  title: 'COD beta flow',
                  subtitle: 'Local MVP follows Swiggy Builders Club Food constraints: COD-capable cart, explicit confirmation, and total below ₹1000.',
                ),
                const Divider(),
                _CapMeter(total: state.grandTotal),
                const Divider(),
                const _CheckoutTile(
                  icon: Icons.security_rounded,
                  title: 'No sensitive transaction storage',
                  subtitle: 'Homie stores room collaboration data only.',
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    await controller.checkout();
                    if (context.mounted) context.go('/tracking');
                  },
                  icon: const Icon(Icons.local_shipping_rounded),
                  label: const Text('Confirm mock COD order'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CapMeter extends StatelessWidget {
  const _CapMeter({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = (total / 1000).clamp(0.0, 1.0);
    final remaining = (1000 - total).clamp(0, 1000);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rule_rounded, color: Color(0xFFFF6D21)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Builders Club beta cap',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              Text(money.format(total)),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            minHeight: 9,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 8),
          Text('${money.format(remaining)} remaining before the ₹1000 local test cap.'),
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
