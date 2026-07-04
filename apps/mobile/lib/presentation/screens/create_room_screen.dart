import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/homie_widgets.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  double budget = 2500;

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded), alignment: Alignment.centerLeft),
          const SizedBox(height: 8),
          Text('Create room', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 18),
          GlassPanel(
            child: Column(
              children: [
                const TextField(decoration: InputDecoration(labelText: 'Room name', prefixIcon: Icon(Icons.celebration_rounded)), controller: null),
                const SizedBox(height: 14),
                const TextField(decoration: InputDecoration(labelText: 'Location / society / office', prefixIcon: Icon(Icons.location_on_rounded))),
                const SizedBox(height: 18),
                Row(children: [const Icon(Icons.account_balance_wallet_rounded), const SizedBox(width: 10), Text('Budget ${money.format(budget)}')]),
                Slider(value: budget, min: 500, max: 8000, divisions: 15, label: money.format(budget), onChanged: (value) => setState(() => budget = value)),
                const Wrap(
                  spacing: 8,
                  children: [
                    Pill(label: 'Veg', icon: Icons.eco_rounded),
                    Pill(label: 'Spicy', icon: Icons.local_fire_department_rounded),
                    Pill(label: 'Party', icon: Icons.groups_rounded, selected: true),
                    Pill(label: 'Desserts', icon: Icons.cake_rounded),
                  ],
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => context.go('/invite'),
                  icon: const Icon(Icons.qr_code_rounded),
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
