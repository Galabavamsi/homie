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
    final controller = ref.read(homieControllerProvider.notifier);
    return GradientScaffold(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              const Icon(Icons.local_dining_rounded, color: Color(0xFFFF6D21)),
              const SizedBox(width: 10),
              Text(
                'Homie',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              Avatar(participant: state.currentUser),
            ],
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 16),
            StatusBanner(
              message: state.errorMessage!,
              isError: true,
              onRetry: controller.initialize,
              onDismiss: controller.dismissError,
            ),
          ],
          if (state.mcpSource.endsWith('live') && !state.swiggyConnected) ...[
            const SizedBox(height: 16),
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Connect Swiggy'),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in with your Swiggy phone number and OTP to load live restaurant data for this room.',
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: state.isBusy
                        ? null
                        : () => controller.connectSwiggy(),
                    icon: state.isBusy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.open_in_browser_rounded),
                    label: const Text('Connect Swiggy'),
                  ),
                ],
              ),
            ),
          ],
          if (state.mcpSource.endsWith('live') &&
              state.swiggyConnected &&
              state.addresses.isNotEmpty &&
              state.selectedAddressId == null) ...[
            const SizedBox(height: 16),
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Choose delivery address'),
                  const SizedBox(height: 8),
                  const Text(
                    'Swiggy uses this saved address for restaurant availability and delivery charges.',
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.location_on_rounded),
                      labelText: 'Saved Swiggy address',
                    ),
                    items: [
                      for (final address in state.addresses)
                        DropdownMenuItem(
                          value: address.id,
                          child: Text(
                            '${address.label}: ${address.displayText}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: state.isBusy
                        ? null
                        : (value) {
                            if (value != null) controller.selectAddress(value);
                          },
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 26),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order together without the group chat chaos',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Create a room for realtime chat, restaurant voting, shared carts, owner splits, and coordinated checkout.',
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed:
                      state.isBusy ? null : () => context.go('/create-room'),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create ordering room'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: state.isBusy
                      ? null
                      : () => _showJoinDialog(context, controller),
                  icon: const Icon(Icons.meeting_room_rounded),
                  label: const Text('Join with room code'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeader(title: 'Local demo room'),
          const SizedBox(height: 12),
          GlassPanel(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.groups_rounded,
                color: Color(0xFFFF6D21),
              ),
              title: const Text(
                'Friday House Party',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text('HOMIE42  |  persisted collaboration data'),
              trailing: state.isBusy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right_rounded),
              onTap: state.isBusy
                  ? null
                  : () async {
                      if (await controller.joinRoom('HOMIE42') &&
                          context.mounted) {
                        context.go('/room');
                      }
                    },
            ),
          ),
          const SizedBox(height: 16),
          StatusBanner(
            message: state.mcpSource.endsWith('live')
                ? 'Restaurant and menu data are coming from live Swiggy MCP.'
                : 'Restaurant commerce uses the local Swiggy MCP stub; room collaboration is live.',
            icon: state.mcpSource.endsWith('live')
                ? Icons.cloud_done_rounded
                : Icons.science_outlined,
          ),
        ],
      ),
    );
  }

  Future<void> _showJoinDialog(
    BuildContext context,
    HomieController controller,
  ) async {
    final codeController = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Join a room'),
        content: TextField(
          controller: codeController,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          maxLength: 12,
          decoration: const InputDecoration(
            labelText: 'Room code',
            hintText: 'HOMIE42',
            prefixIcon: Icon(Icons.key_rounded),
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, codeController.text),
            child: const Text('Join'),
          ),
        ],
      ),
    );
    codeController.dispose();
    if (code == null || code.trim().isEmpty || !context.mounted) return;
    if (await controller.joinRoom(code) && context.mounted) {
      context.go('/room');
    }
  }
}
