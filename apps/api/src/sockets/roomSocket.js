const errorPayload = (error) => ({
  ok: false,
  error: {
    code: error.code || 'socket_error',
    message: error.message || 'Realtime operation failed',
    details: error.details
  }
});

export function registerRoomSockets(io, services) {
  const collaboration = services.collaborationService;
  const presence = new Map();

  const publishPresence = (roomCode) => {
    const online = presence.get(roomCode);
    io.to(roomCode).emit('room:presence', {
      roomCode,
      onlineUserIds: online ? [...online.keys()] : []
    });
  };

  const enterPresence = (roomCode, userId, socketId) => {
    if (!presence.has(roomCode)) presence.set(roomCode, new Map());
    const room = presence.get(roomCode);
    if (!room.has(userId)) room.set(userId, new Set());
    room.get(userId).add(socketId);
  };

  const leavePresence = (roomCode, userId, socketId) => {
    const room = presence.get(roomCode);
    const sockets = room?.get(userId);
    sockets?.delete(socketId);
    if (sockets?.size === 0) room.delete(userId);
    if (room?.size === 0) presence.delete(roomCode);
  };

  const mutation = (socket, event, action) => {
    socket.on(event, async (payload = {}, acknowledge = () => {}) => {
      try {
        const snapshot = await action(payload);
        acknowledge({ ok: true, data: snapshot });
        io.to(snapshot.room.code).emit('room:snapshot', snapshot);
      } catch (error) {
        acknowledge(errorPayload(error));
      }
    });
  };

  io.on('connection', (socket) => {
    socket.on('room:join', async (payload = {}, acknowledge = () => {}) => {
      try {
        const roomCode = String(payload.roomCode || '').trim().toUpperCase();
        const snapshot = await collaboration.joinRoom(
          roomCode,
          payload.userId,
          payload.operationId
        );
        socket.join(roomCode);
        socket.data.roomCode = roomCode;
        socket.data.userId = payload.userId;
        enterPresence(roomCode, payload.userId, socket.id);
        acknowledge({ ok: true, data: snapshot });
        io.to(roomCode).emit('room:snapshot', snapshot);
        publishPresence(roomCode);
      } catch (error) {
        acknowledge(errorPayload(error));
      }
    });

    mutation(socket, 'chat:send', (payload) =>
      collaboration.sendMessage(payload.roomCode, payload));
    mutation(socket, 'vote:cast', (payload) =>
      collaboration.vote(payload.roomCode, payload));
    mutation(socket, 'cart:set', (payload) =>
      collaboration.setCartItem(payload.roomCode, payload));

    socket.on('typing:start', ({ roomCode, userId } = {}) => {
      socket.to(roomCode).emit('typing:changed', { userId, isTyping: true });
    });
    socket.on('typing:stop', ({ roomCode, userId } = {}) => {
      socket.to(roomCode).emit('typing:changed', { userId, isTyping: false });
    });

    socket.on('disconnect', () => {
      const { roomCode, userId } = socket.data;
      if (!roomCode || !userId) return;
      leavePresence(roomCode, userId, socket.id);
      publishPresence(roomCode);
    });
  });
}
