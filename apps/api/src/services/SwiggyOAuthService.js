import crypto from 'node:crypto';

import { AppError } from '../errors/AppError.js';

const DEFAULT_SCOPE = 'mcp:tools';
const PENDING_TTL_MS = 5 * 60 * 1000;
const REQUEST_TIMEOUT_MS = 10 * 1000;

const asObject = (value) => value && typeof value === 'object' ? value : {};

export class SwiggyOAuthService {
  constructor({
    baseUrl,
    redirectUri,
    clientId,
    clientName = 'Homie',
    scope = DEFAULT_SCOPE,
    fetchImpl = fetch
  }) {
    this.baseUrl = baseUrl.replace(/\/$/, '');
    this.redirectUri = redirectUri;
    this.clientId = clientId || null;
    this.clientName = clientName;
    this.scope = scope;
    this.fetchImpl = fetchImpl;
    this.pending = new Map();
    this.tokens = new Map();
  }

  async begin({ userId }) {
    const clientId = await this.#ensureClient();
    const codeVerifier = crypto.randomBytes(32).toString('base64url');
    const codeChallenge = crypto
      .createHash('sha256')
      .update(codeVerifier)
      .digest('base64url');
    const state = crypto.randomBytes(32).toString('base64url');

    this.#purgePending();
    this.pending.set(state, {
      userId,
      clientId,
      codeVerifier,
      createdAt: Date.now()
    });

    const authorization = new URL(`${this.baseUrl}/auth/authorize`);
    authorization.search = new URLSearchParams({
      response_type: 'code',
      client_id: clientId,
      redirect_uri: this.redirectUri,
      code_challenge: codeChallenge,
      code_challenge_method: 'S256',
      state,
      scope: this.scope
    }).toString();

    return {
      authorizationUrl: authorization.toString(),
      expiresInSeconds: Math.floor(PENDING_TTL_MS / 1000)
    };
  }

  async complete({ code, state }) {
    this.#purgePending();
    const pending = this.pending.get(state);
    this.pending.delete(state);
    if (!pending) {
      throw new AppError(400, 'oauth_state_invalid', 'The Swiggy authorization session expired or is invalid');
    }
    if (!code) {
      throw new AppError(400, 'oauth_code_missing', 'Swiggy did not return an authorization code');
    }

    const payload = await this.#requestJson('/auth/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        grant_type: 'authorization_code',
        code,
        code_verifier: pending.codeVerifier,
        redirect_uri: this.redirectUri,
        client_id: pending.clientId
      })
    });
    const tokenPayload = asObject(payload.data || payload);
    const accessToken = tokenPayload.access_token;
    if (typeof accessToken !== 'string' || accessToken.length < 20) {
      throw new AppError(502, 'oauth_token_missing', 'Swiggy returned an invalid authorization response');
    }

    const expiresIn = Number(tokenPayload.expires_in || 432000);
    const expiresAt = Date.now() + Math.max(60, expiresIn) * 1000;
    this.tokens.set(pending.userId, {
      accessToken,
      expiresAt
    });

    return {
      userId: pending.userId,
      expiresAt: new Date(expiresAt).toISOString(),
      scope: tokenPayload.scope || this.scope
    };
  }

  status(userId) {
    const token = this.tokens.get(userId);
    if (!token || token.expiresAt <= Date.now()) {
      this.tokens.delete(userId);
      return { connected: false };
    }
    return {
      connected: true,
      expiresAt: new Date(token.expiresAt).toISOString()
    };
  }

  async authorizationFor(userId) {
    const token = this.tokens.get(userId);
    if (!token) return null;
    if (token.expiresAt <= Date.now() + 60 * 1000) {
      this.tokens.delete(userId);
      return null;
    }
    return `Bearer ${token.accessToken}`;
  }

  async logout(userId) {
    const token = this.tokens.get(userId);
    this.tokens.delete(userId);
    if (!token) return;

    try {
      await this.#requestJson('/auth/logout', {
        method: 'POST',
        headers: { Authorization: `Bearer ${token.accessToken}` }
      });
    } catch (error) {
      if (!(error instanceof AppError) || error.status !== 401) throw error;
    }
  }

  async #ensureClient() {
    if (this.clientId) return this.clientId;
    const payload = await this.#requestJson('/auth/register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        client_name: this.clientName,
        redirect_uris: [this.redirectUri],
        grant_types: ['authorization_code'],
        response_types: ['code'],
        token_endpoint_auth_method: 'none'
      })
    });
    const registration = asObject(payload.data || payload);
    if (typeof registration.client_id !== 'string' || registration.client_id.length === 0) {
      throw new AppError(502, 'oauth_client_registration_failed', 'Swiggy did not return a client identifier');
    }
    this.clientId = registration.client_id;
    return this.clientId;
  }

  async #requestJson(path, options) {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);
    try {
      const response = await this.fetchImpl(`${this.baseUrl}${path}`, {
        ...options,
        signal: controller.signal
      });
      let payload = {};
      try {
        payload = await response.json();
      } catch {
        payload = {};
      }
      if (!response.ok || payload.error) {
        throw new AppError(
          response.status >= 400 ? response.status : 502,
          'swiggy_oauth_request_failed',
          response.status === 401
            ? 'Swiggy authorization expired. Connect Swiggy again.'
            : 'Swiggy authorization is temporarily unavailable'
        );
      }
      return payload;
    } catch (error) {
      if (error instanceof AppError) throw error;
      if (error.name === 'AbortError') {
        throw new AppError(504, 'swiggy_oauth_timeout', 'Swiggy authorization took too long to respond');
      }
      throw new AppError(502, 'swiggy_oauth_unreachable', 'Could not reach Swiggy authorization');
    } finally {
      clearTimeout(timeout);
    }
  }

  #purgePending() {
    const cutoff = Date.now() - PENDING_TTL_MS;
    for (const [state, entry] of this.pending) {
      if (entry.createdAt < cutoff) this.pending.delete(state);
    }
  }
}
