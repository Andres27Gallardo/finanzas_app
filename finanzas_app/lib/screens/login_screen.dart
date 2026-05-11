import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import 'home_screen.dart';
import 'profile_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false, _obscure = true;

  @override
  void dispose() { _nameCtrl.dispose(); _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final p = context.read<FinanceProvider>();
    bool ok;
    if (_isLogin) ok = await p.login(_emailCtrl.text.trim(), _passCtrl.text);
    else ok = await p.register(_nameCtrl.text.trim(), _emailCtrl.text.trim(), _passCtrl.text);
    setState(() => _loading = false);
    if (!mounted) return;
    if (ok) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => p.isProfileComplete ? const HomeScreen() : const ProfileSetupScreen()));
    else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isLogin ? '❌ Email o contraseña incorrectos' : '❌ Email ya registrado'), backgroundColor: Colors.red.shade700, behavior: SnackBarBehavior.floating));
  }

  void _showForgotPassword() {
    final emailCtrl = TextEditingController(text: _emailCtrl.text);
    final newPassCtrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Cambiar contraseña'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Ingresa tu email y una nueva contraseña:', style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 16),
        TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)), keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 12),
        TextField(controller: newPassCtrl, decoration: const InputDecoration(labelText: 'Nueva contraseña', prefixIcon: Icon(Icons.lock_outline)), obscureText: true),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () async {
          if (emailCtrl.text.isEmpty || newPassCtrl.text.length < 6) return;
          final ok = await context.read<FinanceProvider>().changePassword(emailCtrl.text.trim(), newPassCtrl.text);
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? '✅ Contraseña actualizada' : '❌ Email no encontrado'), backgroundColor: ok ? Colors.green : Colors.red, behavior: SnackBarBehavior.floating));
          }
        }, child: const Text('Cambiar')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment(0, 0.4), colors: [Color(0xFF6C63FF), Color(0xFF6C63FF)])),
        child: SafeArea(child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(24, 40, 24, 24), child: Column(children: [
            const Text('💰', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(_isLogin ? 'Bienvenido de vuelta' : 'Crea tu cuenta', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 6),
            Text(_isLogin ? 'Ingresa para ver tus finanzas' : 'Empieza tu journey financiero 🚀', style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ])),
          Expanded(child: Container(
            decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
            child: SingleChildScrollView(padding: const EdgeInsets.all(28), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const SizedBox(height: 8),
              if (!_isLogin) ...[
                TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nombre completo', prefixIcon: Icon(Icons.person_outline)), textCapitalization: TextCapitalization.words, validator: (v) => (v?.isEmpty ?? true) ? 'Escribe tu nombre' : null),
                const SizedBox(height: 16),
              ],
              TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.email_outlined)), keyboardType: TextInputType.emailAddress, validator: (v) => !(v?.contains('@') ?? false) ? 'Email inválido' : null),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passCtrl,
                decoration: InputDecoration(labelText: 'Contraseña', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: () => setState(() => _obscure = !_obscure))),
                obscureText: _obscure,
                validator: (v) => (v?.length ?? 0) < 6 ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 28),
              ElevatedButton(onPressed: _loading ? null : _submit, child: _loading ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : Text(_isLogin ? 'Iniciar Sesión' : 'Registrarse')),
              const SizedBox(height: 12),
              if (_isLogin) TextButton(onPressed: _showForgotPassword, child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(color: Color(0xFF6C63FF)))),
              TextButton(onPressed: () { setState(() => _isLogin = !_isLogin); _formKey.currentState?.reset(); }, child: Text(_isLogin ? '¿No tienes cuenta? Regístrate gratis' : '¿Ya tienes cuenta? Inicia sesión', style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.w500))),
            ]))),
          )),
        ])),
      ),
    );
  }
}
