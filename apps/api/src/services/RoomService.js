import { v4 as uuid } from 'uuid';
import { rooms, users } from '../data/mockData.js';

export class RoomService {
  create({ name, budget }) {
    const code = `HM${Math.random().toString(36).slice(2, 6).toUpperCase()}`;
    const room = {
      id: uuid(),
      code,
      name,
      budget,
      inviteLink: `https://homie.humanslop.in/r/${code}`,
      participants: [users[0]],
      messages: [],
      votes: {},
      cart: []
    };
    rooms.set(code, room);
    return room;
  }

  get(code) {
    return rooms.get(code);
  }

  join(code, userId) {
    const room = rooms.get(code);
    const user = users.find((item) => item.id === userId);
    if (!room || !user) return null;
    if (!room.participants.some((participant) => participant.id === userId)) {
      room.participants.push(user);
    }
    return room;
  }
}
