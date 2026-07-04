export class OrderService {
  constructor(mcpService) {
    this.mcpService = mcpService;
  }

  checkout(roomId, cart) {
    return this.mcpService.checkout({ roomId, cart });
  }

  getOrder(orderId) {
    return this.mcpService.getOrder(orderId);
  }
}
