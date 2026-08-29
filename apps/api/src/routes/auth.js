import { Router } from 'express';
import { z } from 'zod';

const callbackQuery = z.object({
  code: z.string().min(1).optional(),
  state: z.string().min(1).optional(),
  error: z.string().min(1).optional()
});

export function createAuthRouter(services) {
  const router = Router();

  router.get('/auth/callback', async (req, res) => {
    const query = callbackQuery.safeParse(req.query);
    if (!query.success || !query.data.state) {
      return res.status(400).type('html').send(renderResult(false));
    }
    if (query.data.error) {
      return res.status(400).type('html').send(renderResult(false));
    }

    try {
      await services.swiggyOAuthService.complete({
        code: query.data.code,
        state: query.data.state
      });
      return res.type('html').send(renderResult(true));
    } catch (error) {
      console.error('[oauth] callback failed', error.code || error.message);
      return res.status(error.status || 500).type('html').send(renderResult(false));
    }
  });

  return router;
}

function renderResult(success) {
  const title = success ? 'Swiggy connected' : 'Swiggy connection incomplete';
  const message = success
    ? 'Return to Homie. Your Swiggy session is ready for live restaurant discovery.'
    : 'Return to Homie and start the connection again.';
  return `<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${title}</title><style>body{font-family:system-ui,sans-serif;background:#fff7f2;color:#24170f;display:grid;place-items:center;min-height:100vh;margin:0;padding:24px}main{max-width:420px;text-align:center;background:#fff;border:1px solid #f0d6c7;border-radius:20px;padding:32px;box-shadow:0 18px 48px #7e3e1d1c}h1{margin:0 0 12px;font-size:24px}p{line-height:1.5;color:#674e42}</style></head><body><main><h1>${title}</h1><p>${message}</p></main></body></html>`;
}
