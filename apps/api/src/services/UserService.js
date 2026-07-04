import { users } from '../data/mockData.js';

export class UserService {
  currentUser() {
    return users[0];
  }

  listUsers() {
    return users;
  }
}
