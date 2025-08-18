import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:savdo_uz/services/firestore_service.dart';

class AddEditEmployeeScreen extends StatefulWidget {
  final DocumentSnapshot? document;

  const AddEditEmployeeScreen({super.key, this.document});

  @override
  State<AddEditEmployeeScreen> createState() => _AddEditEmployeeScreenState();
}

class _AddEditEmployeeScreenState extends State<AddEditEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();

  late TextEditingController _nameController;
  late TextEditingController _positionController;
  late TextEditingController _loginController;
  late TextEditingController _passwordController;

  File? _imageFile;
  String? _existingImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final data = widget.document?.data() as Map<String, dynamic>?;

    _nameController = TextEditingController(text: data?['name'] ?? '');
    _positionController = TextEditingController(text: data?['position'] ?? '');
    _loginController = TextEditingController(text: data?['login'] ?? '');
    _passwordController = TextEditingController(text: data?['password'] ?? '');
    _existingImageUrl = data?['imageUrl'];
  }

  Future<void> _pickImage() async {
    final pickedFile = await _firestoreService.pickImage();
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  Future<void> _saveEmployee() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        String? imageUrl = _existingImageUrl;

        // Agar yangi rasm tanlangan bo'lsa, uni yuklaymiz
        if (_imageFile != null) {
          imageUrl = await _firestoreService.uploadImage(_imageFile!);
        }

        await _firestoreService.saveEmployee(
          id: widget.document?.id,
          name: _nameController.text,
          position: _positionController.text,
          login: _loginController.text,
          password: _passwordController.text,
          imageUrl: imageUrl,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ma'lumotlar saqlandi!")),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Xatolik yuz berdi: $e")),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.document == null ? 'Yangi Xodim' : 'Xodimni Tahrirlash'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveEmployee,
            )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : (_existingImageUrl != null
                                    ? NetworkImage(_existingImageUrl!)
                                    : null) as ImageProvider?,
                            child:
                                _imageFile == null && _existingImageUrl == null
                                    ? const Icon(Icons.person,
                                        size: 60, color: Colors.white)
                                    : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt,
                                    color: Colors.white),
                                onPressed: _pickImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration:
                          const InputDecoration(labelText: 'Ism Familiya'),
                      validator: (value) =>
                          value!.isEmpty ? 'Maydonni to\'ldiring' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _positionController,
                      decoration: const InputDecoration(labelText: 'Lavozimi'),
                      validator: (value) =>
                          value!.isEmpty ? 'Maydonni to\'ldiring' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _loginController,
                      decoration: const InputDecoration(labelText: 'Login'),
                      validator: (value) =>
                          value!.isEmpty ? 'Maydonni to\'ldiring' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Parol'),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          if (widget.document == null) {
                            // Faqat yangi xodim uchun majburiy
                            return 'Parolni kiriting';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                        onPressed: _saveEmployee, child: const Text("Saqlash"))
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _positionController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
