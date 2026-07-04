import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/app_theme.dart';
import 'screens/checkout_screen.dart';
import 'screens/create_room_screen.dart';
import 'screens/home_screen.dart';
import 'screens/invite_screen.dart';
import 'screens/login_screen.dart';
import 'screens/order_tracking_screen.dart';
import 'screens/room_screen.dart';
import 'screens/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/create-room', builder: (_, __) => const CreateRoomScreen()),
      GoRoute(path: '/invite', builder: (_, __) => const InviteScreen()),
      GoRoute(path: '/room', builder: (_, __) => const RoomScreen()),
      GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),
      GoRoute(path: '/tracking', builder: (_, __) => const OrderTrackingScreen()),
    ],
  );
});

class HomieApp extends ConsumerWidget {
  const HomieApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Homie',
      debugShowCheckedModeBanner: false,
      theme: HomieTheme.light(),
      darkTheme: HomieTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
