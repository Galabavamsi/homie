import assert from 'node:assert/strict';
import { test } from 'node:test';

import { McpService } from '../src/services/McpService.js';
import { SwiggyOAuthService } from '../src/services/SwiggyOAuthService.js';

const jsonResponse = (payload, status = 200) => new Response(JSON.stringify(payload), {
  status,
  headers: { 'Content-Type': 'application/json' }
});

test('Swiggy OAuth uses DCR, PKCE, state, and never returns the access token', async () => {
  const requests = [];
  const service = new SwiggyOAuthService({
    baseUrl: 'https://mcp.swiggy.test',
    redirectUri: 'https://api.homie.test/auth/callback',
    fetchImpl: async (url, options) => {
      requests.push({ url, options });
      if (url.endsWith('/auth/register')) {
        return jsonResponse({ client_id: 'homie-client-123' });
      }
      return jsonResponse({
        access_token: 'abcdefghijklmnopqrstuvwxyz123456',
        token_type: 'Bearer',
        expires_in: 432000,
        scope: 'mcp:tools'
      });
    }
  });

  const started = await service.begin({ userId: 'guest-1' });
  const authorization = new URL(started.authorizationUrl);
  assert.equal(authorization.pathname, '/auth/authorize');
  assert.equal(authorization.searchParams.get('client_id'), 'homie-client-123');
  assert.equal(authorization.searchParams.get('code_challenge_method'), 'S256');
  assert.equal(authorization.searchParams.get('scope'), 'mcp:tools');
  assert.ok(authorization.searchParams.get('code_challenge'));
  assert.ok(authorization.searchParams.get('state'));

  const result = await service.complete({
    code: 'single-use-code',
    state: authorization.searchParams.get('state')
  });
  assert.equal(result.userId, 'guest-1');
  assert.equal(result.scope, 'mcp:tools');
  assert.equal('accessToken' in result, false);
  assert.equal((await service.authorizationFor('guest-1')).startsWith('Bearer '), true);
  assert.equal(requests.length, 2);

  const tokenBody = JSON.parse(requests[1].options.body);
  assert.equal(tokenBody.grant_type, 'authorization_code');
  assert.equal(tokenBody.client_id, 'homie-client-123');
  assert.equal(tokenBody.redirect_uri, 'https://api.homie.test/auth/callback');
  assert.ok(tokenBody.code_verifier);
});

test('live Food MCP payloads normalize to Homie restaurant and menu models', async () => {
  const calls = [];
  const mcp = new McpService({
    baseUrl: 'https://mcp.swiggy.test',
    foodUrl: 'https://mcp.swiggy.test/food',
    mode: 'live',
    oauthService: { authorizationFor: async () => 'Bearer live-token-for-test-123456' },
    fetchImpl: async (_url, options) => {
      calls.push(JSON.parse(options.body));
      const name = calls.at(-1).params.name;
      const data = name === 'search_restaurants'
        ? {
            restaurants: [
              {
                id: 'swiggy-rest-42',
                name: 'Open Kitchen',
                cuisines: ['North Indian', 'Biryani'],
                avgRating: 4.4,
                costForTwo: 'INR 600 for two',
                deliveryTimeMinutes: 31,
                availabilityStatus: 'OPEN',
                veg: true
              },
              { id: 'closed-9', name: 'Closed Kitchen', availabilityStatus: 'CLOSED' }
            ],
            dishes: [],
            nextOffset: null
          }
        : {
            restaurant: { id: 'swiggy-rest-42' },
            categories: [
              {
                title: 'Biryani',
                items: [
                  {
                    id: 'dish-7',
                    name: 'Family Biryani',
                    price: 499,
                    isVeg: false,
                    hasVariants: true
                  }
                ]
              }
            ]
          };
      return jsonResponse({ result: { success: true, data } });
    }
  });

  const found = await mcp.getRestaurants({ userId: 'guest-1', addressId: 'addr-1', query: 'biryani' });
  const menu = await mcp.getMenu('swiggy-rest-42', { userId: 'guest-1', addressId: 'addr-1' });
  assert.deepEqual(found, [{
    id: 'swiggy-rest-42',
    name: 'Open Kitchen',
    cuisine: 'North Indian, Biryani',
    rating: 4.4,
    etaMinutes: 31,
    priceForTwo: 600,
    image: '',
    tags: ['veg', 'north indian', 'biryani'],
    offer: ''
  }]);
  assert.deepEqual(menu, [{
    id: 'dish-7',
    restaurantId: 'swiggy-rest-42',
    name: 'Family Biryani',
    description: '',
    price: 499,
    image: '',
    tags: ['nonVeg'],
    isCustomizable: true
  }]);
  assert.equal(calls[0].params.arguments.addressId, 'addr-1');
  assert.equal(calls[1].params.arguments.restaurantId, 'swiggy-rest-42');
});
