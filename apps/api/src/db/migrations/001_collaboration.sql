CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  avatar TEXT NOT NULL,
  color TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS rooms (
  id TEXT PRIMARY KEY,
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  budget INTEGER NOT NULL CHECK (budget BETWEEN 500 AND 50000),
  host_user_id TEXT NOT NULL REFERENCES users(id),
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'locked')),
  version INTEGER NOT NULL DEFAULT 1,
  public_url TEXT NOT NULL DEFAULT 'https://homie.humanslop.in',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS room_participants (
  room_id TEXT NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (room_id, user_id)
);

CREATE TABLE IF NOT EXISTS messages (
  id TEXT PRIMARY KEY,
  room_id TEXT NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(id),
  message TEXT NOT NULL CHECK (char_length(message) BETWEEN 1 AND 500),
  reaction TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS restaurant_votes (
  room_id TEXT NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  restaurant_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (room_id, user_id)
);

CREATE TABLE IF NOT EXISTS cart_items (
  id TEXT PRIMARY KEY,
  room_id TEXT NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(id),
  item_id TEXT NOT NULL,
  restaurant_id TEXT NOT NULL,
  item JSONB NOT NULL,
  quantity INTEGER NOT NULL CHECK (quantity BETWEEN 1 AND 20),
  customization TEXT NOT NULL DEFAULT 'Regular',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (room_id, user_id, item_id, customization)
);

CREATE TABLE IF NOT EXISTS activity_events (
  id TEXT PRIMARY KEY,
  room_id TEXT NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
  user_id TEXT REFERENCES users(id),
  text TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS orders (
  id TEXT PRIMARY KEY,
  room_id TEXT NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(id),
  swiggy_order_id TEXT NOT NULL,
  status TEXT NOT NULL,
  snapshot JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS room_operations (
  operation_id TEXT PRIMARY KEY,
  result JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS messages_room_created_idx ON messages(room_id, created_at DESC);
CREATE INDEX IF NOT EXISTS activity_room_created_idx ON activity_events(room_id, created_at DESC);
CREATE INDEX IF NOT EXISTS orders_room_created_idx ON orders(room_id, created_at DESC);

INSERT INTO users (id, name, avatar, color) VALUES
  ('u1', 'Vamsi', 'GV', '#ff6d21'),
  ('u2', 'Aarav', 'AR', '#2d6a4f'),
  ('u3', 'Maya', 'MY', '#6c5ce7'),
  ('u4', 'Zoya', 'ZY', '#e84393'),
  ('u5', 'Kabir', 'KB', '#0984e3')
ON CONFLICT (id) DO NOTHING;

INSERT INTO rooms (id, code, name, budget, host_user_id)
VALUES ('room_1', 'HOMIE42', 'Friday House Party', 2500, 'u1')
ON CONFLICT (code) DO NOTHING;

INSERT INTO room_participants (room_id, user_id)
SELECT 'room_1', id FROM users WHERE id IN ('u1', 'u2', 'u3', 'u4', 'u5')
ON CONFLICT DO NOTHING;

INSERT INTO messages (id, room_id, user_id, message, reaction) VALUES
  ('m1', 'room_1', 'u2', 'Can we keep it spicy but not too heavy?', 'fire'),
  ('m2', 'room_1', 'u3', 'I am vegetarian tonight. Paneer or dosa works.', NULL)
ON CONFLICT (id) DO NOTHING;

INSERT INTO restaurant_votes (room_id, user_id, restaurant_id) VALUES
  ('room_1', 'u1', 'r0'),
  ('room_1', 'u2', 'r0'),
  ('room_1', 'u3', 'r1'),
  ('room_1', 'u4', 'r0'),
  ('room_1', 'u5', 'r2')
ON CONFLICT (room_id, user_id) DO NOTHING;

INSERT INTO cart_items (id, room_id, user_id, item_id, restaurant_id, item, quantity) VALUES
  (
    'cart_seed_1', 'room_1', 'u2', 'r0_m1', 'r0',
    '{"id":"r0_m1","restaurantId":"r0","name":"Chicken Biryani","description":"Dum cooked rice, raita, salan","price":329,"image":"https://images.unsplash.com/photo-1589302168068-964664d93dc0","tags":["nonVeg","spicy","party"]}'::jsonb,
    1
  ),
  (
    'cart_seed_2', 'room_1', 'u3', 'r0_m2', 'r0',
    '{"id":"r0_m2","restaurantId":"r0","name":"Truffle Fries","description":"Crispy fries, herb aioli, parmesan dust","price":179,"image":"https://images.unsplash.com/photo-1541592106381-b31e9677c0e5","tags":["veg","party"]}'::jsonb,
    2
  )
ON CONFLICT (id) DO NOTHING;

INSERT INTO activity_events (id, room_id, user_id, text) VALUES
  ('a1', 'room_1', 'u3', 'Maya voted for Pizza Ritual'),
  ('a2', 'room_1', 'u2', 'Aarav added Chicken Biryani'),
  ('a3', 'room_1', 'u4', 'Zoya joined via invite link')
ON CONFLICT (id) DO NOTHING;
