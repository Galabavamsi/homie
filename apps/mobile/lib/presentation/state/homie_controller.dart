import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/mock_data.dart';
import '../../data/network/homie_api.dart';
import '../../data/repositories/homie_repository.dart';
import '../../domain/models/homie_models.dart';

final homieRepositoryProvider = Provider<HomieRepository>((ref) {
  final repository = HomieRepository();
  ref.onDispose(() => unawaited(repository.dispose()));
  return repository;
});

final homieControllerProvider =
    StateNotifierProvider<HomieController, HomieState>((ref) {
  final controller = HomieController(ref.watch(homieRepositoryProvider));
  unawaited(controller.initialize());
  return controller;
});

class HomieController extends StateNotifier<HomieState> {
  HomieController(this._repository)
      : super(
          HomieState(
            currentUser: mockParticipants.first,
            room: mockRoom,
            restaurants: mockRestaurants,
            menu: mockMenu,
            selectedRestaurantId: mockRestaurants.first.id,
            votes: {
              for (final restaurant in mockRestaurants.take(5))
                restaurant.id: 1 + int.parse(restaurant.id.substring(1)) % 7,
            },
            cart: [
              CartItem(
                id: 'c1',
                item: mockMenu[1],
                owner: mockParticipants[1],
                quantity: 1,
              ),
              CartItem(
                id: 'c2',
                item: mockMenu[2],
                owner: mockParticipants[2],
                quantity: 2,
              ),
            ],
            messages: mockMessages,
            activity: mockActivity,
            orderSteps: const [],
          ),
        ) {
    _subscriptions.add(_repository.snapshots.listen((json) {
      _applySnapshot(RoomSnapshot.fromJson(json));
    }));
    _subscriptions.add(_repository.realtimeStatus.listen((status) {
      if (mounted) state = state.copyWith(realtimeStatus: status);
    }));
    _subscriptions.add(_repository.presence.listen(_applyPresence));
    _subscriptions.add(_repository.typing.listen(_applyTyping));
  }

  final HomieRepository _repository;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  Timer? _searchTimer;

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.restoreUser();
      final source = await _repository.healthSource();
      final live = source.endsWith('live');
      final connected = live && user != null
          ? await _repository.swiggyConnected(user.id)
          : false;
      if (live && (user == null || !connected)) {
        if (!mounted) return;
        state = state.copyWith(
          currentUser: user ?? state.currentUser,
          hasSession: user != null,
          swiggyConnected: connected,
          mcpSource: source,
          restaurants: const [],
          menu: const [],
          selectedRestaurantId: '',
          isLoading: false,
        );
        return;
      }
      if (live) {
        final addresses = await _repository.addresses(user!.id);
        if (!mounted) return;
        state = state.copyWith(
          currentUser: user,
          hasSession: true,
          swiggyConnected: true,
          addresses: addresses,
          mcpSource: source,
        );
        if (addresses.isEmpty || state.selectedAddressId == null) {
          state = state.copyWith(isLoading: false);
          return;
        }
      }
      final restaurantResult = await _repository.restaurants(
        userId: live ? user!.id : null,
        addressId: live ? state.selectedAddressId : null,
      );
      final restaurants = restaurantResult.restaurants;
      final menu = restaurants.isEmpty
          ? <MenuItem>[]
          : await _repository.menu(
              restaurants.first.id,
              userId: live ? user!.id : null,
              addressId: live ? state.selectedAddressId : null,
            );
      if (!mounted) return;
      state = state.copyWith(
        currentUser: user,
        hasSession: user != null,
        restaurants: restaurants.isEmpty ? null : restaurants,
        menu: menu.isEmpty ? null : menu,
        selectedRestaurantId: restaurants.isEmpty ? null : restaurants.first.id,
        mcpSource: source,
        isLoading: false,
        swiggyConnected: connected,
      );
    } on Object catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        realtimeStatus: RealtimeStatus.offline,
        errorMessage: _message(error),
      );
    }
  }

  Future<bool> login(String name) async {
    final cleanName = name.trim();
    if (cleanName.length < 2) {
      state = state.copyWith(
          errorMessage: 'Enter at least two characters for your name');
      return false;
    }
    return _run(() async {
      final user = await _repository.createGuest(cleanName);
      state = state.copyWith(currentUser: user, hasSession: true);
    });
  }

  bool continueSession() {
    if (!state.hasSession) {
      state =
          state.copyWith(errorMessage: 'Create a local guest session first');
      return false;
    }
    return true;
  }

  Future<bool> connectSwiggy() => _run(() async {
        if (!state.hasSession) {
          throw const ApiException('session_required', 'Enter Homie before connecting Swiggy');
        }
        final authorizationUrl = await _repository.swiggyAuthUrl(state.currentUser.id);
        final opened = await launchUrl(
          authorizationUrl,
          mode: LaunchMode.externalApplication,
        );
        if (!opened) {
          throw const ApiException('browser_unavailable', 'Could not open the Swiggy sign-in page');
        }

        final deadline = DateTime.now().add(const Duration(minutes: 2));
        while (DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(seconds: 3));
          if (await _repository.swiggyConnected(state.currentUser.id)) {
            if (!mounted) return;
            state = state.copyWith(swiggyConnected: true, clearError: true);
            await _loadLiveAddresses();
            return;
          }
        }
        throw const ApiException(
          'oauth_pending',
          'Finish Swiggy sign-in in the browser, then tap Connect Swiggy again.',
        );
      });

  Future<void> _loadLiveAddresses() async {
    final addresses = await _repository.addresses(state.currentUser.id);
    if (!mounted) return;
    state = state.copyWith(addresses: addresses);
    if (addresses.isEmpty) {
      throw const ApiException(
        'swiggy_address_missing',
        'Add a saved delivery address in Swiggy before browsing food.',
      );
    }
  }

  Future<bool> selectAddress(String addressId) => _run(() async {
        await _repository.selectAddress(
          userId: state.currentUser.id,
          addressId: addressId,
        );
        final result = await _repository.restaurants(
          userId: state.currentUser.id,
          addressId: addressId,
        );
        state = state.copyWith(
          selectedAddressId: addressId,
          restaurants: result.restaurants,
          mcpSource: result.source,
          selectedRestaurantId:
              result.restaurants.isEmpty ? '' : result.restaurants.first.id,
          menu: const [],
        );
        await _ensureSelectedMenu();
      });

  Future<bool> createRoom(String name, int budget) {
    if (name.trim().length < 2) {
      state = state.copyWith(
        errorMessage: 'Give the room a name with at least two characters',
      );
      return Future.value(false);
    }
    return _run(() async {
      final snapshot = await _repository.createRoom(
        name: name.trim(),
        budget: budget,
        hostUserId: state.currentUser.id,
      );
      _applySnapshot(snapshot);
      await _ensureSelectedMenu();
    });
  }

  Future<bool> joinRoom(String code) => _run(() async {
        final snapshot = await _repository.joinRoom(code, state.currentUser.id);
        _applySnapshot(snapshot);
        await _ensureSelectedMenu();
      });

  Future<bool> refreshRoom() => _run(() async {
        final snapshot = await _repository.refreshRoom(state.room.code);
        _applySnapshot(snapshot);
      }, showBusy: false);

  void searchRestaurants(String query) {
    state = state.copyWith(search: query, clearError: true);
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 350), () {
      unawaited(_loadRestaurants(query: query, filter: state.filter));
    });
  }

  Future<void> setFilter(DietaryTag? filter) async {
    state = state.copyWith(
        filter: filter, clearFilter: filter == null, clearError: true);
    await _loadRestaurants(query: state.search, filter: filter);
  }

  Future<void> _loadRestaurants({String? query, DietaryTag? filter}) async {
    try {
      final result =
          await _repository.restaurants(
            query: query,
            filter: filter,
            userId: state.hasSession ? state.currentUser.id : null,
            addressId: state.selectedAddressId,
          );
      if (!mounted) return;
      if (result.restaurants.isEmpty) {
        state =
            state.copyWith(errorMessage: 'No restaurants match those filters');
        return;
      }
      final selectedStillVisible = result.restaurants.any(
        (restaurant) => restaurant.id == state.selectedRestaurantId,
      );
      state = state.copyWith(
        restaurants: result.restaurants,
        selectedRestaurantId: selectedStillVisible
            ? state.selectedRestaurantId
            : (result.restaurants.isEmpty ? '' : result.restaurants.first.id),
        mcpSource: result.source,
        clearError: true,
      );
      await _ensureSelectedMenu();
    } on Object catch (error) {
      if (mounted) state = state.copyWith(errorMessage: _message(error));
    }
  }

  Future<void> selectRestaurant(String id) async {
    state = state.copyWith(selectedRestaurantId: id, clearError: true);
    await _ensureSelectedMenu();
  }

  Future<void> _ensureSelectedMenu() async {
    if (state.selectedRestaurantId.isEmpty) return;
    if (state.menu
        .any((item) => item.restaurantId == state.selectedRestaurantId)) return;
    try {
      final fetched = await _repository.menu(
        state.selectedRestaurantId,
        userId: state.hasSession ? state.currentUser.id : null,
        addressId: state.selectedAddressId,
      );
      if (!mounted) return;
      final retained = state.menu
          .where((item) => item.restaurantId != state.selectedRestaurantId)
          .toList();
      state = state.copyWith(menu: [...retained, ...fetched]);
    } on Object catch (error) {
      if (mounted) state = state.copyWith(errorMessage: _message(error));
    }
  }

  Future<void> vote(String restaurantId) async {
    await _run(() async {
      _applySnapshot(await _repository.vote(
        code: state.room.code,
        userId: state.currentUser.id,
        restaurantId: restaurantId,
      ));
    }, showBusy: false);
  }

  Future<void> addToCart(MenuItem item) async {
    final existing = state.cart.where(
      (line) =>
          line.owner.id == state.currentUser.id && line.item.id == item.id,
    );
    final quantity = existing.isEmpty ? 1 : existing.first.quantity + 1;
    await setCartQuantity(item, quantity);
  }

  Future<void> setCartQuantity(MenuItem item, int quantity) async {
    await _run(() async {
      _applySnapshot(await _repository.setCartItem(
        code: state.room.code,
        userId: state.currentUser.id,
        item: item,
        quantity: quantity.clamp(0, 20),
      ));
    }, showBusy: false);
  }

  Future<void> sendMessage(String text) async {
    final message = text.trim();
    if (message.isEmpty) return;
    await _run(() async {
      _applySnapshot(await _repository.sendMessage(
        code: state.room.code,
        userId: state.currentUser.id,
        message: message,
      ));
    }, showBusy: false);
  }

  void setTyping(bool value) => _repository.setTyping(value);

  void askAssistant(String prompt) {
    final lower = prompt.toLowerCase();
    final answer = lower.contains('budget')
        ? 'Budget-safe plan: order two shareable mains, one starter, and a dessert. The room has INR ${(state.room.budget - state.grandTotal).clamp(0, state.room.budget)} left.'
        : lower.contains('veg')
            ? 'Vegetarian picks: Paneer Tikka Bowl, Rainbow Salad, Truffle Fries, and Brownie Box balance spicy, healthy, and sharing choices.'
            : 'I would vote for ${state.selectedRestaurant.name}: ${state.selectedRestaurant.rating.toStringAsFixed(1)} rating, ${state.selectedRestaurant.etaMinutes} minute ETA, and a group-friendly menu.';
    state = state.copyWith(assistantText: answer);
  }

  Future<bool> checkout() => _run(() async {
        _applySnapshot(await _repository.checkout(
          code: state.room.code,
          userId: state.currentUser.id,
        ));
      });

  void dismissError() => state = state.copyWith(clearError: true);

  void _applySnapshot(RoomSnapshot snapshot) {
    if (!mounted) return;
    final cartRestaurant =
        snapshot.cart.isEmpty ? null : snapshot.cart.first.item.restaurantId;
    final selected = cartRestaurant ??
        (state.restaurants.any((item) => item.id == state.selectedRestaurantId)
            ? state.selectedRestaurantId
            : (state.restaurants.isEmpty ? '' : state.restaurants.first.id));
    state = state.copyWith(
      room: snapshot.room,
      votes: snapshot.votes,
      userVotes: snapshot.userVotes,
      cart: snapshot.cart,
      messages: snapshot.messages,
      activity: snapshot.activity,
      orderSteps: snapshot.orderSteps,
      selectedRestaurantId: selected,
      clearError: true,
    );
  }

  void _applyPresence(Map<String, dynamic> payload) {
    if (!mounted) return;
    final online = (payload['onlineUserIds'] as List? ?? const [])
        .map((value) => value.toString())
        .toSet();
    Participant apply(Participant participant) => participant.copyWith(
          isOnline: online.contains(participant.id),
        );
    state = state.copyWith(
      room: state.room.copyWith(
        participants: state.room.participants.map(apply).toList(),
      ),
      cart: state.cart
          .map((line) => line.copyWith(owner: apply(line.owner)))
          .toList(),
      messages: state.messages
          .map((message) => message.copyWith(sender: apply(message.sender)))
          .toList(),
    );
  }

  void _applyTyping(Map<String, dynamic> payload) {
    if (!mounted) return;
    final userId = payload['userId']?.toString();
    final isTyping = payload['isTyping'] as bool? ?? false;
    state = state.copyWith(
      room: state.room.copyWith(
        participants: state.room.participants
            .map((participant) => participant.id == userId
                ? participant.copyWith(isTyping: isTyping)
                : participant)
            .toList(),
      ),
    );
  }

  Future<bool> _run(
    Future<void> Function() action, {
    bool showBusy = true,
  }) async {
    if (showBusy) state = state.copyWith(isBusy: true, clearError: true);
    try {
      await action();
      if (mounted && showBusy) state = state.copyWith(isBusy: false);
      return true;
    } on Object catch (error) {
      if (mounted) {
        state = state.copyWith(
          isBusy: false,
          errorMessage: _message(error),
          realtimeStatus: error is ApiException && error.code == 'offline'
              ? RealtimeStatus.offline
              : null,
        );
      }
      return false;
    }
  }

  String _message(Object error) => error is ApiException
      ? error.message
      : 'Something went wrong. Please try again.';

  @override
  void dispose() {
    _searchTimer?.cancel();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }
}
