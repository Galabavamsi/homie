import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/homie_controller.dart';
import '../widgets/homie_widgets.dart';

class CreateRoomScreen extends ConsumerStatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  final nameController = TextEditingController(text: 'Friday House Party');
  double budget = 2500;

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homieControllerProvider);
    final controller = ref.read(homieControllerProvider.notifier);
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
          const SizedBox(height: 8),
          Text(
            'Create room',
            style: Theme.of(context)
                .textTheme
                .headlineLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 18),
          GlassPanel(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  maxLength: 60,
                  decoration: const InputDecoration(
                    labelText: 'Room name',
                    prefixIcon: Icon(Icons.celebration_rounded),
                  ),
                ),
                const SizedBox(height: 8),
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Location label (not stored in MVP)',
                    prefixIcon: Icon(Icons.location_on_rounded),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_rounded),
                    const SizedBox(width: 10),
                    Text('Budget ${money.format(budget)}'),
                  ],
                ),
                Slider(
                  value: budget,
                  min: 500,
                  max: 8000,
                  divisions: 15,
                  label: money.format(budget),
                  onChanged: state.isBusy
                      ? null
                      : (value) => setState(() => budget = value),
                ),
                const Wrap(
                  spacing: 8,
                  children: [
                    Pill(label: 'Veg', icon: Icons.eco_rounded),
                    Pill(
                        label: 'Spicy',
                        icon: Icons.local_fire_department_rounded),
                    Pill(
                      label: 'Party',
                      icon: Icons.groups_rounded,
                      selected: true,
                    ),
                    Pill(label: 'Desserts', icon: Icons.cake_rounded),
                  ],
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 14),
                  StatusBanner(
                    message: state.errorMessage!,
                    isError: true,
                    onDismiss: controller.dismissError,
                  ),
                ],
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: state.isBusy
                      ? null
                      : () async {
                          final created = await controller.createRoom(
                            nameController.text.trim(),
                            budget.round(),
                          );
                          if (created && context.mounted) {
                            context.go('/invite');
                          }
                        },
                  icon: state.isBusy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.qr_code_rounded),
                  label: const Text('Create invite'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
