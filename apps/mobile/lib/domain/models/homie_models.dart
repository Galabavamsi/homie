enum DietaryTag { veg, nonVeg, spicy, healthy, dessert, lateNight, party }

enum RealtimeStatus { idle, connecting, connected, reconnecting, offline }

DietaryTag? dietaryTagFromJson(Object? value) {
  final text = value?.toString();
  for (final tag in DietaryTag.values) {
    if (tag.name == text) return tag;
  }
  return null;
}

int colorFromJson(Object? value) {
  if (value is int) return value;
  final hex = value?.toString().replaceFirst('#', '') ?? 'ff6d21';
  return int.tryParse('FF$hex', radix: 16) ?? 0xFFFF6D21;
}

DateTime dateFromJson(Object? value) =>
    DateTime.tryParse(value?.toString() ?? '')?.toLocal() ?? DateTime.now();

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

  factory Participant.fromJson(Map<String, dynamic> json) => Participant(
        id: json['id'].toString(),
        name: json['name']?.toString() ?? 'Guest',
        avatar: json['avatar']?.toString() ?? 'G',
        color: colorFromJson(json['color']),
        isOnline: false,
      );

  final String id;
  final String name;
  final String avatar;
  final int color;
  final bool isOnline;
  final bool isTyping;
  final String? cursorLabel;

  Participant copyWith({bool? isOnline, bool? isTyping, String? cursorLabel}) {
    return Participant(
      id: id,
      name: name,
      avatar: avatar,
      color: color,
      isOnline: isOnline ?? this.isOnline,
      isTyping: isTyping ?? this.isTyping,
      cursorLabel: cursorLabel ?? this.cursorLabel,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatar': avatar,
        'color': color,
      };
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

  factory Restaurant.fromJson(Map<String, dynamic> json) => Restaurant(
        id: json['id'].toString(),
        name: json['name']?.toString() ?? 'Restaurant',
        cuisine: json['cuisine']?.toString() ?? 'Multi-cuisine',
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        etaMinutes: (json['etaMinutes'] as num?)?.toInt() ?? 0,
        priceForTwo: (json['priceForTwo'] as num?)?.toInt() ?? 0,
        image: json['image']?.toString() ?? '',
        tags: (json['tags'] as List? ?? const [])
            .map(dietaryTagFromJson)
            .whereType<DietaryTag>()
            .toList(),
        offer: json['offer']?.toString() ?? '',
      );

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

class DeliveryAddress {
  const DeliveryAddress({
    required this.id,
    required this.label,
    required this.displayText,
    required this.city,
  });

  final String id;
  final String label;
  final String displayText;
  final String city;
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

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
        id: json['id'].toString(),
        restaurantId: json['restaurantId']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Menu item',
        description: json['description']?.toString() ?? '',
        price: (json['price'] as num?)?.toInt() ?? 0,
        image: json['image']?.toString() ?? '',
        tags: (json['tags'] as List? ?? const [])
            .map(dietaryTagFromJson)
            .whereType<DietaryTag>()
            .toList(),
        isCustomizable: json['isCustomizable'] as bool? ?? true,
      );

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

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: json['id'].toString(),
        item: MenuItem.fromJson(Map<String, dynamic>.from(json['item'] as Map)),
        owner: Participant.fromJson(
            Map<String, dynamic>.from(json['owner'] as Map)),
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        customization: json['customization']?.toString() ?? 'Regular',
      );

  final String id;
  final MenuItem item;
  final Participant owner;
  final int quantity;
  final String customization;

  int get total => item.price * quantity;

  CartItem copyWith({int? quantity, Participant? owner}) {
    return CartItem(
      id: id,
      item: item,
      owner: owner ?? this.owner,
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

  ChatMessage copyWith({Participant? sender}) => ChatMessage(
        id: id,
        sender: sender ?? this.sender,
        message: message,
        time: time,
        reaction: reaction,
      );
}

class ActivityEvent {
  const ActivityEvent(
      {required this.id, required this.text, required this.time});

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
    this.hostUserId = '',
    this.status = 'open',
    this.version = 1,
  });

  final String id;
  final String name;
  final String code;
  final String inviteLink;
  final int budget;
  final List<Participant> participants;
  final String hostUserId;
  final String status;
  final int version;

  Room copyWith({List<Participant>? participants}) => Room(
        id: id,
        name: name,
        code: code,
        inviteLink: inviteLink,
        budget: budget,
        participants: participants ?? this.participants,
        hostUserId: hostUserId,
        status: status,
        version: version,
      );
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

class RoomSnapshot {
  const RoomSnapshot({
    required this.room,
    required this.votes,
    required this.userVotes,
    required this.cart,
    required this.messages,
    required this.activity,
    required this.orderSteps,
    this.orderId,
  });

  factory RoomSnapshot.fromJson(Map<String, dynamic> json) {
    final roomJson = Map<String, dynamic>.from(json['room'] as Map);
    final participants = (roomJson['participants'] as List? ?? const [])
        .map((value) =>
            Participant.fromJson(Map<String, dynamic>.from(value as Map)))
        .toList();
    final byId = {
      for (final participant in participants) participant.id: participant
    };
    Participant participant(String id) =>
        byId[id] ??
        const Participant(
          id: 'unknown',
          name: 'Guest',
          avatar: 'G',
          color: 0xFFFF6D21,
          isOnline: false,
        );

    final order = json['order'] is Map
        ? Map<String, dynamic>.from(json['order'] as Map)
        : null;
    final timeline = (order?['timeline'] as List? ?? const []).map((value) {
      final step = Map<String, dynamic>.from(value as Map);
      return OrderStep(
        title: step['label']?.toString() ?? 'Order update',
        subtitle: step['detail']?.toString() ?? '',
        isComplete: step['complete'] as bool? ?? false,
        timestamp: dateFromJson(step['timestamp']),
      );
    }).toList();

    return RoomSnapshot(
      room: Room(
        id: roomJson['id'].toString(),
        name: roomJson['name']?.toString() ?? 'Ordering room',
        code: roomJson['code']?.toString() ?? '',
        inviteLink: roomJson['inviteLink']?.toString() ?? '',
        budget: (roomJson['budget'] as num?)?.toInt() ?? 0,
        participants: participants,
        hostUserId: roomJson['hostUserId']?.toString() ?? '',
        status: roomJson['status']?.toString() ?? 'open',
        version: (roomJson['version'] as num?)?.toInt() ?? 1,
      ),
      votes: Map<String, dynamic>.from(json['votes'] as Map? ?? const {})
          .map((key, value) => MapEntry(key, (value as num).toInt())),
      userVotes:
          Map<String, dynamic>.from(json['userVotes'] as Map? ?? const {})
              .map((key, value) => MapEntry(key, value.toString())),
      cart: (json['cart'] as List? ?? const [])
          .map((value) =>
              CartItem.fromJson(Map<String, dynamic>.from(value as Map)))
          .toList(),
      messages: (json['messages'] as List? ?? const []).map((value) {
        final message = Map<String, dynamic>.from(value as Map);
        return ChatMessage(
          id: message['id'].toString(),
          sender: participant(message['userId'].toString()),
          message: message['message']?.toString() ?? '',
          time: dateFromJson(message['createdAt']),
          reaction: message['reaction']?.toString(),
        );
      }).toList(),
      activity: (json['activity'] as List? ?? const []).map((value) {
        final event = Map<String, dynamic>.from(value as Map);
        return ActivityEvent(
          id: event['id'].toString(),
          text: event['text']?.toString() ?? '',
          time: dateFromJson(event['createdAt']),
        );
      }).toList(),
      orderSteps: timeline,
      orderId: order?['id']?.toString(),
    );
  }

  final Room room;
  final Map<String, int> votes;
  final Map<String, String> userVotes;
  final List<CartItem> cart;
  final List<ChatMessage> messages;
  final List<ActivityEvent> activity;
  final List<OrderStep> orderSteps;
  final String? orderId;
}

class HomieState {
  const HomieState({
    required this.currentUser,
    required this.room,
    required this.restaurants,
    required this.menu,
    required this.selectedRestaurantId,
    required this.votes,
    required this.cart,
    required this.messages,
    required this.activity,
    required this.orderSteps,
    this.userVotes = const {},
    this.search = '',
    this.filter,
    this.hasSession = false,
    this.swiggyConnected = false,
    this.swiggyExpiresAt,
    this.addresses = const [],
    this.selectedAddressId,
    this.isLoading = false,
    this.isBusy = false,
    this.realtimeStatus = RealtimeStatus.idle,
    this.errorMessage,
    this.mcpSource = 'swiggy_mcp_mock',
    this.assistantText =
        'For this group, I suggest party-friendly meals under budget: biryani combos, garlic bread, paneer starters, and one dessert box.',
  });

  final Participant currentUser;
  final Room room;
  final List<Restaurant> restaurants;
  final List<MenuItem> menu;
  final String selectedRestaurantId;
  final Map<String, int> votes;
  final Map<String, String> userVotes;
  final List<CartItem> cart;
  final List<ChatMessage> messages;
  final List<ActivityEvent> activity;
  final List<OrderStep> orderSteps;
  final String search;
  final DietaryTag? filter;
  final bool hasSession;
  final bool swiggyConnected;
  final String? swiggyExpiresAt;
  final List<DeliveryAddress> addresses;
  final String? selectedAddressId;
  final bool isLoading;
  final bool isBusy;
  final RealtimeStatus realtimeStatus;
  final String? errorMessage;
  final String mcpSource;
  final String assistantText;

  int get subtotal => cart.fold(0, (sum, item) => sum + item.total);
  int get fees => cart.isEmpty ? 0 : 89;
  int get taxes => (subtotal * .05).round();
  int get grandTotal => subtotal + fees + taxes;
  bool get isHost => room.hostUserId == currentUser.id;
  bool get isRoomLocked => room.status != 'open';
  String? get myVote => userVotes[currentUser.id];

  Restaurant get selectedRestaurant {
    if (restaurants.isEmpty) {
      return const Restaurant(
        id: '',
        name: 'Choose a restaurant',
        cuisine: '',
        rating: 0,
        etaMinutes: 0,
        priceForTwo: 0,
        image: '',
        tags: [],
        offer: '',
      );
    }
    return restaurants.firstWhere(
      (restaurant) => restaurant.id == selectedRestaurantId,
      orElse: () => restaurants.first,
    );
  }

  List<MenuItem> get selectedMenu =>
      menu.where((item) => item.restaurantId == selectedRestaurantId).toList();

  HomieState copyWith({
    Participant? currentUser,
    Room? room,
    List<Restaurant>? restaurants,
    List<MenuItem>? menu,
    String? selectedRestaurantId,
    Map<String, int>? votes,
    Map<String, String>? userVotes,
    List<CartItem>? cart,
    List<ChatMessage>? messages,
    List<ActivityEvent>? activity,
    List<OrderStep>? orderSteps,
    String? search,
    DietaryTag? filter,
    bool clearFilter = false,
    bool? hasSession,
    bool? swiggyConnected,
    String? swiggyExpiresAt,
    List<DeliveryAddress>? addresses,
    String? selectedAddressId,
    bool? isLoading,
    bool? isBusy,
    RealtimeStatus? realtimeStatus,
    String? errorMessage,
    bool clearError = false,
    String? mcpSource,
    String? assistantText,
  }) {
    return HomieState(
      currentUser: currentUser ?? this.currentUser,
      room: room ?? this.room,
      restaurants: restaurants ?? this.restaurants,
      menu: menu ?? this.menu,
      selectedRestaurantId: selectedRestaurantId ?? this.selectedRestaurantId,
      votes: votes ?? this.votes,
      userVotes: userVotes ?? this.userVotes,
      cart: cart ?? this.cart,
      messages: messages ?? this.messages,
      activity: activity ?? this.activity,
      orderSteps: orderSteps ?? this.orderSteps,
      search: search ?? this.search,
      filter: clearFilter ? null : filter ?? this.filter,
      hasSession: hasSession ?? this.hasSession,
      swiggyConnected: swiggyConnected ?? this.swiggyConnected,
      swiggyExpiresAt: swiggyExpiresAt ?? this.swiggyExpiresAt,
      addresses: addresses ?? this.addresses,
      selectedAddressId: selectedAddressId ?? this.selectedAddressId,
      isLoading: isLoading ?? this.isLoading,
      isBusy: isBusy ?? this.isBusy,
      realtimeStatus: realtimeStatus ?? this.realtimeStatus,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      mcpSource: mcpSource ?? this.mcpSource,
      assistantText: assistantText ?? this.assistantText,
    );
  }
}
