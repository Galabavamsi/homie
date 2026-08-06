import { env } from '../config/env.js';
import { CartService } from './CartService.js';
import { CollaborationService } from './CollaborationService.js';
import { DemoAgentService } from './DemoAgentService.js';
import { McpService } from './McpService.js';
import { MenuService } from './MenuService.js';
import { OrderService } from './OrderService.js';
import { RestaurantService } from './RestaurantService.js';
import { RoomService } from './RoomService.js';
import { UserService } from './UserService.js';

export function createServices(repository) {
  const mcpService = new McpService({
    baseUrl: env.swiggyMcpBaseUrl,
    foodUrl: env.swiggyMcpFoodUrl,
    mode: env.swiggyMcpMode,
    oauthCallback: env.swiggyOAuthCallback
  });
  const restaurantService = new RestaurantService(mcpService);
  const menuService = new MenuService(mcpService);
  const orderService = new OrderService(mcpService);

  return {
    repository,
    mcpService,
    demoAgentService: new DemoAgentService(mcpService),
    restaurantService,
    menuService,
    cartService: new CartService(mcpService),
    orderService,
    userService: new UserService(),
    roomService: new RoomService(),
    collaborationService: new CollaborationService({
      repository,
      restaurantService,
      menuService,
      orderService,
      publicUrl: env.homiePublicUrl
    })
  };
}
