import { Router } from 'express';
import { z } from 'zod';

import { env } from '../config/env.js';

const operationId = z.string().min(8).max(120).optional();
const roomCode = z.string().trim().min(4).max(12).transform((value) => value.toUpperCase());

export function createRouter(services) {
  const router = Router();
  const collaboration = services.collaborationService;

  router.get('/health', (_req, res) => {
    res.json({
      ok: true,
      service: 'homie-api',
      persistence: services.repository.kind,
      mcpMode: env.swiggyMcpMode,
      time: new Date().toISOString()
    });
  });

  router.get('/ready', async (_req, res, next) => {
    try {
      const persistence = await services.repository.readiness();
      res.json({ ok: true, persistence });
    } catch (error) {
      next(error);
    }
  });

  router.get('/auth/swiggy', (_req, res) => {
    res.json({
      provider: 'swiggy',
      type: 'oauth_2_1_pkce',
      redirectUri: env.swiggyOAuthCallback,
      documentation: 'https://mcp.swiggy.com/builders/docs/start/authenticate/'
    });
  });

  router.get('/auth/swiggy/start', async (req, res, next) => {
    try {
      const userId = z.string().min(1).max(100).parse(req.query.userId);
      res.json({
        provider: 'swiggy',
        ...(await services.swiggyOAuthService.begin({ userId }))
      });
    } catch (error) {
      next(error);
    }
  });

  router.get('/mcp/addresses', async (req, res, next) => {
    try {
      const userId = z.string().min(1).max(100).parse(req.query.userId);
      const result = await services.mcpService.getAddresses({ userId });
      res.json({
        data: result.addresses || result.data?.addresses || [],
        source: `swiggy_mcp_${env.swiggyMcpMode}`
      });
    } catch (error) {
      next(error);
    }
  });

  router.post('/mcp/addresses/select', async (req, res, next) => {
    try {
      const body = z.object({
        userId: z.string().min(1).max(100),
        addressId: z.string().trim().min(1).max(200)
      }).parse(req.body);
      res.json(await services.mcpService.selectAddress(body));
    } catch (error) {
      next(error);
    }
  });

  router.get('/auth/swiggy/status', (req, res, next) => {
    try {
      const userId = z.string().min(1).max(100).parse(req.query.userId);
      res.json(services.swiggyOAuthService.status(userId));
    } catch (error) {
      next(error);
    }
  });

  router.post('/auth/swiggy/logout', async (req, res, next) => {
    try {
      const userId = z.string().min(1).max(100).parse(req.body?.userId);
      await services.swiggyOAuthService.logout(userId);
      res.status(204).end();
    } catch (error) {
      next(error);
    }
  });

  router.get('/mcp/restaurants', async (req, res, next) => {
    try {
      const userId = req.query.userId ? z.string().min(1).max(100).parse(req.query.userId) : undefined;
      const addressId = req.query.addressId ? z.string().min(1).max(200).parse(req.query.addressId) : undefined;
      const restaurants = await services.restaurantService.list({
        query: req.query.q,
        tag: req.query.tag,
        userId,
        addressId
      });
      res.json({ data: restaurants, source: `swiggy_mcp_${env.swiggyMcpMode}` });
    } catch (error) {
      next(error);
    }
  });

  router.get('/mcp/menu/:restaurantId', async (req, res, next) => {
    try {
      const userId = req.query.userId ? z.string().min(1).max(100).parse(req.query.userId) : undefined;
      const addressId = req.query.addressId ? z.string().min(1).max(200).parse(req.query.addressId) : undefined;
      const menu = await services.menuService.getRestaurantMenu(req.params.restaurantId, { userId, addressId });
      if (menu.length === 0) return res.status(404).json({ error: { code: 'menu_not_found', message: 'Menu not found' } });
      res.json({ data: menu, source: `swiggy_mcp_${env.swiggyMcpMode}` });
    } catch (error) {
      next(error);
    }
  });

  router.post('/mcp/food', async (req, res, next) => {
    try {
      const schema = z.object({
        jsonrpc: z.literal('2.0').default('2.0'),
        method: z.literal('tools/call'),
        params: z.object({
          name: z.string(),
          arguments: z.record(z.any()).default({})
        }),
        id: z.union([z.string(), z.number()]).optional()
      });
      const body = schema.parse(req.body);
      const data = await services.mcpService.callFoodTool(
        body.params.name,
        body.params.arguments,
        {
          authorization: req.headers.authorization,
          userId: req.headers['x-homie-user-id']
        }
      );
      res.json({
        jsonrpc: '2.0',
        id: body.id ?? null,
        result: { success: true, data }
      });
    } catch (error) {
      next(error);
    }
  });

  router.post('/demo/food-agent', async (req, res, next) => {
    try {
      const schema = z.object({
        query: z.string().trim().min(1).max(100).default('pizza'),
        confirmOrder: z.boolean().default(false)
      });
      res.json(await services.demoAgentService.runFoodOrderDemo(schema.parse(req.body)));
    } catch (error) {
      next(error);
    }
  });

  router.post('/users/guest', async (req, res, next) => {
    try {
      const body = z.object({ name: z.string().trim().min(2).max(40) }).parse(req.body);
      res.status(201).json(await collaboration.createGuest(body.name));
    } catch (error) {
      next(error);
    }
  });

  router.get('/users/me', (_req, res) => {
    res.json(services.userService.currentUser());
  });

  router.post('/rooms', async (req, res, next) => {
    try {
      const body = z.object({
        name: z.string().trim().min(2).max(60),
        budget: z.number().int().min(500).max(50000),
        hostUserId: z.string().min(1).max(100)
      }).parse(req.body);
      res.status(201).json(await collaboration.createRoom(body));
    } catch (error) {
      next(error);
    }
  });

  router.get('/rooms/:code', async (req, res, next) => {
    try {
      const code = roomCode.parse(req.params.code);
      res.json(await collaboration.getRoom(code));
    } catch (error) {
      next(error);
    }
  });

  router.post('/rooms/:code/join', async (req, res, next) => {
    try {
      const code = roomCode.parse(req.params.code);
      const body = z.object({
        userId: z.string().min(1).max(100),
        operationId
      }).parse(req.body);
      res.json(await collaboration.joinRoom(code, body.userId, body.operationId));
    } catch (error) {
      next(error);
    }
  });

  router.post('/rooms/:code/messages', async (req, res, next) => {
    try {
      const code = roomCode.parse(req.params.code);
      const body = z.object({
        userId: z.string().min(1).max(100),
        message: z.string().max(500),
        operationId
      }).parse(req.body);
      res.status(201).json(await collaboration.sendMessage(code, body));
    } catch (error) {
      next(error);
    }
  });

  router.put('/rooms/:code/vote', async (req, res, next) => {
    try {
      const code = roomCode.parse(req.params.code);
      const body = z.object({
        userId: z.string().min(1).max(100),
        restaurantId: z.string().min(1).max(100),
        operationId
      }).parse(req.body);
      res.json(await collaboration.vote(code, body));
    } catch (error) {
      next(error);
    }
  });

  router.put('/rooms/:code/cart/items/:itemId', async (req, res, next) => {
    try {
      const code = roomCode.parse(req.params.code);
      const body = z.object({
        userId: z.string().min(1).max(100),
        restaurantId: z.string().min(1).max(100),
        quantity: z.number().int().min(0).max(20),
        customization: z.string().trim().max(120).default('Regular'),
        operationId
      }).parse(req.body);
      res.json(await collaboration.setCartItem(code, { ...body, itemId: req.params.itemId }));
    } catch (error) {
      next(error);
    }
  });

  router.post('/rooms/:code/checkout', async (req, res, next) => {
    try {
      const code = roomCode.parse(req.params.code);
      const body = z.object({
        userId: z.string().min(1).max(100),
        confirmed: z.literal(true),
        operationId: z.string().min(8).max(120)
      }).parse(req.body);
      res.status(201).json(await collaboration.checkout(code, body));
    } catch (error) {
      next(error);
    }
  });

  router.get('/collaboration/orders/:orderId', async (req, res, next) => {
    try {
      res.json(await collaboration.getOrder(req.params.orderId));
    } catch (error) {
      next(error);
    }
  });

  return router;
}
