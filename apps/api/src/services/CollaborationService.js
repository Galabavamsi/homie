import { v4 as uuid } from 'uuid';

import { AppError, assertFound } from '../errors/AppError.js';

const guestColors = ['#ff6d21', '#2d6a4f', '#6c5ce7', '#e84393', '#0984e3'];

export class CollaborationService {
  constructor({ repository, restaurantService, menuService, orderService, publicUrl }) {
    this.repository = repository;
    this.restaurantService = restaurantService;
    this.menuService = menuService;
    this.orderService = orderService;
    this.publicUrl = publicUrl;
  }

  async createGuest(name) {
    const cleanName = name.trim().replace(/\s+/g, ' ');
    const words = cleanName.split(' ');
    const avatar = words.slice(0, 2).map((word) => word[0]).join('').toUpperCase();
    const id = uuid();
    return this.repository.createUser({
      id,
      name: cleanName,
      avatar,
      color: guestColors[id.charCodeAt(0) % guestColors.length]
    });
  }

  async createRoom({ name, budget, hostUserId }) {
    await this.#requireUser(hostUserId);
    return this.repository.createRoom({
      name: name.trim(),
      budget,
      hostUserId,
      publicUrl: this.publicUrl
    });
  }

  async getRoom(code) {
    return assertFound(
      await this.repository.getRoomSnapshot(code.toUpperCase()),
      'Room not found. Check the code and try again.'
    );
  }

  async joinRoom(code, userId, operationId) {
    return this.#idempotent(operationId, async () => {
      await this.#requireUser(userId);
      return this.repository.joinRoom(code, userId);
    });
  }

  async sendMessage(code, { userId, message, operationId }) {
    return this.#idempotent(operationId, async () => {
      const snapshot = await this.#requireOpenMember(code, userId);
      const cleanMessage = message.trim();
      if (!cleanMessage) {
        throw new AppError(400, 'empty_message', 'Message cannot be empty');
      }
      await this.repository.addMessage(snapshot.room.code, { userId, message: cleanMessage });
      return this.getRoom(snapshot.room.code);
    });
  }

  async vote(code, { userId, restaurantId, operationId }) {
    return this.#idempotent(operationId, async () => {
      const snapshot = await this.#requireOpenMember(code, userId);
      const restaurants = await this.restaurantService.list({});
      const restaurant = restaurants.find((item) => item.id === restaurantId);
      if (!restaurant) {
        throw new AppError(404, 'restaurant_not_found', 'Restaurant is no longer available');
      }
      return this.repository.castVote(snapshot.room.code, {
        userId,
        restaurantId,
        restaurantName: restaurant.name
      });
    });
  }

  async setCartItem(code, { userId, itemId, restaurantId, quantity, customization, operationId }) {
    return this.#idempotent(operationId, async () => {
      const snapshot = await this.#requireOpenMember(code, userId);
      const menu = await this.menuService.getRestaurantMenu(restaurantId);
      const canonicalItem = menu.find((item) => item.id === itemId);
      if (!canonicalItem) {
        throw new AppError(404, 'menu_item_not_found', 'Menu item is no longer available');
      }

      const otherRestaurant = snapshot.cart.find(
        (line) => line.item.restaurantId !== canonicalItem.restaurantId && line.quantity > 0
      );
      if (quantity > 0 && otherRestaurant) {
        throw new AppError(
          409,
          'mixed_restaurant_cart',
          'A shared room can checkout from one restaurant at a time. Clear the current cart first.'
        );
      }

      return this.repository.setCartItem(snapshot.room.code, {
        userId,
        item: canonicalItem,
        quantity,
        customization: customization.trim() || 'Regular'
      });
    });
  }

  async checkout(code, { userId, operationId, confirmed }) {
    return this.#idempotent(operationId, async () => {
      if (!confirmed) {
        throw new AppError(400, 'confirmation_required', 'Explicit checkout confirmation is required');
      }
      const snapshot = await this.#requireOpenMember(code, userId);
      if (snapshot.room.hostUserId !== userId) {
        throw new AppError(403, 'host_only', 'Only the room host can confirm checkout');
      }
      if (snapshot.cart.length === 0) {
        throw new AppError(409, 'empty_cart', 'Add at least one item before checkout');
      }

      const subtotal = snapshot.cart.reduce((sum, line) => sum + line.item.price * line.quantity, 0);
      const taxes = Math.round(subtotal * 0.05);
      const fees = 89;
      const total = subtotal + taxes + fees;
      if (total >= 1000) {
        throw new AppError(
          409,
          'beta_cart_limit',
          'The local Swiggy Food beta checkout must remain below INR 1,000',
          { total, limit: 1000 }
        );
      }

      const mcpOrder = await this.orderService.checkout(snapshot.room.id, snapshot.cart);
      const createdAt = new Date().toISOString();
      const order = {
        id: uuid(),
        roomId: snapshot.room.id,
        userId,
        swiggyOrderId: mcpOrder.orderId,
        status: mcpOrder.status || 'confirmed',
        subtotal,
        taxes,
        fees,
        total,
        createdAt,
        timeline: [
          { status: 'confirmed', label: 'Order confirmed', detail: 'Swiggy accepted the checkout', complete: true, timestamp: createdAt },
          { status: 'preparing', label: 'Preparing', detail: 'Restaurant is preparing the group order', complete: false, timestamp: createdAt },
          { status: 'picked_up', label: 'Picked up', detail: 'Waiting for delivery partner pickup', complete: false, timestamp: createdAt },
          { status: 'on_the_way', label: 'On the way', detail: 'ETA appears after pickup', complete: false, timestamp: createdAt },
          { status: 'delivered', label: 'Delivered', detail: 'Everyone in the room is notified', complete: false, timestamp: createdAt }
        ]
      };
      return this.repository.createOrder(snapshot.room.code, order);
    });
  }

  async getOrder(orderId) {
    return assertFound(await this.repository.getOrder(orderId), 'Order not found');
  }

  async #requireUser(userId) {
    return assertFound(await this.repository.getUser(userId), 'User session not found');
  }

  async #requireOpenMember(code, userId) {
    const snapshot = await this.getRoom(code);
    if (!snapshot.room.participants.some((participant) => participant.id === userId)) {
      throw new AppError(403, 'not_a_member', 'Join this room before changing it');
    }
    if (snapshot.room.status !== 'open') {
      throw new AppError(409, 'room_locked', 'This room has already checked out');
    }
    return snapshot;
  }

  async #idempotent(operationId, action) {
    if (operationId) {
      const previous = await this.repository.findOperation(operationId);
      if (previous) return previous;
    }
    const result = await action();
    if (operationId) await this.repository.recordOperation(operationId, result);
    return result;
  }
}
