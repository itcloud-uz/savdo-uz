// Tizimga kirish ekrani.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:savdo_uz/providers/auth_provider.dart';
import 'package:savdo_uz/widgets/custom_textfield.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email yoki parol xato.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Savdo-UZ',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 48),
                CustomTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => (value == null || !value.contains('@'))
                      ? 'To\'g\'ri email kiriting'
                      : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _passwordController,
                  labelText: 'Parol',
                  obscureText: true,
                  validator: (value) => (value == null || value.length < 6)
                      ? 'Parol kamida 6 belgidan iborat bo\'lishi kerak'
                      : null,
                ),
                const SizedBox(height: 32),
                authProvider.status == AuthStatus.authenticating
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _login,
                          child: const Text('Kirish'),
                        ),
                      ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // Yuz orqali kirish ekraniga o'tish
                  },
                  child: const Text('Yuz orqali kirish'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
