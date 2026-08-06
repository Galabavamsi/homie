import { createAdapter } from '@socket.io/redis-adapter';
import { createClient } from 'redis';
import { env } from './env.js';

export const redisClient = env.redisUrl
  ? createClient({ url: env.redisUrl })
  : null;

let redisSubscriber = null;
let errorListenerRegistered = false;

export async function connectRedis() {
  if (!redisClient || redisClient.isOpen) return;
  if (!errorListenerRegistered) {
    redisClient.on('error', (error) => {
      console.warn('[redis] connection error', error.message);
    });
    errorListenerRegistered = true;
  }
  await redisClient.connect();
}

export async function configureSocketRedis(io) {
  if (!redisClient) return { enabled: false };
  await connectRedis();
  redisSubscriber = redisClient.duplicate();
  redisSubscriber.on('error', (error) => {
    console.warn('[redis] subscriber error', error.message);
  });
  await redisSubscriber.connect();
  io.adapter(createAdapter(redisClient, redisSubscriber));
  return { enabled: true };
}

export async function closeRedis() {
  if (redisSubscriber?.isOpen) await redisSubscriber.quit();
  if (redisClient?.isOpen) await redisClient.quit();
  redisSubscriber = null;
}
