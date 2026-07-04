import '../../core/mock_data.dart';
import '../../domain/models/homie_models.dart';
import '../../domain/services/mcp_services.dart';

class MockMcpService
    implements RestaurantService, MenuService, CartService, OrderService, UserService {
  @override
  Future<List<Restaurant>> getRestaurants({String? query, DietaryTag? filter}) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return mockRestaurants.where((restaurant) {
      final matchesQuery = query == null ||
          query.isEmpty ||
          restaurant.name.toLowerCase().contains(query.toLowerCase()) ||
          restaurant.cuisine.toLowerCase().contains(query.toLowerCase());
      final matchesFilter = filter == null || restaurant.tags.contains(filter);
      return matchesQuery && matchesFilter;
    }).toList();
  }

  @override
  Future<List<MenuItem>> getMenu(String restaurantId) async {
    await Future<void>.delayed(const Duration(milliseconds: 140));
    return mockMenu.where((item) => item.restaurantId == restaurantId).toList();
  }

  @override
  Future<List<CartItem>> syncCart(String roomId, List<CartItem> cart) async => cart;

  @override
  Future<String> checkout(String roomId, List<CartItem> cart) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return 'swiggy_mock_order_8842';
  }

  @override
  Future<List<OrderStep>> getOrderTracking(String orderId) async {
    final now = DateTime.now();
    return [
      OrderStep(title: 'Order confirmed', subtitle: 'Swiggy MCP accepted the checkout', isComplete: true, timestamp: now.subtract(const Duration(minutes: 18))),
      OrderStep(title: 'Preparing', subtitle: 'Restaurant is packing the group order', isComplete: true, timestamp: now.subtract(const Duration(minutes: 12))),
      OrderStep(title: 'Picked up', subtitle: 'Delivery partner has the food', isComplete: true, timestamp: now.subtract(const Duration(minutes: 4))),
      OrderStep(title: 'On the way', subtitle: 'Arriving in 11 minutes', isComplete: false, timestamp: now),
      OrderStep(title: 'Delivered', subtitle: 'Everyone gets notified', isComplete: false, timestamp: now.add(const Duration(minutes: 11))),
    ];
  }

  @override
  Future<Participant> getCurrentUser() async => mockParticipants.first;

  @override
  Future<List<Participant>> getRoomParticipants(String roomId) async => mockParticipants;
}
