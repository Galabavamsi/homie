enum DietaryTag { veg, nonVeg, spicy, healthy, dessert, lateNight, party }

class Participant {
  const Participant({
    required this.id,
    required this.name,
    required this.avatar,
    required this.color,
    this.isOnline = true,
    this.isTyping = false,
    this.cursorLabel,
  });

  final String id;
  final String name;
  final String avatar;
  final int color;
  final bool isOnline;
  final bool isTyping;
  final String? cursorLabel;
}

class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.rating,
    required this.etaMinutes,
    required this.priceForTwo,
    required this.image,
    required this.tags,
    required this.offer,
  });

  final String id;
  final String name;
  final String cuisine;
  final double rating;
  final int etaMinutes;
  final int priceForTwo;
  final String image;
  final List<DietaryTag> tags;
  final String offer;
}

class MenuItem {
  const MenuItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    required this.tags,
    this.isCustomizable = true,
  });

  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final int price;
  final String image;
  final List<DietaryTag> tags;
  final bool isCustomizable;
}

class CartItem {
  const CartItem({
    required this.id,
    required this.item,
    required this.owner,
    required this.quantity,
    this.customization = 'Regular',
  });

  final String id;
  final MenuItem item;
  final Participant owner;
  final int quantity;
  final String customization;

  int get total => item.price * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      item: item,
      owner: owner,
      quantity: quantity ?? this.quantity,
      customization: customization,
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.message,
    required this.time,
    this.reaction,
  });

  final String id;
  final Participant sender;
  final String message;
  final DateTime time;
  final String? reaction;
}

class ActivityEvent {
  const ActivityEvent({
    required this.id,
    required this.text,
    required this.time,
  });

  final String id;
  final String text;
  final DateTime time;
}

class Room {
  const Room({
    required this.id,
    required this.name,
    required this.code,
    required this.inviteLink,
    required this.budget,
    required this.participants,
  });

  final String id;
  final String name;
  final String code;
  final String inviteLink;
  final int budget;
  final List<Participant> participants;
}

class OrderStep {
  const OrderStep({
    required this.title,
    required this.subtitle,
    required this.isComplete,
    required this.timestamp,
  });

  final String title;
  final String subtitle;
  final bool isComplete;
  final DateTime timestamp;
}

class HomieState {
  const HomieState({
    required this.room,
    required this.restaurants,
    required this.menu,
    required this.selectedRestaurantId,
    required this.votes,
    required this.cart,
    required this.messages,
    required this.activity,
    required this.orderSteps,
    this.search = '',
    this.filter,
    this.assistantText =
        'For this group, I suggest party-friendly meals under budget: biryani combos, garlic bread, paneer starters, and one dessert box.',
  });

  final Room room;
  final List<Restaurant> restaurants;
  final List<MenuItem> menu;
  final String selectedRestaurantId;
  final Map<String, int> votes;
  final List<CartItem> cart;
  final List<ChatMessage> messages;
  final List<ActivityEvent> activity;
  final List<OrderStep> orderSteps;
  final String search;
  final DietaryTag? filter;
  final String assistantText;

  int get subtotal => cart.fold(0, (sum, item) => sum + item.total);
  int get fees => cart.isEmpty ? 0 : 89;
  int get taxes => (subtotal * .05).round();
  int get grandTotal => subtotal + fees + taxes;

  Restaurant get selectedRestaurant =>
      restaurants.firstWhere((restaurant) => restaurant.id == selectedRestaurantId);

  List<MenuItem> get selectedMenu =>
      menu.where((item) => item.restaurantId == selectedRestaurantId).toList();

  HomieState copyWith({
    Room? room,
    List<Restaurant>? restaurants,
    List<MenuItem>? menu,
    String? selectedRestaurantId,
    Map<String, int>? votes,
    List<CartItem>? cart,
    List<ChatMessage>? messages,
    List<ActivityEvent>? activity,
    List<OrderStep>? orderSteps,
    String? search,
    DietaryTag? filter,
    bool clearFilter = false,
    String? assistantText,
  }) {
    return HomieState(
      room: room ?? this.room,
      restaurants: restaurants ?? this.restaurants,
      menu: menu ?? this.menu,
      selectedRestaurantId: selectedRestaurantId ?? this.selectedRestaurantId,
      votes: votes ?? this.votes,
      cart: cart ?? this.cart,
      messages: messages ?? this.messages,
      activity: activity ?? this.activity,
      orderSteps: orderSteps ?? this.orderSteps,
      search: search ?? this.search,
      filter: clearFilter ? null : filter ?? this.filter,
      assistantText: assistantText ?? this.assistantText,
    );
  }
}
