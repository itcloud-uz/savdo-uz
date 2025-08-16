import 'package:flutter/material.dart';
import 'package:savdo_uz/main_screen.dart';
import 'package:savdo_uz/face_scan_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginController = TextEditingController();
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _loginController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  // Login va PIN-kod orqali kirish funksiyasi
  Future<void> _loginWithCredentials() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final login = _loginController.text;
      final pin = _pinController.text;
      final usersCollection = FirebaseFirestore.instance.collection('users');

      // Kiritilgan login va PIN-kod bo'yicha xodimni qidiramiz
      final querySnapshot = await usersCollection
          .where('login',
              isEqualTo: login) // 'login' maydoni bo'yicha qidiramiz
          .where('pinCode', isEqualTo: pin)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty && mounted) {
        final userDoc = querySnapshot.docs.first;
        final userRole = userDoc.data()['role'] as String;
        _navigateToMainScreen(context, userRole);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Login yoki PIN-kod noto'g'ri!"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Xatolik: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToMainScreen(BuildContext context, String userRole) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => MainScreen(userRole: userRole)),
    );
  }

  void _navigateToFaceScan(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const FaceScanScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_rounded,
                      size: 64, color: Colors.blue),
                  const SizedBox(height: 20),
                  const Text('Tizimga xush kelibsiz!',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Iltimos, tizimga kirish usulini tanlang',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 40),

                  // Yuzni skanerlash bo'limi
                  _buildSectionTitle('Yuzni Skanerlash'),
                  const SizedBox(height: 16),
                  _buildRoleButton(context,
                      label: 'Yuzni Skanerlash',
                      color: Colors.blue,
                      onPressed: () => _navigateToFaceScan(context)),
                  const SizedBox(height: 32),

                  // Login va PIN-kod bo'limi
                  _buildSectionTitle('Login va PIN-kod orqali'),
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _loginController,
                          decoration: const InputDecoration(
                            labelText: 'Login',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Iltimos, loginni kiriting";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _pinController,
                          obscureText: true,
                          maxLength: 4,
                          decoration: const InputDecoration(
                            labelText: 'PIN-kod',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock_outline),
                            counterText: "",
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.length < 4) {
                              return 'PIN-kod 4 xonali bo\'lishi kerak';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                          onPressed: _loginWithCredentials,
                          icon: const Icon(Icons.login),
                          label: const Text('Kirish'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Bo'lim sarlavhasi uchun yordamchi funksiya
  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
        ),
        const Divider(),
      ],
    );
  }

  Widget _buildRoleButton(BuildContext context,
      {required String label,
      required Color color,
      required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.face_retouching_natural),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 16),
      ),
    );
  }
}
