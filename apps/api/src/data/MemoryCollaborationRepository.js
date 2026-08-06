import { v4 as uuid } from 'uuid';

import { menus, users } from './mockData.js';
import { AppError } from '../errors/AppError.js';

const now = () => new Date().toISOString();

export class MemoryCollaborationRepository {
  constructor({ seed = true } = {}) {
    this.kind = 'memory';
    this.users = new Map();
    this.rooms = new Map();
    this.operations = new Map();
    this.orders = new Map();

    for (const user of users) this.users.set(user.id, { ...user });
    if (seed) this.#seedDemoRoom();
  }

  #seedDemoRoom() {
    const createdAt = now();
    const room = {
      id: 'room_1',
      code: 'HOMIE42',
      name: 'Friday House Party',
      budget: 2500,
      hostUserId: 'u1',
      status: 'open',
      version: 1,
      createdAt,
      participantIds: new Set(users.map((user) => user.id)),
      messages: [
        {
          id: 'm1',
          userId: 'u2',
          message: 'Can we keep it spicy but not too heavy?',
          reaction: 'fire',
          createdAt
        },
        {
          id: 'm2',
          userId: 'u3',
          message: 'I am vegetarian tonight. Paneer or dosa works.',
          reaction: null,
          createdAt
        }
      ],
      userVotes: new Map([
        ['u1', 'r0'],
        ['u2', 'r0'],
        ['u3', 'r1'],
        ['u4', 'r0'],
        ['u5', 'r2']
      ]),
      cart: [
        {
          id: 'cart_seed_1',
          userId: 'u2',
          item: { ...menus.r0[1] },
          quantity: 1,
          customization: 'Regular',
          createdAt,
          updatedAt: createdAt
        },
        {
          id: 'cart_seed_2',
          userId: 'u3',
          item: { ...menus.r0[2] },
          quantity: 2,
          customization: 'Regular',
          createdAt,
          updatedAt: createdAt
        }
      ],
      activity: [
        { id: 'a1', userId: 'u3', text: 'Maya voted for Pizza Ritual', createdAt },
        { id: 'a2', userId: 'u2', text: 'Aarav added Chicken Biryani', createdAt },
        { id: 'a3', userId: 'u4', text: 'Zoya joined via invite link', createdAt }
      ]
    };
    this.rooms.set(room.code, room);
  }

  async readiness() {
    return { ok: true, kind: this.kind };
  }

  async createUser(user) {
    this.users.set(user.id, { ...user });
    return { ...user };
  }

  async getUser(userId) {
    const user = this.users.get(userId);
    return user ? { ...user } : null;
  }

  async createRoom({ name, budget, hostUserId, publicUrl }) {
    let code;
    do {
      code = `HM${Math.random().toString(36).slice(2, 6).toUpperCase()}`;
    } while (this.rooms.has(code));

    const createdAt = now();
    this.rooms.set(code, {
      id: uuid(),
      code,
      name,
      budget,
      hostUserId,
      status: 'open',
      version: 1,
      createdAt,
      publicUrl,
      participantIds: new Set([hostUserId]),
      messages: [],
      userVotes: new Map(),
      cart: [],
      activity: [
        {
          id: uuid(),
          userId: hostUserId,
          text: `${this.users.get(hostUserId)?.name || 'Host'} created the room`,
          createdAt
        }
      ]
    });
    return this.getRoomSnapshot(code);
  }

  async getRoomSnapshot(code) {
    const room = this.rooms.get(code.toUpperCase());
    if (!room) return null;

    const votes = {};
    for (const restaurantId of room.userVotes.values()) {
      votes[restaurantId] = (votes[restaurantId] || 0) + 1;
    }

    const participants = [...room.participantIds]
      .map((id) => this.users.get(id))
      .filter(Boolean)
      .map((user) => ({ ...user }));
    const latestOrder = [...this.orders.values()]
      .filter((order) => order.roomId === room.id)
      .sort((a, b) => b.createdAt.localeCompare(a.createdAt))[0];

    return {
      room: {
        id: room.id,
        code: room.code,
        name: room.name,
        budget: room.budget,
        hostUserId: room.hostUserId,
        status: room.status,
        version: room.version,
        createdAt: room.createdAt,
        inviteLink: `${room.publicUrl || 'https://homie.humanslop.in'}/r/${room.code}`,
        participants
      },
      messages: room.messages.map((message) => ({ ...message })),
      votes,
      userVotes: Object.fromEntries(room.userVotes),
      cart: room.cart.map((line) => ({
        ...line,
        item: { ...line.item },
        owner: { ...this.users.get(line.userId) }
      })),
      activity: room.activity.map((event) => ({ ...event })),
      order: latestOrder ? structuredClone(latestOrder) : null
    };
  }

  async joinRoom(code, userId) {
    const room = this.#room(code);
    if (room.status !== 'open') {
      throw new AppError(409, 'room_locked', 'This room has already checked out');
    }
    if (!room.participantIds.has(userId)) {
      room.participantIds.add(userId);
      room.version += 1;
      room.activity.unshift({
        id: uuid(),
        userId,
        text: `${this.users.get(userId)?.name || 'A guest'} joined the room`,
        createdAt: now()
      });
    }
    return this.getRoomSnapshot(room.code);
  }

  async addMessage(code, { userId, message }) {
    const room = this.#room(code);
    const payload = { id: uuid(), userId, message, reaction: null, createdAt: now() };
    room.messages.unshift(payload);
    room.version += 1;
    return payload;
  }

  async castVote(code, { userId, restaurantId, restaurantName }) {
    const room = this.#room(code);
    room.userVotes.set(userId, restaurantId);
    room.version += 1;
    room.activity.unshift({
      id: uuid(),
      userId,
      text: `${this.users.get(userId)?.name || 'A guest'} voted for ${restaurantName}`,
      createdAt: now()
    });
    return this.getRoomSnapshot(room.code);
  }

  async setCartItem(code, { userId, item, quantity, customization }) {
    const room = this.#room(code);
    const keyMatches = (line) =>
      line.userId === userId &&
      line.item.id === item.id &&
      line.customization === customization;
    const existingIndex = room.cart.findIndex(keyMatches);

    if (quantity === 0) {
      if (existingIndex >= 0) room.cart.splice(existingIndex, 1);
    } else if (existingIndex >= 0) {
      room.cart[existingIndex] = {
        ...room.cart[existingIndex],
        item: { ...item },
        quantity,
        updatedAt: now()
      };
    } else {
      room.cart.unshift({
        id: uuid(),
        userId,
        item: { ...item },
        quantity,
        customization,
        createdAt: now(),
        updatedAt: now()
      });
    }

    room.version += 1;
    room.activity.unshift({
      id: uuid(),
      userId,
      text: quantity === 0
        ? `${this.users.get(userId)?.name || 'A guest'} removed ${item.name}`
        : `${this.users.get(userId)?.name || 'A guest'} set ${item.name} to ${quantity}`,
      createdAt: now()
    });
    return this.getRoomSnapshot(room.code);
  }

  async createOrder(code, order) {
    const room = this.#room(code);
    room.status = 'locked';
    room.version += 1;
    this.orders.set(order.id, structuredClone(order));
    room.activity.unshift({
      id: uuid(),
      userId: order.userId,
      text: `Order ${order.swiggyOrderId} confirmed`,
      createdAt: order.createdAt
    });
    return this.getRoomSnapshot(room.code);
  }

  async getOrder(orderId) {
    const order = this.orders.get(orderId);
    return order ? structuredClone(order) : null;
  }

  async findOperation(operationId) {
    return this.operations.get(operationId) || null;
  }

  async recordOperation(operationId, result) {
    this.operations.set(operationId, structuredClone(result));
  }

  #room(code) {
    const room = this.rooms.get(code.toUpperCase());
    if (!room) throw new AppError(404, 'room_not_found', 'Room not found');
    return room;
  }
}
