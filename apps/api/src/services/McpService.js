import { menus, restaurants } from '../data/mockData.js';

export class McpService {
  constructor({ baseUrl, foodUrl, mode, oauthCallback, oauthService, fetchImpl = fetch }) {
    this.baseUrl = baseUrl;
    this.foodUrl = foodUrl;
    this.mode = mode;
    this.oauthCallback = oauthCallback;
    this.oauthService = oauthService;
    this.fetchImpl = fetchImpl;
    this.selectedAddresses = new Map();
  }

  async getAddresses({ userId, authorization } = {}) {
    return this.callFoodTool('get_addresses', {}, { userId, authorization });
  }

  async selectAddress({ userId, addressId, authorization }) {
    const result = await this.getAddresses({ userId, authorization });
    const addresses = result.addresses || result.data?.addresses || [];
    if (!addresses.some((address) => address.id === addressId)) {
      throw Object.assign(
        new Error('Choose an address returned by Swiggy before continuing'),
        { status: 400, code: 'swiggy_address_invalid' }
      );
    }
    this.selectedAddresses.set(userId, addressId);
    return { addressId };
  }

  async getRestaurants({ query, tag, userId, addressId }) {
    if (this.mode === 'live') {
      const selectedAddressId = this.#liveAddressId(userId, addressId);
      const result = await this.callLiveFoodTool('search_restaurants', {
        addressId: selectedAddressId,
        query: [query, tag].filter(Boolean).join(' ') || 'popular restaurants'
      }, { userId });
      return this.#restaurantsFrom(result);
    }
    return restaurants.filter((restaurant) => {
      const text = `${restaurant.name} ${restaurant.cuisine}`.toLowerCase();
      const matchesQuery = !query || text.includes(query.toLowerCase());
      const matchesTag = !tag || restaurant.tags.includes(tag);
      return matchesQuery && matchesTag;
    });
  }

  async getMenu(restaurantId, { userId, addressId } = {}) {
    if (this.mode === 'live') {
      const result = await this.callLiveFoodTool('get_restaurant_menu', {
        addressId: this.#liveAddressId(userId, addressId),
        restaurantId
      }, { userId });
      return this.#menuItemsFrom(result, restaurantId);
    }
    return menus[restaurantId] || [];
  }

  async createCart(payload) {
    if (this.mode === 'live') {
      if (!payload.restaurantId || !Array.isArray(payload.cartItems)) {
        throw Object.assign(
          new Error('Live cart sync requires restaurantId and Swiggy-shaped cartItems'),
          { status: 501, code: 'live_cart_mapping_required' }
        );
      }
      return this.callLiveFoodTool('update_food_cart', {
        ...payload,
        addressId: payload.addressId || this.#liveAddressId()
      });
    }
    return {
      swiggyCartId: `swiggy_mock_cart_${Date.now()}`,
      source: 'swiggy_mcp_mock',
      ...payload
    };
  }

  async checkout({ roomId, cart }) {
    if (this.mode === 'live') {
      throw Object.assign(
        new Error(
          'Live checkout is blocked until Homie maps Swiggy cart customizations, calls get_food_cart, and confirms a saved address'
        ),
        {
          status: 501,
          code: 'live_checkout_reconciliation_required',
          details: { roomId, cartLines: cart.length }
        }
      );
    }
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
    if (this.mode === 'live') {
      return this.callLiveFoodTool('track_food_order', { orderId });
    }
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
    const authorization = options.authorization ||
      await this.oauthService?.authorizationFor(options.userId) ||
      process.env.SWIGGY_TOKEN;
    if (!authorization) {
      throw Object.assign(
        new Error('Live Swiggy MCP mode requires Authorization: Bearer <token> or SWIGGY_TOKEN'),
        { status: 401 }
      );
    }

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 10000);
    let response;
    try {
      response = await this.fetchImpl(this.foodUrl, {
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
        }),
        signal: controller.signal
      });
    } catch (error) {
      if (error.name === 'AbortError') {
        throw Object.assign(new Error('Swiggy MCP request timed out'), {
          status: 504,
          code: 'swiggy_timeout'
        });
      }
      throw Object.assign(new Error('Could not reach Swiggy MCP'), {
        status: 502,
        code: 'swiggy_unreachable'
      });
    } finally {
      clearTimeout(timeout);
    }

    let payload = {};
    try {
      payload = await response.json();
    } catch {
      payload = {};
    }
    if (!response.ok || payload.error) {
      const message = payload?.error?.message || `Swiggy MCP call failed with ${response.status}`;
      throw Object.assign(new Error(message), { status: response.status, payload });
    }
    const result = payload.result?.data ?? payload.result ?? payload;
    if (result?.success === false) {
      throw Object.assign(new Error(result.error?.message || 'Swiggy MCP tool failed'), {
        status: 502,
        code: result.error?.code || 'swiggy_tool_failed',
        payload: result
      });
    }
    return result?.data ?? result;
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

  #liveAddressId(userId, addressId) {
    const selectedAddressId = addressId || this.selectedAddresses.get(userId) || process.env.SWIGGY_ADDRESS_ID;
    const addressIdValue = typeof selectedAddressId === 'string' ? selectedAddressId.trim() : '';
    if (!addressIdValue) {
      throw Object.assign(
        new Error('Choose a saved Swiggy delivery address before browsing food'),
        { status: 412, code: 'swiggy_address_required' }
      );
    }
    return addressIdValue;
  }

  #restaurantsFrom(result) {
    const restaurants = Array.isArray(result.restaurants)
      ? result.restaurants
      : Array.isArray(result.data?.restaurants)
        ? result.data.restaurants
        : [];
    return restaurants
      .filter((restaurant) => restaurant && typeof restaurant.id === 'string' && restaurant.id.length > 0)
      .filter((restaurant) => !restaurant.availabilityStatus || String(restaurant.availabilityStatus).toUpperCase() === 'OPEN')
      .map((restaurant) => ({
        id: restaurant.id,
        name: restaurant.name || 'Swiggy restaurant',
        cuisine: this.#cuisinesFrom(restaurant).join(', ') || 'Multi-cuisine',
        rating: restaurant.avgRating ?? restaurant.rating ?? 0,
        etaMinutes: restaurant.deliveryTimeMinutes ?? restaurant.etaMinutes ?? 0,
        priceForTwo: this.#priceNumber(restaurant.costForTwo),
        image: restaurant.imageUrl || restaurant.image || '',
        tags: [
          ...(restaurant.veg ? ['veg'] : []),
          ...this.#cuisinesFrom(restaurant).map((cuisine) => cuisine.toLowerCase())
        ],
        offer: restaurant.offer || ''
      }));
  }

  #menuItemsFrom(result, restaurantId) {
    if (Array.isArray(result.items)) {
      return result.items
        .filter((item) => item && typeof item.id === 'string' && item.id.length > 0)
        .map((item) => this.#menuItem(item, restaurantId));
    }
    const categories = Array.isArray(result.categories)
      ? result.categories
      : Array.isArray(result.data?.categories)
        ? result.data.categories
        : [];
    return categories.flatMap((category) => [
      ...(category.items || []),
      ...(category.subcategories || []).flatMap((nested) => nested.items || [])
    ]).filter((item) => item && typeof item.id === 'string' && item.id.length > 0)
      .map((item) => this.#menuItem(item, restaurantId));
  }

  #menuItem(item, restaurantId) {
    return {
      id: item.id,
      restaurantId: item.restaurantId || restaurantId,
      name: item.name || 'Menu item',
      description: item.description || '',
      price: this.#priceNumber(item.price),
      image: item.imageUrl || item.image || '',
      tags: item.isVeg ? ['veg'] : ['nonVeg'],
      isCustomizable: Boolean(item.hasVariants || item.hasAddons)
    };
  }

  #cuisinesFrom(restaurant) {
    if (Array.isArray(restaurant.cuisines)) {
      return restaurant.cuisines
        .filter((cuisine) => typeof cuisine === 'string' && cuisine.trim().length > 0)
        .map((cuisine) => cuisine.trim());
    }
    return typeof restaurant.cuisine === 'string' && restaurant.cuisine.trim().length > 0
      ? [restaurant.cuisine.trim()]
      : [];
  }

  #priceNumber(value) {
    if (typeof value === 'number') return Math.round(value);
    const parsed = Number(String(value || '').replace(/[^0-9.]/g, ''));
    return Number.isFinite(parsed) ? Math.round(parsed) : 0;
  }
}
