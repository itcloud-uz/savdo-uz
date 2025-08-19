import 'package:flutter/material.dart';
import 'package:savdo_uz/screens/home/main_screen.dart';
import 'package:savdo_uz/screens/scan/face_scan_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  void _login() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (_loginController.text == 'admin' &&
          _passwordController.text == 'password') {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Login yoki parol xato!';
            _isLoading = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.storefront_outlined,
                    size: 80, color: Theme.of(context).primaryColor),
                const SizedBox(height: 16),
                Text('Tizimga xush kelibsiz!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text('Savdo.uz hisobingizga kiring',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 40),
                TextFormField(
                    controller: _loginController,
                    decoration: const InputDecoration(
                        labelText: 'Login',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(12))))),
                const SizedBox(height: 16),
                TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Parol',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(12))))),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(_errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center),
                  ),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child: const Text('Kirish',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                const SizedBox(height: 16),
                const Row(children: [
                  Expanded(child: Divider()),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      child:
                          Text('yoki', style: TextStyle(color: Colors.grey))),
                  Expanded(child: Divider())
                ]),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const FaceScanScreen()),
                    );
                  },
                  icon: const Icon(Icons.face_retouching_natural_outlined),
                  label: const Text('Yuz orqali skanerlash'),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
