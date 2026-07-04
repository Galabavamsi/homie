import { menus, restaurants } from '../data/mockData.js';

export class McpService {
  constructor({ baseUrl, foodUrl, mode, oauthCallback }) {
    this.baseUrl = baseUrl;
    this.foodUrl = foodUrl;
    this.mode = mode;
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

  async callFoodTool(name, args = {}, options = {}) {
    if (this.mode === 'live') {
      return this.callLiveFoodTool(name, args, options);
    }
    return this.callMockFoodTool(name, args);
  }

  async callLiveFoodTool(name, args = {}, options = {}) {
    const authorization = options.authorization || process.env.SWIGGY_TOKEN;
    if (!authorization) {
      throw Object.assign(
        new Error('Live Swiggy MCP mode requires Authorization: Bearer <token> or SWIGGY_TOKEN'),
        { status: 401 }
      );
    }

    const response = await fetch(this.foodUrl, {
      method: 'POST',
      headers: {
        Authorization: authorization.startsWith('Bearer ') ? authorization : `Bearer ${authorization}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        jsonrpc: '2.0',
        method: 'tools/call',
        params: {
          name,
          arguments: args
        },
        id: Date.now()
      })
    });

    const payload = await response.json();
    if (!response.ok || payload.error) {
      const message = payload?.error?.message || `Swiggy MCP call failed with ${response.status}`;
      throw Object.assign(new Error(message), { status: response.status, payload });
    }
    return payload.result?.data ?? payload.result ?? payload;
  }

  async callMockFoodTool(name, args = {}) {
    switch (name) {
      case 'get_addresses':
        return {
          addresses: [
            {
              id: 'addr_home_001',
              label: 'Home',
              displayText: 'HSR Layout, Bengaluru',
              city: 'Bengaluru'
            }
          ]
        };
      case 'search_restaurants':
        return {
          restaurants: await this.getRestaurants({
            query: args.query || 'popular',
            tag: args.tag
          }),
          nextOffset: null
        };
      case 'get_restaurant_menu':
        return {
          restaurantId: args.restaurantId,
          items: await this.getMenu(args.restaurantId)
        };
      case 'search_menu': {
        const allItems = Object.values(menus).flat();
        const query = String(args.query || '').toLowerCase();
        return {
          items: allItems.filter((item) =>
            `${item.name} ${item.description}`.toLowerCase().includes(query)
          )
        };
      }
      case 'update_food_cart':
        return {
          restaurantId: args.restaurantId,
          items: args.items || [],
          message: 'Mock Swiggy food cart updated'
        };
      case 'get_food_cart':
        return {
          restaurantId: args.restaurantId || 'r0',
          items: args.items || [],
          total: 810,
          currency: 'INR',
          availablePaymentMethods: ['COD'],
          cap: 1000
        };
      case 'fetch_food_coupons':
        return {
          coupons: [
            { code: 'HOMIE20', description: '20% off mock Swiggy coupon', requiresOnlinePayment: false }
          ]
        };
      case 'apply_food_coupon':
        return {
          code: args.code,
          message: 'Mock coupon applied to Swiggy food cart'
        };
      case 'flush_food_cart':
        return {
          items: [],
          message: 'Mock Swiggy food cart cleared'
        };
      case 'place_food_order':
        return {
          orderId: `swiggy_mock_order_${Math.floor(Math.random() * 9000 + 1000)}`,
          paymentMethod: args.paymentMethod || 'COD',
          message: 'Swiggy order placed successfully'
        };
      case 'get_food_orders':
        return {
          orders: [
            {
              orderId: 'swiggy_mock_order_8842',
              status: 'on_the_way',
              placedAt: new Date().toISOString()
            }
          ]
        };
      case 'track_food_order':
        return this.getOrder(args.orderId || 'swiggy_mock_order_8842');
      default:
        throw Object.assign(new Error(`Unsupported Food MCP tool: ${name}`), { status: 400 });
    }
  }
}
