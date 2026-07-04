import { env } from '../config/env.js';
import { CartService } from './CartService.js';
import { McpService } from './McpService.js';
import { MenuService } from './MenuService.js';
import { OrderService } from './OrderService.js';
import { RestaurantService } from './RestaurantService.js';
import { RoomService } from './RoomService.js';
import { UserService } from './UserService.js';

export const mcpService = new McpService({
  baseUrl: env.swiggyMcpBaseUrl,
  oauthCallback: env.swiggyOAuthCallback
});

export const services = {
  mcpService,
  restaurantService: new RestaurantService(mcpService),
  menuService: new MenuService(mcpService),
  cartService: new CartService(mcpService),
  orderService: new OrderService(mcpService),
  userService: new UserService(),
  roomService: new RoomService()
};
