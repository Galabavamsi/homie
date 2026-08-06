import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/homie_models.dart';
import '../state/homie_controller.dart';
import '../widgets/homie_widgets.dart';

class RoomScreen extends ConsumerStatefulWidget {
  const RoomScreen({super.key});

  @override
  ConsumerState<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends ConsumerState<RoomScreen> {
  final messageController = TextEditingController();
  final assistantController = TextEditingController();

  @override
  void dispose() {
    messageController.dispose();
    assistantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homieControllerProvider);
    final controller = ref.read(homieControllerProvider.notifier);
    final maxVotes = state.votes.values
        .fold<int>(1, (max, value) => value > max ? value : max);

    return GradientScaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAssistant(context, state, controller),
        icon: const Icon(Icons.auto_awesome_rounded),
        label: const Text('AI'),
      ),
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor:
                Theme.of(context).scaffoldBackgroundColor.withOpacity(.96),
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            pinned: true,
            title: Text(state.room.name,
                style: const TextStyle(fontWeight: FontWeight.w900)),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ParticipantStack(participants: state.room.participants),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList.list(
              children: [
                _RoomHero(state: state),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  StatusBanner(
                    message: state.errorMessage!,
                    isError: true,
                    onRetry: () {
                      controller.refreshRoom();
                    },
                    onDismiss: controller.dismissError,
                  ),
                ],
                if (state.realtimeStatus != RealtimeStatus.connected) ...[
                  const SizedBox(height: 12),
                  StatusBanner(
                    message: state.realtimeStatus == RealtimeStatus.offline
                        ? 'Realtime is offline. Updates will use HTTP until Socket.IO reconnects.'
                        : 'Reconnecting realtime updates...',
                    icon: Icons.sync_rounded,
                  ),
                ],
                if (state.isRoomLocked) ...[
                  const SizedBox(height: 12),
                  const StatusBanner(
                    message:
                        'Checkout is confirmed. This room is now read-only.',
                    icon: Icons.lock_rounded,
                  ),
                ],
                const SizedBox(height: 16),
                _Discovery(state: state, controller: controller),
                const SizedBox(height: 16),
                _Voting(
                    state: state, controller: controller, maxVotes: maxVotes),
                const SizedBox(height: 16),
                _Menu(state: state, controller: controller),
                const SizedBox(height: 16),
                _Cart(state: state, controller: controller),
                const SizedBox(height: 16),
                _Chat(
                    state: state,
                    controller: controller,
                    messageController: messageController),
                const SizedBox(height: 16),
                _Activity(state: state),
                const SizedBox(height: 92),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAssistant(
      BuildContext context, HomieState state, HomieController controller) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
            18, 0, 18, MediaQuery.of(context).viewInsets.bottom + 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Homie assistant',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            GlassPanel(child: Text(state.assistantText)),
            const SizedBox(height: 12),
            TextField(
              controller: assistantController,
              decoration: const InputDecoration(
                hintText: 'Ask for budget, veg, spicy, desserts...',
                prefixIcon: Icon(Icons.auto_awesome_rounded),
              ),
              onSubmitted: (value) {
                controller.askAssistant(value);
                assistantController.clear();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                controller.askAssistant(assistantController.text.isEmpty
                    ? 'budget'
                    : assistantController.text);
                assistantController.clear();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.send_rounded),
              label: const Text('Get recommendation'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomHero extends StatelessWidget {
  const _RoomHero({required this.state});

  final HomieState state;

  @override
  Widget build(BuildContext context) {
    final budgetUsed = state.room.budget == 0
        ? 0.0
        : (state.grandTotal / state.room.budget).clamp(0.0, 1.0);
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Live room ${state.room.code}',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w900)),
              ),
              Chip(
                label: Text(
                  '${state.room.participants.where((user) => user.isOnline).length} online',
                ),
                avatar: Icon(
                  state.realtimeStatus == RealtimeStatus.connected
                      ? Icons.bolt_rounded
                      : Icons.sync_rounded,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
              'Swiggy MCP owns restaurant data, pricing, checkout, and delivery. Homie owns the collaboration layer.'),
          const SizedBox(height: 18),
          LinearProgressIndicator(
              value: budgetUsed,
              minHeight: 9,
              borderRadius: BorderRadius.circular(999)),
          const SizedBox(height: 8),
          Text(
              '${money.format(state.grandTotal)} of ${money.format(state.room.budget)} planned'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state.room.participants
                .where((p) => p.cursorLabel != null || p.isTyping)
                .map((p) => Pill(
                    label: p.isTyping
                        ? '${p.name} typing'
                        : '${p.name} ${p.cursorLabel}',
                    icon: p.isTyping
                        ? Icons.chat_bubble_rounded
                        : Icons.near_me_rounded))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _Discovery extends StatelessWidget {
  const _Discovery({required this.state, required this.controller});

  final HomieState state;
  final HomieController controller;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Swiggy discovery'),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Search cuisine or restaurant'),
            onChanged: controller.searchRestaurants,
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Pill(
                      label: 'All',
                      selected: state.filter == null,
                      onTap: () => controller.setFilter(null)),
                ),
                for (final tag in DietaryTag.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Pill(
                        label: tagLabel(tag),
                        selected: state.filter == tag,
                        onTap: () => controller.setFilter(tag)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 230,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final restaurant = state.restaurants[index];
                final selected = restaurant.id == state.selectedRestaurantId;
                return GestureDetector(
                  onTap: () => controller.selectRestaurant(restaurant.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 218,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFFF6D21).withOpacity(.13)
                          : Theme.of(context)
                              .colorScheme
                              .surface
                              .withOpacity(.72),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: selected
                              ? const Color(0xFFFF6D21)
                              : Colors.transparent,
                          width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FoodImage(
                          url: restaurant.image,
                          height: 96,
                          width: double.infinity,
                          borderRadius: 8,
                        ),
                        const SizedBox(height: 10),
                        Text(restaurant.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontWeight: FontWeight.w900)),
                        Text(restaurant.cuisine,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 17, color: Color(0xFFFFB000)),
                            Text(' ${restaurant.rating.toStringAsFixed(1)}'),
                            const Spacer(),
                            Text('${restaurant.etaMinutes} min'),
                          ],
                        ),
                        Text(restaurant.offer,
                            style: const TextStyle(
                                color: Color(0xFFFF6D21),
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemCount: state.restaurants.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _Voting extends StatelessWidget {
  const _Voting(
      {required this.state, required this.controller, required this.maxVotes});

  final HomieState state;
  final HomieController controller;
  final int maxVotes;

  @override
  Widget build(BuildContext context) {
    final entries = state.votes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Live restaurant voting'),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            const Text(
                'No votes yet. Pick a restaurant to start the room vote.'),
          for (final entry in entries.take(5))
            Builder(
              builder: (context) {
                final restaurant = state.restaurants.firstWhere(
                    (r) => r.id == entry.key,
                    orElse: () => state.selectedRestaurant);
                final winning = entry.value == entries.first.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(restaurant.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontWeight: winning
                                    ? FontWeight.w900
                                    : FontWeight.w600)),
                      ),
                      Expanded(
                        flex: 4,
                        child: LinearProgressIndicator(
                            value: entry.value / maxVotes,
                            minHeight: 9,
                            borderRadius: BorderRadius.circular(999)),
                      ),
                      const SizedBox(width: 8),
                      Text('${entry.value}'),
                      IconButton.filledTonal(
                        tooltip:
                            state.myVote == entry.key ? 'Your vote' : 'Vote',
                        onPressed: state.isRoomLocked
                            ? null
                            : () => controller.vote(entry.key),
                        icon: Icon(
                          state.myVote == entry.key
                              ? Icons.check_rounded
                              : Icons.how_to_vote_rounded,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu({required this.state, required this.controller});

  final HomieState state;
  final HomieController controller;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: '${state.selectedRestaurant.name} menu'),
          const SizedBox(height: 12),
          if (state.selectedMenu.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            ),
          for (final item in state.selectedMenu)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  FoodImage(
                    url: item.image,
                    width: 82,
                    height: 82,
                    borderRadius: 8,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w900)),
                        Text(item.description,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(money.format(item.price),
                            style: const TextStyle(
                                color: Color(0xFFFF6D21),
                                fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  IconButton.filled(
                    tooltip: 'Add',
                    onPressed: state.isRoomLocked
                        ? null
                        : () => controller.addToCart(item),
                    icon: const Icon(Icons.add_shopping_cart_rounded),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Cart extends StatelessWidget {
  const _Cart({required this.state, required this.controller});

  final HomieState state;
  final HomieController controller;

  @override
  Widget build(BuildContext context) {
    final byOwner = <String, List<CartItem>>{};
    for (final item in state.cart) {
      byOwner.putIfAbsent(item.owner.id, () => []).add(item);
    }
    final canCheckout =
        state.isHost && state.cart.isNotEmpty && !state.isRoomLocked;
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Shared cart',
            action: TextButton.icon(
              onPressed: canCheckout ? () => context.go('/checkout') : null,
              icon: const Icon(Icons.lock_rounded),
              label: Text(state.isHost ? 'Checkout' : 'Host checkout'),
            ),
          ),
          const SizedBox(height: 8),
          if (byOwner.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child:
                  Text('The shared cart is empty. Add a dish from the menu.'),
            ),
          for (final entry in byOwner.entries)
            Builder(
              builder: (context) {
                final owner = entry.value.first.owner;
                final total =
                    entry.value.fold(0, (sum, item) => sum + item.total);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Avatar(participant: owner),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${owner.name} owes ${money.format(total)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w900),
                            ),
                            for (final line in entry.value)
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      line.item.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (owner.id == state.currentUser.id &&
                                      !state.isRoomLocked) ...[
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      tooltip: line.quantity == 1
                                          ? 'Remove'
                                          : 'Decrease',
                                      onPressed: () =>
                                          controller.setCartQuantity(
                                        line.item,
                                        line.quantity - 1,
                                      ),
                                      icon: Icon(
                                        line.quantity == 1
                                            ? Icons.delete_outline_rounded
                                            : Icons.remove_rounded,
                                        size: 18,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 24,
                                      child: Text(
                                        '${line.quantity}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      tooltip: 'Increase',
                                      onPressed: line.quantity >= 20
                                          ? null
                                          : () => controller.setCartQuantity(
                                                line.item,
                                                line.quantity + 1,
                                              ),
                                      icon: const Icon(Icons.add_rounded,
                                          size: 18),
                                    ),
                                  ] else
                                    Text('${line.quantity}x'),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const Divider(),
          _PriceRow(label: 'Subtotal', value: state.subtotal),
          _PriceRow(label: 'Taxes', value: state.taxes),
          _PriceRow(label: 'Delivery + platform fees', value: state.fees),
          _PriceRow(label: 'Grand total', value: state.grandTotal, bold: true),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow(
      {required this.label, required this.value, this.bold = false});
  final String label;
  final int value;
  final bool bold;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontWeight: bold ? FontWeight.w900 : FontWeight.w500))),
          Text(money.format(value),
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w900 : FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Chat extends StatelessWidget {
  const _Chat(
      {required this.state,
      required this.controller,
      required this.messageController});

  final HomieState state;
  final HomieController controller;
  final TextEditingController messageController;

  @override
  Widget build(BuildContext context) {
    Future<void> send() async {
      final message = messageController.text.trim();
      if (message.isEmpty) return;
      await controller.sendMessage(message);
      messageController.clear();
      controller.setTyping(false);
    }

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Room chat'),
          const SizedBox(height: 8),
          if (state.messages.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No messages yet. Say hello to the room.'),
            ),
          for (final message in state.messages.take(4))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Avatar(participant: message.sender, size: 34),
              title: Text(message.sender.name,
                  style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text(message.message),
              trailing: message.reaction == null
                  ? null
                  : Text(message.reaction!,
                      style: const TextStyle(fontSize: 13)),
            ),
          TextField(
            controller: messageController,
            enabled: !state.isRoomLocked,
            decoration: InputDecoration(
              hintText:
                  state.isRoomLocked ? 'Room is read-only' : 'Message the room',
              prefixIcon: const Icon(Icons.chat_bubble_rounded),
              suffixIcon: IconButton(
                tooltip: 'Send',
                icon: const Icon(Icons.send_rounded),
                onPressed: state.isRoomLocked ? null : send,
              ),
            ),
            onChanged: (value) => controller.setTyping(value.trim().isNotEmpty),
            onSubmitted: (_) => send(),
            onTapOutside: (_) => controller.setTyping(false),
          ),
        ],
      ),
    );
  }
}

class _Activity extends StatelessWidget {
  const _Activity({required this.state});

  final HomieState state;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Activity feed'),
          const SizedBox(height: 8),
          for (final event in state.activity.take(5))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.bolt_rounded, color: Color(0xFFFF6D21)),
              title: Text(event.text),
              subtitle: const Text('Persisted and broadcast through Socket.IO'),
            ),
        ],
      ),
    );
  }
}
