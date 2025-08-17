import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Yangi import
import 'package:savdo_uz/main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  // Tizimga kirish funksiyasi to'liq yangilandi
  Future<void> _signIn() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Firebase orqali tizimga kirish
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Foydalanuvchi topilmadi.');
      }

      // 2. Foydalanuvchi rolini Firestore'dan olish
      final docSnapshot = await FirebaseFirestore.instance
          .collection('employees')
          .doc(user.uid)
          .get();

      if (!docSnapshot.exists || docSnapshot.data() == null) {
        _errorMessage = 'Foydalanuvchi ma\'lumotlar bazasida topilmadi.';
        setState(() => _isLoading = false);
        return;
      }

      // Agar rol yozilmagan bo'lsa, 'Sotuvchi' standart rolini berish
      final userRole = docSnapshot.data()!['role'] as String? ?? 'Sotuvchi';

      // 3. Rol bilan birga asosiy ekranga o'tish
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            // XATO TUZATILDI: MainScreen'ga userRole parametri uzatildi
            builder: (context) => MainScreen(userRole: userRole),
          ),
        );
      }
    } on FirebaseAuthException {
      _errorMessage = 'Email yoki parol xato!';
    } catch (e) {
      _errorMessage = 'Tizimda kutilmagan xatolik yuz berdi.';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;
    final errorColor = Theme.of(context).colorScheme.error;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Savdo.uz',
                style: textTheme.displayLarge?.copyWith(color: primaryColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Tizimga kirish',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Parol',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: textTheme.bodyMedium?.copyWith(color: errorColor),
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _signIn,
                        child: const Text('KIRISH'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
