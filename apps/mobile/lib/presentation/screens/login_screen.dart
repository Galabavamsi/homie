import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/homie_controller.dart';
import '../widgets/homie_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final nameController = TextEditingController(text: 'Vamsi');

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
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 72),
          Text(
            'Homie',
            style: Theme.of(context)
                .textTheme
                .displayMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Text(
            'Create a live food room, vote together, split the cart, and hand checkout to Swiggy.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 28),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.phone_android_rounded,
                    color: Color(0xFFFF6D21),
                  ),
                  title: Text('Native local MVP'),
                  subtitle: Text(
                    'Guest identity is used until Swiggy OAuth production access is issued.',
                  ),
                ),
                const Divider(),
                TextField(
                  controller: nameController,
                  textInputAction: TextInputAction.done,
                  maxLength: 40,
                  decoration: const InputDecoration(
                    labelText: 'Your name',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                  onSubmitted: (_) => _login(controller),
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 10),
                  StatusBanner(
                    message: state.errorMessage!,
                    isError: true,
                    onDismiss: controller.dismissError,
                  ),
                ],
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: state.isBusy ? null : () => _login(controller),
                  icon: state.isBusy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login_rounded),
                  label: const Text('Enter Homie locally'),
                ),
                if (state.hasSession) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: state.isBusy
                        ? null
                        : () {
                            if (controller.continueSession()) {
                              context.go('/home');
                            }
                          },
                    icon: const Icon(Icons.history_rounded),
                    label: Text('Continue as ${state.currentUser.name}'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          const ListTile(
            leading: Icon(Icons.verified_user_outlined),
            title: Text('Swiggy OAuth 2.1 + PKCE ready'),
            subtitle: Text('Callback: https://api.humanslop.in/auth/callback'),
          ),
        ],
      ),
    );
  }

  Future<void> _login(HomieController controller) async {
    if (await controller.login(nameController.text) && mounted) {
      context.go('/home');
    }
  }
}
