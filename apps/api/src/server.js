import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import http from 'http';
import { Server } from 'socket.io';

import { env } from './config/env.js';
import { connectRedis } from './config/redis.js';
import { createRouter } from './routes/index.js';
import { services } from './services/index.js';
import { registerRoomSockets } from './sockets/roomSocket.js';

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: env.clientOrigin,
    methods: ['GET', 'POST']
  }
});

app.use(helmet());
app.use(cors({ origin: env.clientOrigin }));
app.use(express.json({ limit: '1mb' }));
app.use('/api', createRouter(services));

app.use((error, _req, res, _next) => {
  if (error?.name === 'ZodError') {
    return res.status(400).json({ error: 'Invalid request', details: error.errors });
  }
  console.error(error);
  return res.status(500).json({ error: 'Unexpected server error' });
});

registerRoomSockets(io, services);

if (env.redisUrl) {
  connectRedis().catch((error) => {
    console.warn('[redis] continuing without redis in MVP mode:', error.message);
  });
}

server.listen(env.port, () => {
  console.log(`Homie API listening on http://localhost:${env.port}`);
  console.log(`Swiggy OAuth callback placeholder: ${env.swiggyOAuthCallback}`);
});
