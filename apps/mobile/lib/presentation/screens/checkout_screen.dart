import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/homie_models.dart';
import '../state/homie_controller.dart';
import '../widgets/homie_widgets.dart';

const _foodBetaCartLimit = 1000;

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homieControllerProvider);
    final controller = ref.read(homieControllerProvider.notifier);
    final isWithinBetaCap = state.grandTotal < _foodBetaCartLimit;
    final canCheckout = state.isHost &&
        state.cart.isNotEmpty &&
        isWithinBetaCap &&
        !state.isRoomLocked &&
        !state.isBusy;
    return GradientScaffold(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
            alignment: Alignment.centerLeft,
          ),
          Text(
            'Checkout',
            style: Theme.of(context)
                .textTheme
                .headlineLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 12),
            StatusBanner(
              message: state.errorMessage!,
              isError: true,
              onDismiss: controller.dismissError,
            ),
          ],
          if (!state.isHost) ...[
            const SizedBox(height: 12),
            const StatusBanner(
              message: 'Only the room host can confirm checkout.',
              icon: Icons.admin_panel_settings_outlined,
            ),
          ],
          if (state.cart.isEmpty) ...[
            const SizedBox(height: 12),
            const StatusBanner(
              message: 'The cart is empty. Return to the menu and add a dish.',
              icon: Icons.remove_shopping_cart_outlined,
            ),
          ],
          const SizedBox(height: 16),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: state.mcpSource.endsWith('live')
                      ? 'Live Swiggy MCP checkout'
                      : 'Swiggy MCP local checkout stub',
                ),
                const SizedBox(height: 12),
                _CheckoutTile(
                  icon: Icons.restaurant_rounded,
                  title: state.selectedRestaurant.name,
                  subtitle:
                      'The API revalidates every item and price before checkout.',
                ),
                const Divider(),
                _CheckoutTile(
                  icon: Icons.receipt_long_rounded,
                  title: money.format(state.grandTotal),
                  subtitle:
                      '${state.cart.length} cart lines with automatic owner split',
                ),
                const Divider(),
                const _CheckoutTile(
                  icon: Icons.payments_rounded,
                  title: 'COD beta flow',
                  subtitle:
                      'Explicit host confirmation and a total below INR 1,000 are enforced by the backend.',
                ),
                const Divider(),
                _CapMeter(total: state.grandTotal),
                const Divider(),
                const _CheckoutTile(
                  icon: Icons.security_rounded,
                  title: 'No payment data stored by Homie',
                  subtitle:
                      'Only room collaboration and the resulting order reference are persisted.',
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: canCheckout
                      ? () => _confirmCheckout(
                          context, controller, state.grandTotal)
                      : null,
                  icon: state.isBusy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.local_shipping_rounded),
                  label: Text(_buttonLabel(state, isWithinBetaCap)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buttonLabel(HomieState state, bool isWithinBetaCap) {
    if (state.isRoomLocked) return 'Order already confirmed';
    if (!state.isHost) return 'Waiting for host';
    if (state.cart.isEmpty) return 'Cart is empty';
    if (!isWithinBetaCap) return 'Cart must be below INR 1,000';
    return state.mcpSource.endsWith('live')
        ? 'Confirm Swiggy COD order'
        : 'Confirm local COD order';
  }

  Future<void> _confirmCheckout(
    BuildContext context,
    HomieController controller,
    int total,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm checkout?'),
        content: Text(
          'Lock the room and place the ${money.format(total)} COD order through the configured Swiggy MCP adapter?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm order'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    if (await controller.checkout() && context.mounted) context.go('/tracking');
  }
}

class _CapMeter extends StatelessWidget {
  const _CapMeter({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = (total / _foodBetaCartLimit).clamp(0.0, 1.0);
    final remaining = (_foodBetaCartLimit - total).clamp(0, _foodBetaCartLimit);
    final isWithinBetaCap = total < _foodBetaCartLimit;
    final statusColor = isWithinBetaCap
        ? const Color(0xFFFF6D21)
        : Theme.of(context).colorScheme.error;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rule_rounded, color: statusColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Builders Club local cap',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              Text(money.format(total)),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            color: statusColor,
            minHeight: 9,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 8),
          Text(
            isWithinBetaCap
                ? '${money.format(remaining)} remaining before the INR 1,000 local test cap.'
                : '${money.format(total - (_foodBetaCartLimit - 1))} over the local cap. Remove an item to continue.',
            style: TextStyle(
              color: isWithinBetaCap ? null : statusColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutTile extends StatelessWidget {
  const _CheckoutTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

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
