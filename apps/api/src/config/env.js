import dotenv from 'dotenv';

dotenv.config();

export const env = {
  port: Number(process.env.PORT || 4000),
  nodeEnv: process.env.NODE_ENV || 'development',
  clientOrigin: process.env.CLIENT_ORIGIN || '*',
  databaseUrl: process.env.DATABASE_URL,
  redisUrl: process.env.REDIS_URL,
  swiggyMcpBaseUrl: process.env.SWIGGY_MCP_BASE_URL || 'https://mcp.swiggy.example',
  swiggyOAuthCallback: process.env.SWIGGY_OAUTH_CALLBACK || 'https://api.humanslop.in/auth/callback',
};
