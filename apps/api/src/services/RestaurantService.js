export class RestaurantService {
  constructor(mcpService) {
    this.mcpService = mcpService;
  }

  list(filters = {}) {
    return this.mcpService.getRestaurants(filters);
  }
}
