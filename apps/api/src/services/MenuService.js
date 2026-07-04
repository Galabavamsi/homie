export class MenuService {
  constructor(mcpService) {
    this.mcpService = mcpService;
  }

  getRestaurantMenu(restaurantId) {
    return this.mcpService.getMenu(restaurantId);
  }
}
