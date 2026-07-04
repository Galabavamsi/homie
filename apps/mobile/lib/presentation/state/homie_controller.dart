import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/mock_data.dart';
import '../../data/mcp/mock_mcp_service.dart';
import '../../domain/models/homie_models.dart';

final mcpServiceProvider = Provider((ref) => MockMcpService());

final homieControllerProvider =
    StateNotifierProvider<HomieController, HomieState>((ref) {
  return HomieController(ref.watch(mcpServiceProvider));
});

class HomieController extends StateNotifier<HomieState> {
  HomieController(this._mcp)
      : super(
          HomieState(
            room: mockRoom,
            restaurants: mockRestaurants,
            menu: mockMenu,
            selectedRestaurantId: mockRestaurants.first.id,
            votes: {for (final r in mockRestaurants.take(5)) r.id: 1 + int.parse(r.id.substring(1)) % 7},
            cart: [
              CartItem(id: 'c1', item: mockMenu[1], owner: mockParticipants[1], quantity: 1),
              CartItem(id: 'c2', item: mockMenu[2], owner: mockParticipants[2], quantity: 2),
            ],
            messages: mockMessages,
            activity: mockActivity,
            orderSteps: const [],
          ),
        );

  final MockMcpService _mcp;

  Future<void> searchRestaurants(String query) async {
    final restaurants = await _mcp.getRestaurants(query: query, filter: state.filter);
    state = state.copyWith(restaurants: restaurants, search: query);
  }

  Future<void> setFilter(DietaryTag? filter) async {
    final restaurants = await _mcp.getRestaurants(query: state.search, filter: filter);
    state = state.copyWith(restaurants: restaurants, filter: filter, clearFilter: filter == null);
  }

  void selectRestaurant(String id) {
    state = state.copyWith(selectedRestaurantId: id);
  }

  void vote(String restaurantId) {
    final votes = Map<String, int>.from(state.votes);
    votes[restaurantId] = (votes[restaurantId] ?? 0) + 1;
    state = state.copyWith(
      votes: votes,
      activity: [
        ActivityEvent(id: 'a${DateTime.now().microsecondsSinceEpoch}', text: 'You voted for ${state.restaurants.firstWhere((r) => r.id == restaurantId).name}', time: DateTime.now()),
        ...state.activity,
      ],
    );
  }

  void addToCart(MenuItem item) {
    final existingIndex = state.cart.indexWhere((cartItem) => cartItem.item.id == item.id && cartItem.owner.id == mockParticipants.first.id);
    final cart = [...state.cart];
    if (existingIndex >= 0) {
      cart[existingIndex] = cart[existingIndex].copyWith(quantity: cart[existingIndex].quantity + 1);
    } else {
      cart.insert(0, CartItem(id: 'c${DateTime.now().microsecondsSinceEpoch}', item: item, owner: mockParticipants.first, quantity: 1));
    }
    state = state.copyWith(
      cart: cart,
      activity: [
        ActivityEvent(id: 'a${DateTime.now().microsecondsSinceEpoch}', text: 'You added ${item.name}', time: DateTime.now()),
        ...state.activity,
      ],
    );
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;
    state = state.copyWith(
      messages: [
        ChatMessage(id: 'm${DateTime.now().microsecondsSinceEpoch}', sender: mockParticipants.first, message: text.trim(), time: DateTime.now()),
        ...state.messages,
      ],
    );
  }

  void askAssistant(String prompt) {
    final lower = prompt.toLowerCase();
    final answer = lower.contains('budget')
        ? 'Budget-safe plan: order 2 party combos, 1 veg starter, 1 non-veg main, and split desserts. Current cart leaves about ₹${(state.room.budget - state.grandTotal).clamp(0, state.room.budget)}.'
        : lower.contains('veg')
            ? 'Vegetarian picks: Paneer Tikka Bowl, Rainbow Salad, Truffle Fries, and Brownie Box. They balance spicy, healthy, and sharing.'
            : 'I would lock ${state.selectedRestaurant.name}: high rating, ${state.selectedRestaurant.etaMinutes} min ETA, and enough veg/non-veg options for the room.';
    state = state.copyWith(assistantText: answer);
  }

  Future<void> checkout() async {
    final orderId = await _mcp.checkout(state.room.id, state.cart);
    final steps = await _mcp.getOrderTracking(orderId);
    state = state.copyWith(orderSteps: steps);
  }
}
