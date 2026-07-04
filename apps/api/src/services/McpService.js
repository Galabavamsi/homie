import { menus, restaurants } from '../data/mockData.js';

export class McpService {
  constructor({ baseUrl, oauthCallback }) {
    this.baseUrl = baseUrl;
    this.oauthCallback = oauthCallback;
  }

  async getRestaurants({ query, tag }) {
    return restaurants.filter((restaurant) => {
      const text = `${restaurant.name} ${restaurant.cuisine}`.toLowerCase();
      const matchesQuery = !query || text.includes(query.toLowerCase());
      const matchesTag = !tag || restaurant.tags.includes(tag);
      return matchesQuery && matchesTag;
    });
  }

  async getMenu(restaurantId) {
    return menus[restaurantId] || [];
  }

  async createCart(payload) {
    return {
      swiggyCartId: `swiggy_mock_cart_${Date.now()}`,
      source: 'swiggy_mcp_mock',
      ...payload
    };
  }

  async checkout({ roomId, cart }) {
    return {
      orderId: `swiggy_mock_order_${Math.floor(Math.random() * 9000 + 1000)}`,
      roomId,
      status: 'confirmed',
      totalItems: cart.length,
      paymentProvider: 'swiggy',
      checkoutOwner: 'swiggy_mcp'
    };
  }

  async getOrder(orderId) {
    return {
      orderId,
      status: 'on_the_way',
      etaMinutes: 11,
      timeline: [
        { status: 'confirmed', label: 'Order confirmed', complete: true },
        { status: 'preparing', label: 'Preparing', complete: true },
        { status: 'picked_up', label: 'Picked up', complete: true },
        { status: 'on_the_way', label: 'On the way', complete: false },
        { status: 'delivered', label: 'Delivered', complete: false }
      ]
    };
  }
}
