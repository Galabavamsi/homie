export class DemoAgentService {
  constructor(mcpService) {
    this.mcpService = mcpService;
  }

  async runFoodOrderDemo({ query = 'pizza', confirmOrder = false } = {}) {
    const transcript = [];
    const step = async (tool, args = {}) => {
      const data = await this.mcpService.callFoodTool(tool, args);
      transcript.push({ tool, args, data });
      return data;
    };

    const addressResult = await step('get_addresses');
    const address = addressResult.addresses?.[0];
    if (!address) {
      return {
        status: 'blocked',
        reason: 'No saved Swiggy address found. Ask the user to add one in Swiggy.',
        transcript
      };
    }

    const restaurantResult = await step('search_restaurants', {
      addressId: address.id,
      query
    });
    const restaurants = restaurantResult.restaurants || [];
    const restaurant =
      restaurants.find((item) => item.availabilityStatus === 'OPEN') || restaurants[0];

    if (!restaurant) {
      return {
        status: 'blocked',
        reason: `No restaurants found for "${query}".`,
        transcript
      };
    }

    const menuResult = await step('get_restaurant_menu', {
      restaurantId: restaurant.id
    });
    const item = menuResult.items?.[0];
    if (!item) {
      return {
        status: 'blocked',
        reason: `${restaurant.name} has no menu items in the current MCP response.`,
        transcript
      };
    }

    const cartItems = [{ itemId: item.id, quantity: 1 }];
    await step('update_food_cart', {
      restaurantId: restaurant.id,
      items: cartItems
    });

    const cart = await step('get_food_cart', {
      restaurantId: restaurant.id,
      items: cartItems
    });

    if (cart.total >= 1000) {
      return {
        status: 'needs_cart_reduction',
        reason: 'Builders Club beta Food orders must stay below ₹1000.',
        address,
        restaurant,
        selectedItem: item,
        cart,
        transcript
      };
    }

    const confirmation = {
      message: `Ready to place a COD Swiggy order from ${restaurant.name} to ${address.displayText} for ₹${cart.total}.`,
      required: true
    };

    if (!confirmOrder) {
      return {
        status: 'awaiting_user_confirmation',
        address,
        restaurant,
        selectedItem: item,
        cart,
        confirmation,
        transcript
      };
    }

    const order = await step('place_food_order', {
      addressId: address.id,
      paymentMethod: cart.availablePaymentMethods?.[0] || 'COD'
    });

    const tracking = await step('track_food_order', {
      orderId: order.orderId
    });

    return {
      status: 'placed',
      address,
      restaurant,
      selectedItem: item,
      cart,
      order,
      tracking,
      transcript
    };
  }
}
