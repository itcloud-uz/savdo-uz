// lib/login_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:savdo_uz/main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    // Form validation
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Agar context hali mavjud bo'lsa, keyingi ekranga o'tish
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _translateErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            "Noma'lum xatolik yuz berdi. Iltimos, qayta urinib ko'ring.";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Firebase xatolik kodlarini o'zbek tiliga tarjima qilish
  String _translateErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Bunday foydalanuvchi topilmadi.';
      case 'wrong-password':
        return 'Parol noto‘g‘ri. Iltimos, tekshirib qayta kiriting.';
      case 'invalid-email':
        return 'Email manzil noto‘g‘ri formatda kiritilgan.';
      case 'user-disabled':
        return 'Bu foydalanuvchi akkaunti oʻchirib qoʻyilgan.';
      case 'network-request-failed':
        return 'Internet aloqasi mavjud emas. Ulanishni tekshiring.';
      default:
        return 'Kirishda xatolik yuz berdi.';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theme ma'lumotlarini osonroq chaqirish uchun
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Asosiy Sarlavha
                  Text(
                    'savdo.uz tizimiga',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge
                        ?.copyWith(color: Theme.of(context).primaryColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Xush kelibsiz!',
                    textAlign: TextAlign.center,
                    style: textTheme.displayMedium, // Yangi dizayn tizimidan
                  ),
                  const SizedBox(height: 40),

                  // Email kiritish maydoni
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Elektron pochta',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          !value.contains('@')) {
                        return 'Iltimos, to\'g\'ri elektron pochta kiriting';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Parol kiritish maydoni
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Parol',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Iltimos, parolni kiriting';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Xatolik xabarini ko'rsatish
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: colorScheme.error),
                      ),
                    ),

                  // Kirish tugmasi
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text('Kirish'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
