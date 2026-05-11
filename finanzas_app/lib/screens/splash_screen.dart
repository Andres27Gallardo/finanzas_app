import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'profile_setup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _fade;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2200), _navigate);
  }
  void _navigate() {
    if (!mounted) return;
    final p = context.read<FinanceProvider>();
    Widget dest;
    if (!p.isLoggedIn) dest = const LoginScreen();
    else if (!p.isProfileComplete) dest = const ProfileSetupScreen();
    else dest = const HomeScreen();
    Navigator.of(context).pushReplacement(PageRouteBuilder(pageBuilder: (_, __, ___) => dest, transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c), transitionDuration: const Duration(milliseconds: 400)));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF6C63FF), Color(0xFF3F3D56)])),
        child: FadeTransition(opacity: _fade, child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          ScaleTransition(scale: _scale, child: Container(width: 120, height: 120, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: const Center(child: Text('💰', style: TextStyle(fontSize: 60))))),
          const SizedBox(height: 24),
          const Text('Finanzas IA', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Tu asistente financiero inteligente', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 60),
          const SizedBox(width: 30, height: 30, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
        ]))),
      ),
    );
  }
}
