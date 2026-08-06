import { v4 as uuid } from 'uuid';

import { AppError } from '../errors/AppError.js';

const iso = (value) => new Date(value).toISOString();

export class PostgresCollaborationRepository {
  constructor(pool) {
    this.kind = 'postgres';
    this.pool = pool;
  }

  async readiness() {
    await this.pool.query('SELECT 1');
    return { ok: true, kind: this.kind };
  }

  async createUser(user) {
    const { rows } = await this.pool.query(
      `INSERT INTO users (id, name, avatar, color)
       VALUES ($1, $2, $3, $4)
       RETURNING id, name, avatar, color`,
      [user.id, user.name, user.avatar, user.color]
    );
    return rows[0];
  }

  async getUser(userId) {
    const { rows } = await this.pool.query(
      'SELECT id, name, avatar, color FROM users WHERE id = $1',
      [userId]
    );
    return rows[0] || null;
  }

  async createRoom({ name, budget, hostUserId, publicUrl }) {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');
      let room;
      for (let attempt = 0; attempt < 6 && !room; attempt += 1) {
        const code = `HM${Math.random().toString(36).slice(2, 6).toUpperCase()}`;
        try {
          const result = await client.query(
            `INSERT INTO rooms (id, code, name, budget, host_user_id, public_url)
             VALUES ($1, $2, $3, $4, $5, $6)
             RETURNING id, code`,
            [uuid(), code, name, budget, hostUserId, publicUrl]
          );
          room = result.rows[0];
        } catch (error) {
          if (error.code !== '23505') throw error;
        }
      }
      if (!room) throw new AppError(503, 'room_code_exhausted', 'Could not allocate a room code');

      await client.query(
        'INSERT INTO room_participants (room_id, user_id) VALUES ($1, $2)',
        [room.id, hostUserId]
      );
      const host = await this.getUser(hostUserId);
      await client.query(
        'INSERT INTO activity_events (id, room_id, user_id, text) VALUES ($1, $2, $3, $4)',
        [uuid(), room.id, hostUserId, `${host?.name || 'Host'} created the room`]
      );
      await client.query('COMMIT');
      return this.getRoomSnapshot(room.code);
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async getRoomSnapshot(code) {
    const roomResult = await this.pool.query(
      `SELECT id, code, name, budget, host_user_id, status, version, public_url, created_at
       FROM rooms WHERE code = $1`,
      [code.toUpperCase()]
    );
    const row = roomResult.rows[0];
    if (!row) return null;

    const [participantsResult, messagesResult, votesResult, cartResult, activityResult, orderResult] =
      await Promise.all([
        this.pool.query(
          `SELECT u.id, u.name, u.avatar, u.color
           FROM room_participants rp JOIN users u ON u.id = rp.user_id
           WHERE rp.room_id = $1 ORDER BY rp.joined_at`,
          [row.id]
        ),
        this.pool.query(
          `SELECT id, user_id, message, reaction, created_at
           FROM messages WHERE room_id = $1 ORDER BY created_at DESC LIMIT 100`,
          [row.id]
        ),
        this.pool.query(
          'SELECT user_id, restaurant_id FROM restaurant_votes WHERE room_id = $1',
          [row.id]
        ),
        this.pool.query(
          `SELECT c.id, c.user_id, c.item, c.quantity, c.customization, c.created_at, c.updated_at,
                  u.id AS owner_id, u.name AS owner_name, u.avatar AS owner_avatar, u.color AS owner_color
           FROM cart_items c JOIN users u ON u.id = c.user_id
           WHERE c.room_id = $1 ORDER BY c.created_at DESC`,
          [row.id]
        ),
        this.pool.query(
          `SELECT id, user_id, text, created_at
           FROM activity_events WHERE room_id = $1 ORDER BY created_at DESC LIMIT 100`,
          [row.id]
        ),
        this.pool.query(
          `SELECT snapshot FROM orders WHERE room_id = $1 ORDER BY created_at DESC LIMIT 1`,
          [row.id]
        )
      ]);

    const votes = {};
    const userVotes = {};
    for (const vote of votesResult.rows) {
      votes[vote.restaurant_id] = (votes[vote.restaurant_id] || 0) + 1;
      userVotes[vote.user_id] = vote.restaurant_id;
    }

    return {
      room: {
        id: row.id,
        code: row.code,
        name: row.name,
        budget: row.budget,
        hostUserId: row.host_user_id,
        status: row.status,
        version: row.version,
        createdAt: iso(row.created_at),
        inviteLink: `${row.public_url}/r/${row.code}`,
        participants: participantsResult.rows
      },
      messages: messagesResult.rows.map((message) => ({
        id: message.id,
        userId: message.user_id,
        message: message.message,
        reaction: message.reaction,
        createdAt: iso(message.created_at)
      })),
      votes,
      userVotes,
      cart: cartResult.rows.map((line) => ({
        id: line.id,
        userId: line.user_id,
        item: line.item,
        quantity: line.quantity,
        customization: line.customization,
        createdAt: iso(line.created_at),
        updatedAt: iso(line.updated_at),
        owner: {
          id: line.owner_id,
          name: line.owner_name,
          avatar: line.owner_avatar,
          color: line.owner_color
        }
      })),
      activity: activityResult.rows.map((event) => ({
        id: event.id,
        userId: event.user_id,
        text: event.text,
        createdAt: iso(event.created_at)
      })),
      order: orderResult.rows[0]?.snapshot || null
    };
  }

  async joinRoom(code, userId) {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');
      const room = await this.#lockedRoom(client, code);
      if (room.status !== 'open') {
        throw new AppError(409, 'room_locked', 'This room has already checked out');
      }
      const insert = await client.query(
        `INSERT INTO room_participants (room_id, user_id) VALUES ($1, $2)
         ON CONFLICT DO NOTHING`,
        [room.id, userId]
      );
      if (insert.rowCount > 0) {
        const user = await this.getUser(userId);
        await client.query(
          'INSERT INTO activity_events (id, room_id, user_id, text) VALUES ($1, $2, $3, $4)',
          [uuid(), room.id, userId, `${user?.name || 'A guest'} joined the room`]
        );
        await client.query('UPDATE rooms SET version = version + 1 WHERE id = $1', [room.id]);
      }
      await client.query('COMMIT');
      return this.getRoomSnapshot(room.code);
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async addMessage(code, { userId, message }) {
    const room = await this.#room(code);
    const id = uuid();
    const { rows } = await this.pool.query(
      `INSERT INTO messages (id, room_id, user_id, message)
       VALUES ($1, $2, $3, $4)
       RETURNING id, user_id, message, reaction, created_at`,
      [id, room.id, userId, message]
    );
    await this.pool.query('UPDATE rooms SET version = version + 1 WHERE id = $1', [room.id]);
    return {
      id: rows[0].id,
      userId: rows[0].user_id,
      message: rows[0].message,
      reaction: rows[0].reaction,
      createdAt: iso(rows[0].created_at)
    };
  }

  async castVote(code, { userId, restaurantId, restaurantName }) {
    const room = await this.#room(code);
    const user = await this.getUser(userId);
    await this.pool.query(
      `INSERT INTO restaurant_votes (room_id, user_id, restaurant_id)
       VALUES ($1, $2, $3)
       ON CONFLICT (room_id, user_id)
       DO UPDATE SET restaurant_id = EXCLUDED.restaurant_id, created_at = NOW()`,
      [room.id, userId, restaurantId]
    );
    await this.pool.query(
      'INSERT INTO activity_events (id, room_id, user_id, text) VALUES ($1, $2, $3, $4)',
      [uuid(), room.id, userId, `${user?.name || 'A guest'} voted for ${restaurantName}`]
    );
    await this.pool.query('UPDATE rooms SET version = version + 1 WHERE id = $1', [room.id]);
    return this.getRoomSnapshot(room.code);
  }

  async setCartItem(code, { userId, item, quantity, customization }) {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');
      const room = await this.#lockedRoom(client, code);
      if (quantity === 0) {
        await client.query(
          `DELETE FROM cart_items
           WHERE room_id = $1 AND user_id = $2 AND item_id = $3 AND customization = $4`,
          [room.id, userId, item.id, customization]
        );
      } else {
        const mixed = await client.query(
          'SELECT 1 FROM cart_items WHERE room_id = $1 AND restaurant_id <> $2 LIMIT 1',
          [room.id, item.restaurantId]
        );
        if (mixed.rowCount > 0) {
          throw new AppError(409, 'mixed_restaurant_cart', 'The room cart already contains another restaurant');
        }
        await client.query(
          `INSERT INTO cart_items
             (id, room_id, user_id, item_id, restaurant_id, item, quantity, customization)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
           ON CONFLICT (room_id, user_id, item_id, customization)
           DO UPDATE SET item = EXCLUDED.item, quantity = EXCLUDED.quantity, updated_at = NOW()`,
          [uuid(), room.id, userId, item.id, item.restaurantId, item, quantity, customization]
        );
      }
      const user = await this.getUser(userId);
      const activityText = quantity === 0
        ? `${user?.name || 'A guest'} removed ${item.name}`
        : `${user?.name || 'A guest'} set ${item.name} to ${quantity}`;
      await client.query(
        'INSERT INTO activity_events (id, room_id, user_id, text) VALUES ($1, $2, $3, $4)',
        [uuid(), room.id, userId, activityText]
      );
      await client.query('UPDATE rooms SET version = version + 1 WHERE id = $1', [room.id]);
      await client.query('COMMIT');
      return this.getRoomSnapshot(room.code);
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async createOrder(code, order) {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');
      const room = await this.#lockedRoom(client, code);
      if (room.status !== 'open') {
        throw new AppError(409, 'room_locked', 'This room has already checked out');
      }
      await client.query(
        `INSERT INTO orders (id, room_id, user_id, swiggy_order_id, status, snapshot, created_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7)`,
        [order.id, room.id, order.userId, order.swiggyOrderId, order.status, order, order.createdAt]
      );
      await client.query(
        `UPDATE rooms SET status = 'locked', version = version + 1 WHERE id = $1`,
        [room.id]
      );
      await client.query(
        'INSERT INTO activity_events (id, room_id, user_id, text, created_at) VALUES ($1, $2, $3, $4, $5)',
        [uuid(), room.id, order.userId, `Order ${order.swiggyOrderId} confirmed`, order.createdAt]
      );
      await client.query('COMMIT');
      return this.getRoomSnapshot(room.code);
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async getOrder(orderId) {
    const { rows } = await this.pool.query('SELECT snapshot FROM orders WHERE id = $1', [orderId]);
    return rows[0]?.snapshot || null;
  }

  async findOperation(operationId) {
    const { rows } = await this.pool.query(
      'SELECT result FROM room_operations WHERE operation_id = $1',
      [operationId]
    );
    return rows[0]?.result || null;
  }

  async recordOperation(operationId, result) {
    await this.pool.query(
      `INSERT INTO room_operations (operation_id, result) VALUES ($1, $2)
       ON CONFLICT (operation_id) DO NOTHING`,
      [operationId, result]
    );
  }

  async #room(code) {
    const { rows } = await this.pool.query(
      'SELECT id, code, status FROM rooms WHERE code = $1',
      [code.toUpperCase()]
    );
    if (!rows[0]) throw new AppError(404, 'room_not_found', 'Room not found');
    return rows[0];
  }

  async #lockedRoom(client, code) {
    const { rows } = await client.query(
      'SELECT id, code, status FROM rooms WHERE code = $1 FOR UPDATE',
      [code.toUpperCase()]
    );
    if (!rows[0]) throw new AppError(404, 'room_not_found', 'Room not found');
    return rows[0];
  }
}
