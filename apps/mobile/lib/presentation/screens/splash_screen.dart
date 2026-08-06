import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/homie_widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) context.go('/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: .88, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutBack,
          builder: (context, value, child) =>
              Transform.scale(scale: value, child: child),
          child: const GlassPanel(
            padding: EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_dining_rounded,
                    size: 58, color: Color(0xFFFF6D21)),
                SizedBox(height: 16),
                Text('Homie',
                    style:
                        TextStyle(fontSize: 40, fontWeight: FontWeight.w900)),
                SizedBox(height: 8),
                Text('Group ordering, powered by Swiggy MCP'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
