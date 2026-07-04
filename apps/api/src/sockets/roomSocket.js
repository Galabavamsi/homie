export function registerRoomSockets(io, services) {
  io.on('connection', (socket) => {
    socket.on('room:join', ({ roomCode, userId }) => {
      const room = services.roomService.join(roomCode, userId || 'u1');
      if (!room) {
        socket.emit('room:error', { message: 'Room not found' });
        return;
      }
      socket.join(roomCode);
      io.to(roomCode).emit('room:presence', {
        roomCode,
        participants: room.participants,
        activity: `${userId || 'u1'} joined the room`
      });
    });

    socket.on('chat:message', ({ roomCode, message, userId }) => {
      const room = services.roomService.get(roomCode);
      if (!room) return;
      const payload = {
        id: `m_${Date.now()}`,
        userId: userId || 'u1',
        message,
        createdAt: new Date().toISOString()
      };
      room.messages.unshift(payload);
      io.to(roomCode).emit('chat:message', payload);
    });

    socket.on('cart:update', async ({ roomCode, cart }) => {
      const result = await services.cartService.sync(roomCode, cart || []);
      if (result) io.to(roomCode).emit('cart:update', result.cart);
    });

    socket.on('restaurant:vote', ({ roomCode, restaurantId }) => {
      const room = services.roomService.get(roomCode);
      if (!room) return;
      room.votes[restaurantId] = (room.votes[restaurantId] || 0) + 1;
      io.to(roomCode).emit('restaurant:votes', room.votes);
    });

    socket.on('typing:start', ({ roomCode, userId }) => {
      socket.to(roomCode).emit('typing:start', { userId });
    });

    socket.on('typing:stop', ({ roomCode, userId }) => {
      socket.to(roomCode).emit('typing:stop', { userId });
    });
  });
}
