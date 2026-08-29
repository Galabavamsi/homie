export class MenuService {
  constructor(mcpService) {
    this.mcpService = mcpService;
  }

  getRestaurantMenu(restaurantId, context = {}) {
    return this.mcpService.getMenu(restaurantId, context);
  }
}
