import { createClient } from 'redis';
import { env } from './env.js';

export const redisClient = env.redisUrl
  ? createClient({ url: env.redisUrl })
  : null;

export async function connectRedis() {
  if (!redisClient || redisClient.isOpen) return;
  redisClient.on('error', (error) => {
    console.warn('[redis] connection error', error.message);
  });
  await redisClient.connect();
}
