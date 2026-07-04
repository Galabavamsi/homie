import { rooms } from '../data/mockData.js';

export class CartService {
  constructor(mcpService) {
    this.mcpService = mcpService;
  }

  async sync(roomCode, cart) {
    const room = rooms.get(roomCode);
    if (!room) return null;
    room.cart = cart;
    const mcpCart = await this.mcpService.createCart({ roomId: room.id, cart });
    return { roomCode, cart: room.cart, mcpCart };
  }
}
