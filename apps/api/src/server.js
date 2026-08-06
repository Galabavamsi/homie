import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import http from 'node:http';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { Server } from 'socket.io';

import { env } from './config/env.js';
import { closePostgres } from './config/postgres.js';
import { closeRedis, configureSocketRedis } from './config/redis.js';
import { createCollaborationRepository } from './data/repository.js';
import { createRouter } from './routes/index.js';
import { createServices } from './services/index.js';
import { registerRoomSockets } from './sockets/roomSocket.js';

export async function buildHomieServer({ repository: suppliedRepository } = {}) {
  const repository = suppliedRepository || await createCollaborationRepository();
  const services = createServices(repository);
  const app = express();
  const httpServer = http.createServer(app);
  const io = new Server(httpServer, {
    cors: { origin: env.clientOrigin, methods: ['GET', 'POST', 'PUT'] },
    transports: ['websocket', 'polling']
  });

  app.disable('x-powered-by');
  app.use(helmet({ crossOriginResourcePolicy: false }));
  app.use(cors({ origin: env.clientOrigin }));
  app.use(express.json({ limit: '256kb' }));
  app.use((req, res, next) => {
    res.setHeader('Cache-Control', 'no-store');
    next();
  });
  app.use('/api', createRouter(services));
  app.use((_req, res) => {
    res.status(404).json({ error: { code: 'route_not_found', message: 'Route not found' } });
  });
  app.use((error, _req, res, _next) => {
    if (error?.name === 'ZodError') {
      return res.status(400).json({
        error: {
          code: 'invalid_request',
          message: 'Some fields are invalid',
          details: error.errors.map((issue) => ({ path: issue.path.join('.'), message: issue.message }))
        }
      });
    }
    const status = Number.isInteger(error.status) ? error.status : 500;
    if (status >= 500) console.error(error);
    return res.status(status).json({
      error: {
        code: error.code || 'unexpected_error',
        message: status >= 500 ? 'Unexpected server error' : error.message,
        details: error.details
      }
    });
  });

  registerRoomSockets(io, services);

  let redis = { enabled: false };
  try {
    redis = await configureSocketRedis(io);
  } catch (error) {
    console.warn('[redis] continuing without cross-instance Socket.IO:', error.message);
  }

  const start = (port = env.port) => new Promise((resolve, reject) => {
    httpServer.once('error', reject);
    httpServer.listen(port, '0.0.0.0', () => {
      httpServer.off('error', reject);
      resolve(httpServer.address());
    });
  });

  const close = async () => {
    await new Promise((resolve) => io.close(resolve));
    if (httpServer.listening) {
      await new Promise((resolve, reject) => {
        httpServer.close((error) => error ? reject(error) : resolve());
      });
    }
    await closeRedis();
    if (repository.kind === 'postgres') await closePostgres();
  };

  return { app, httpServer, io, services, repository, redis, start, close };
}

async function run() {
  const homie = await buildHomieServer();
  const address = await homie.start();
  const port = typeof address === 'object' ? address.port : env.port;
  console.log(`Homie API listening on http://localhost:${port}`);
  console.log(`Persistence: ${homie.repository.kind}; Swiggy MCP: ${env.swiggyMcpMode}; Redis adapter: ${homie.redis.enabled}`);
  console.log(`Swiggy OAuth callback: ${env.swiggyOAuthCallback}`);

  const shutdown = async () => {
    await homie.close();
    process.exit(0);
  };
  process.once('SIGINT', shutdown);
  process.once('SIGTERM', shutdown);
}

const currentFile = fileURLToPath(import.meta.url);
const isMain = process.argv[1] && path.resolve(process.argv[1]) === path.resolve(currentFile);
if (isMain) {
  run().catch((error) => {
    console.error(error);
    process.exit(1);
  });
}
