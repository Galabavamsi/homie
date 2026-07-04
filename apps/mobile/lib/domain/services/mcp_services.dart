import '../models/homie_models.dart';

abstract interface class RestaurantService {
  Future<List<Restaurant>> getRestaurants({String? query, DietaryTag? filter});
}

abstract interface class MenuService {
  Future<List<MenuItem>> getMenu(String restaurantId);
}

abstract interface class CartService {
  Future<List<CartItem>> syncCart(String roomId, List<CartItem> cart);
}

abstract interface class OrderService {
  Future<String> checkout(String roomId, List<CartItem> cart);
  Future<List<OrderStep>> getOrderTracking(String orderId);
}

abstract interface class UserService {
  Future<Participant> getCurrentUser();
  Future<List<Participant>> getRoomParticipants(String roomId);
}
