import assert from 'node:assert/strict';
import { after, before, test } from 'node:test';
import { io as createSocket } from 'socket.io-client';

import { MemoryCollaborationRepository } from '../src/data/MemoryCollaborationRepository.js';
import { buildHomieServer } from '../src/server.js';

let homie;
let baseUrl;
let socket;

const request = async (path, { method = 'GET', body } = {}) => {
  const response = await fetch(`${baseUrl}/api${path}`, {
    method,
    headers: body ? { 'Content-Type': 'application/json' } : undefined,
    body: body ? JSON.stringify(body) : undefined
  });
  const payload = await response.json();
  return { status: response.status, payload };
};

const emitAck = (event, payload) => new Promise((resolve) => {
  socket.timeout(2000).emit(event, payload, (error, response) => {
    resolve(error ? { ok: false, error: { message: error.message } } : response);
  });
});

before(async () => {
  homie = await buildHomieServer({
    repository: new MemoryCollaborationRepository({ seed: false })
  });
  const address = await homie.start(0);
  baseUrl = `http://127.0.0.1:${address.port}`;
});

after(async () => {
  socket?.disconnect();
  await homie.close();
});

test('two guests collaborate through HTTP and Socket.IO with guarded checkout', async () => {
  const invalidGuest = await request('/users/guest', { method: 'POST', body: { name: ' ' } });
  assert.equal(invalidGuest.status, 400);

  const hostResult = await request('/users/guest', {
    method: 'POST',
    body: { name: 'Host Vamsi' }
  });
  const guestResult = await request('/users/guest', {
    method: 'POST',
    body: { name: 'Maya Guest' }
  });
  assert.equal(hostResult.status, 201);
  assert.equal(guestResult.status, 201);
  const host = hostResult.payload;
  const guest = guestResult.payload;

  const roomResult = await request('/rooms', {
    method: 'POST',
    body: { name: 'Local Test Room', budget: 1500, hostUserId: host.id }
  });
  assert.equal(roomResult.status, 201);
  const code = roomResult.payload.room.code;

  const joinResult = await request(`/rooms/${code}/join`, {
    method: 'POST',
    body: { userId: guest.id, operationId: 'join-guest-0001' }
  });
  assert.equal(joinResult.payload.room.participants.length, 2);

  socket = createSocket(baseUrl, { transports: ['websocket'], forceNew: true });
  await new Promise((resolve, reject) => {
    socket.once('connect', resolve);
    socket.once('connect_error', reject);
  });

  const socketJoin = await emitAck('room:join', {
    roomCode: code,
    userId: guest.id,
    operationId: 'socket-join-0001'
  });
  assert.equal(socketJoin.ok, true);

  const messagePayload = {
    roomCode: code,
    userId: guest.id,
    message: 'One paneer bowl for me',
    operationId: 'message-guest-0001'
  };
  const firstMessage = await emitAck('chat:send', messagePayload);
  const retriedMessage = await emitAck('chat:send', messagePayload);
  assert.equal(firstMessage.ok, true);
  assert.equal(retriedMessage.data.messages.length, 1);

  const cartResult = await request(`/rooms/${code}/cart/items/r0_m0`, {
    method: 'PUT',
    body: {
      userId: guest.id,
      restaurantId: 'r0',
      quantity: 1,
      customization: 'Regular',
      operationId: 'cart-guest-0001'
    }
  });
  assert.equal(cartResult.status, 200);
  assert.equal(cartResult.payload.cart[0].item.price, 249);

  const mixedCart = await request(`/rooms/${code}/cart/items/r1_m0`, {
    method: 'PUT',
    body: {
      userId: host.id,
      restaurantId: 'r1',
      quantity: 1,
      operationId: 'cart-host-mixed-0001'
    }
  });
  assert.equal(mixedCart.status, 409);
  assert.equal(mixedCart.payload.error.code, 'mixed_restaurant_cart');

  const guestCheckout = await request(`/rooms/${code}/checkout`, {
    method: 'POST',
    body: { userId: guest.id, confirmed: true, operationId: 'checkout-guest-0001' }
  });
  assert.equal(guestCheckout.status, 403);
  assert.equal(guestCheckout.payload.error.code, 'host_only');

  const hostCheckout = await request(`/rooms/${code}/checkout`, {
    method: 'POST',
    body: { userId: host.id, confirmed: true, operationId: 'checkout-host-0001' }
  });
  assert.equal(hostCheckout.status, 201);
  assert.equal(hostCheckout.payload.room.status, 'locked');
  assert.equal(hostCheckout.payload.order.total, 350);

  const retryCheckout = await request(`/rooms/${code}/checkout`, {
    method: 'POST',
    body: { userId: host.id, confirmed: true, operationId: 'checkout-host-0001' }
  });
  assert.equal(retryCheckout.status, 201);
  assert.equal(retryCheckout.payload.order.id, hostCheckout.payload.order.id);
});
