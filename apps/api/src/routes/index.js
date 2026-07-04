import { Router } from 'express';
import { z } from 'zod';

export function createRouter(services) {
  const router = Router();

  router.get('/health', (_req, res) => {
    res.json({ ok: true, service: 'homie-api', mcp: 'mocked' });
  });

  router.get('/auth/swiggy', (_req, res) => {
    res.json({
      provider: 'swiggy',
      type: 'oauth_placeholder',
      redirectUri: 'https://api.humanslop.in/auth/callback',
      authorizationUrl: 'https://mcp.swiggy.example/oauth/authorize'
    });
  });

  router.get('/auth/callback', (req, res) => {
    res.json({ ok: true, message: 'Swiggy OAuth callback placeholder', query: req.query });
  });

  router.get('/mcp/restaurants', async (req, res, next) => {
    try {
      const restaurants = await services.restaurantService.list({
        query: req.query.q,
        tag: req.query.tag
      });
      res.json({ data: restaurants, source: 'swiggy_mcp_mock' });
    } catch (error) {
      next(error);
    }
  });

  router.get('/mcp/menu/:restaurantId', async (req, res, next) => {
    try {
      const menu = await services.menuService.getRestaurantMenu(req.params.restaurantId);
      res.json({ data: menu, source: 'swiggy_mcp_mock' });
    } catch (error) {
      next(error);
    }
  });

  router.post('/mcp/cart', async (req, res, next) => {
    try {
      const schema = z.object({
        roomCode: z.string().min(3),
        cart: z.array(z.record(z.any()))
      });
      const body = schema.parse(req.body);
      const result = await services.cartService.sync(body.roomCode, body.cart);
      if (!result) return res.status(404).json({ error: 'Room not found' });
      res.json(result);
    } catch (error) {
      next(error);
    }
  });

  router.post('/mcp/checkout', async (req, res, next) => {
    try {
      const schema = z.object({
        roomId: z.string(),
        cart: z.array(z.record(z.any()))
      });
      const body = schema.parse(req.body);
      const order = await services.orderService.checkout(body.roomId, body.cart);
      res.status(201).json(order);
    } catch (error) {
      next(error);
    }
  });

  router.get('/mcp/orders/:orderId', async (req, res, next) => {
    try {
      const order = await services.orderService.getOrder(req.params.orderId);
      res.json(order);
    } catch (error) {
      next(error);
    }
  });

  router.post('/rooms', (req, res, next) => {
    try {
      const schema = z.object({
        name: z.string().min(2),
        budget: z.number().int().positive().default(2500)
      });
      const room = services.roomService.create(schema.parse(req.body));
      res.status(201).json(room);
    } catch (error) {
      next(error);
    }
  });

  router.get('/rooms/:code', (req, res) => {
    const room = services.roomService.get(req.params.code);
    if (!room) return res.status(404).json({ error: 'Room not found' });
    res.json(room);
  });

  router.post('/rooms/:code/join', (req, res) => {
    const room = services.roomService.join(req.params.code, req.body.userId || 'u1');
    if (!room) return res.status(404).json({ error: 'Room or user not found' });
    res.json(room);
  });

  router.get('/users/me', (_req, res) => {
    res.json(services.userService.currentUser());
  });

  return router;
}
