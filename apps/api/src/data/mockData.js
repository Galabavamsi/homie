export const users = [
  { id: 'u1', name: 'Vamsi', avatar: 'GV', color: '#ff6d21' },
  { id: 'u2', name: 'Aarav', avatar: 'AR', color: '#2d6a4f' },
  { id: 'u3', name: 'Maya', avatar: 'MY', color: '#6c5ce7' },
  { id: 'u4', name: 'Zoya', avatar: 'ZY', color: '#e84393' },
  { id: 'u5', name: 'Kabir', avatar: 'KB', color: '#0984e3' }
];

const cuisines = ['Biryani', 'Pizza', 'Burgers', 'Asian', 'South Indian', 'Mexican', 'North Indian', 'Desserts'];
const names = ['Biryani Borough', 'Pizza Ritual', 'Burger Lab', 'Wok Street', 'Dosa Garage', 'Taco Theory', 'Paneer & Co', 'Midnight Momo', 'Curry Cloud', 'Dessert District'];

export const restaurants = Array.from({ length: 20 }, (_, index) => ({
  id: `r${index}`,
  name: `${names[index % names.length]}${index > 9 ? ' Express' : ''}`,
  cuisine: cuisines[index % cuisines.length],
  rating: Number((4.1 + (index % 7) / 10).toFixed(1)),
  etaMinutes: 18 + (index * 3) % 24,
  priceForTwo: 320 + (index * 70) % 620,
  offer: `${20 + (index % 5) * 5}% off via Swiggy`,
  tags: [index % 2 === 0 ? 'veg' : 'nonVeg', index % 3 === 0 ? 'spicy' : 'healthy', index % 4 === 0 ? 'party' : 'lateNight']
}));

export const menus = Object.fromEntries(restaurants.map((restaurant) => [
  restaurant.id,
  [
    { id: `${restaurant.id}_m0`, restaurantId: restaurant.id, name: 'Paneer Tikka Bowl', description: 'Smoky paneer, mint chutney, pickled onions', price: 249, tags: ['veg', 'spicy'] },
    { id: `${restaurant.id}_m1`, restaurantId: restaurant.id, name: 'Chicken Biryani', description: 'Dum cooked rice, raita, salan', price: 329, tags: ['nonVeg', 'spicy', 'party'] },
    { id: `${restaurant.id}_m2`, restaurantId: restaurant.id, name: 'Truffle Fries', description: 'Crispy fries, herb aioli, parmesan dust', price: 179, tags: ['veg', 'party'] },
    { id: `${restaurant.id}_m3`, restaurantId: restaurant.id, name: 'Rainbow Salad', description: 'Greens, grains, avocado, citrus dressing', price: 219, tags: ['veg', 'healthy'] },
    { id: `${restaurant.id}_m4`, restaurantId: restaurant.id, name: 'Chocolate Brownie Box', description: 'Six warm brownies for sharing', price: 299, tags: ['dessert', 'party'] },
    { id: `${restaurant.id}_m5`, restaurantId: restaurant.id, name: 'Late Night Combo', description: 'Two mains, two drinks, one dessert', price: 599, tags: ['lateNight', 'party'] }
  ]
]));

export const rooms = new Map([
  ['HOMIE42', {
    id: 'room_1',
    code: 'HOMIE42',
    name: 'Friday House Party',
    budget: 2500,
    inviteLink: 'https://homie.humanslop.in/r/HOMIE42',
    participants: users,
    messages: [
      { id: 'm1', userId: 'u2', message: 'Can we keep it spicy but not too heavy?', createdAt: new Date().toISOString(), reaction: 'fire' },
      { id: 'm2', userId: 'u3', message: 'I am vegetarian tonight. Paneer or dosa works.', createdAt: new Date().toISOString() }
    ],
    votes: { r0: 7, r1: 4, r2: 2 },
    cart: []
  }]
]);
