import { env } from '../config/env.js';
import { CartService } from './CartService.js';
import { DemoAgentService } from './DemoAgentService.js';
import { McpService } from './McpService.js';
import { MenuService } from './MenuService.js';
import { OrderService } from './OrderService.js';
import { RestaurantService } from './RestaurantService.js';
import { RoomService } from './RoomService.js';
import { UserService } from './UserService.js';

export const mcpService = new McpService({
  baseUrl: env.swiggyMcpBaseUrl,
  foodUrl: env.swiggyMcpFoodUrl,
  mode: env.swiggyMcpMode,
  oauthCallback: env.swiggyOAuthCallback
});

export const services = {
  mcpService,
  demoAgentService: new DemoAgentService(mcpService),
  restaurantService: new RestaurantService(mcpService),
  menuService: new MenuService(mcpService),
  cartService: new CartService(mcpService),
  orderService: new OrderService(mcpService),
  userService: new UserService(),
  roomService: new RoomService()
};
