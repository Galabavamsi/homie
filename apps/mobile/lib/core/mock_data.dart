import '../domain/models/homie_models.dart';

const _images = [
  'https://images.unsplash.com/photo-1513104890138-7c749659a591',
  'https://images.unsplash.com/photo-1568901346375-23c9450c58cd',
  'https://images.unsplash.com/photo-1589302168068-964664d93dc0',
  'https://images.unsplash.com/photo-1600891964599-f61ba0e24092',
  'https://images.unsplash.com/photo-1543352634-a1c51d9f1fa7',
];

final mockParticipants = [
  const Participant(
      id: 'u1',
      name: 'Vamsi',
      avatar: 'GV',
      color: 0xFFFF6D21,
      cursorLabel: 'locking restaurant'),
  const Participant(
      id: 'u2', name: 'Aarav', avatar: 'AR', color: 0xFF2D6A4F, isTyping: true),
  const Participant(
      id: 'u3',
      name: 'Maya',
      avatar: 'MY',
      color: 0xFF6C5CE7,
      cursorLabel: 'viewing desserts'),
  const Participant(id: 'u4', name: 'Zoya', avatar: 'ZY', color: 0xFFE84393),
  const Participant(id: 'u5', name: 'Kabir', avatar: 'KB', color: 0xFF0984E3),
];

final mockRoom = Room(
  id: 'room_1',
  name: 'Friday House Party',
  code: 'HOMIE42',
  inviteLink: 'https://homie.humanslop.in/r/HOMIE42',
  budget: 2500,
  participants: mockParticipants,
);

final mockRestaurants = List.generate(20, (index) {
  final names = [
    'Biryani Borough',
    'Pizza Ritual',
    'Burger Lab',
    'Wok Street',
    'Dosa Garage',
    'Taco Theory',
    'Paneer & Co',
    'Midnight Momo',
    'Curry Cloud',
    'Dessert District',
  ];
  final cuisines = [
    'Biryani',
    'Pizza',
    'Burgers',
    'Asian',
    'South Indian',
    'Mexican',
    'North Indian',
    'Tibetan'
  ];
  return Restaurant(
    id: 'r$index',
    name: '${names[index % names.length]} ${index > 9 ? 'Express' : ''}'.trim(),
    cuisine: cuisines[index % cuisines.length],
    rating: 4.1 + (index % 7) / 10,
    etaMinutes: 18 + (index * 3) % 24,
    priceForTwo: 320 + (index * 70) % 620,
    image: _images[index % _images.length],
    tags: [
      if (index % 2 == 0) DietaryTag.veg else DietaryTag.nonVeg,
      if (index % 3 == 0) DietaryTag.spicy,
      if (index % 4 == 0) DietaryTag.party,
      if (index % 5 == 0) DietaryTag.lateNight,
      if (index % 6 == 0) DietaryTag.healthy,
    ],
    offer: '${20 + index % 5 * 5}% off via Swiggy',
  );
});

final mockMenu = mockRestaurants.expand((restaurant) {
  final dishes = [
    (
      'Paneer Tikka Bowl',
      'Smoky paneer, mint chutney, pickled onions',
      249,
      [DietaryTag.veg, DietaryTag.spicy]
    ),
    (
      'Chicken Biryani',
      'Dum cooked rice, raita, salan',
      329,
      [DietaryTag.nonVeg, DietaryTag.spicy, DietaryTag.party]
    ),
    (
      'Truffle Fries',
      'Crispy fries, herb aioli, parmesan dust',
      179,
      [DietaryTag.veg, DietaryTag.party]
    ),
    (
      'Rainbow Salad',
      'Greens, grains, avocado, citrus dressing',
      219,
      [DietaryTag.veg, DietaryTag.healthy]
    ),
    (
      'Chocolate Brownie Box',
      'Six warm brownies for sharing',
      299,
      [DietaryTag.dessert, DietaryTag.party]
    ),
    (
      'Late Night Combo',
      'Two mains, two drinks, one dessert',
      599,
      [DietaryTag.lateNight, DietaryTag.party]
    ),
  ];
  return dishes.asMap().entries.map((entry) {
    final dish = entry.value;
    return MenuItem(
      id: '${restaurant.id}_m${entry.key}',
      restaurantId: restaurant.id,
      name: dish.$1,
      description: dish.$2,
      price: dish.$3,
      image: _images[(entry.key + 1) % _images.length],
      tags: dish.$4,
    );
  });
}).toList();

final mockMessages = [
  ChatMessage(
      id: 'm1',
      sender: mockParticipants[1],
      message: 'Can we keep it spicy but not too heavy?',
      time: DateTime.now().subtract(const Duration(minutes: 12)),
      reaction: '🔥'),
  ChatMessage(
      id: 'm2',
      sender: mockParticipants[2],
      message: 'I am vegetarian tonight. Paneer or dosa works.',
      time: DateTime.now().subtract(const Duration(minutes: 8))),
  ChatMessage(
      id: 'm3',
      sender: mockParticipants[0],
      message: 'Voting closes in 2 minutes, then checkout through Swiggy.',
      time: DateTime.now().subtract(const Duration(minutes: 4)),
      reaction: '✅'),
];

final mockActivity = [
  ActivityEvent(
      id: 'a1',
      text: 'Maya voted for Pizza Ritual',
      time: DateTime.now().subtract(const Duration(minutes: 10))),
  ActivityEvent(
      id: 'a2',
      text: 'Aarav added Chicken Biryani',
      time: DateTime.now().subtract(const Duration(minutes: 6))),
  ActivityEvent(
      id: 'a3',
      text: 'Zoya joined via invite link',
      time: DateTime.now().subtract(const Duration(minutes: 3))),
];
