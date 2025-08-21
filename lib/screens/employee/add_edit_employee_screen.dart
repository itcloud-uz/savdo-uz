import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../../models/employee_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/custom_textfield.dart';

class AddEditEmployeeScreen extends StatefulWidget {
  const AddEditEmployeeScreen({super.key, this.employee});
  final Employee? employee;

  @override
  State<AddEditEmployeeScreen> createState() => _AddEditEmployeeScreenState();
}

class _AddEditEmployeeScreenState extends State<AddEditEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _positionController;
  late TextEditingController _phoneController;
  late TextEditingController _loginController;
  late TextEditingController _passwordController;
  String? _existingImageUrl;
  bool _isLoading = false;
  String _statusMessage = '';
  List<double>? _faceData;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee?.name);
    _positionController =
        TextEditingController(text: widget.employee?.position);
    _phoneController = TextEditingController(text: widget.employee?.phone);
    _loginController = TextEditingController(text: widget.employee?.login);
    _passwordController =
        TextEditingController(text: widget.employee?.password);
    _existingImageUrl = widget.employee?.imageUrl;
    _faceData = widget.employee?.faceData != null
        ? widget.employee!.faceData.map((e) => e as double).toList()
        : null;
  }

  Future<void> _pickAndRegisterFace() async {}

  @override
  void dispose() {
    _nameController.dispose();
    _positionController.dispose();
    _phoneController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ...existing code...

  Future<void> _saveEmployee() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final firestoreService = context.read<FirestoreService>();
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);

      try {
        String? imageUrl = _existingImageUrl;
        if (_selectedImage != null) {
          imageUrl =
              await firestoreService.uploadEmployeeImage(_selectedImage!);
        }

        final employee = Employee(
          id: widget.employee?.id,
          name: _nameController.text.trim(),
          position: _positionController.text.trim(),
          phone: _phoneController.text.trim(),
          login: _loginController.text.trim(),
          password: _passwordController.text.trim(),
          imageUrl: imageUrl,
          faceData: _faceData ?? [],
        );

        if (widget.employee == null) {
          await firestoreService.addEmployee(employee);
        } else {
          await firestoreService.updateEmployee(employee);
        }

        navigator.pop();
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text("Xatolik: $e")));
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _deleteEmployee() async {
    if (widget.employee == null) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final firestoreService = context.read<FirestoreService>();

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('O\'chirishni tasdiqlang'),
        content: Text(
            '${widget.employee!.name} nomli xodimni o\'chirishga ishonchingiz komilmi?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Bekor qilish')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      setState(() => _isLoading = true);
      try {
        await firestoreService.deleteEmployee(widget.employee!.id!);
        navigator.pop();
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text("Xatolik: $e")));
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employee == null ? 'Yangi Xodim' : 'Tahrirlash'),
        actions: [
          if (widget.employee != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _isLoading ? null : _deleteEmployee,
              tooltip: 'O\'chirish',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickAndRegisterFace,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: _faceData != null
                      ? Colors.green.shade100
                      : Colors.grey.shade200,
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!)
                      : (_existingImageUrl != null &&
                              _existingImageUrl!.isNotEmpty)
                          ? CachedNetworkImageProvider(_existingImageUrl!)
                          : null as ImageProvider?,
                  child: _buildAvatarChild(),
                ),
              ),
              const SizedBox(height: 8),
              Text(_statusMessage),
              const SizedBox(height: 24),
              CustomTextField(
                controller: _nameController,
                labelText: 'Ism-sharifi',
                validator: (value) =>
                    value!.trim().isEmpty ? 'Ismni kiriting' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _positionController,
                labelText: 'Lavozimi',
                validator: (value) =>
                    value!.trim().isEmpty ? 'Lavozimni kiriting' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _phoneController,
                labelText: 'Telefon raqami',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _loginController,
                labelText: 'Login',
                validator: (value) =>
                    value!.trim().isEmpty ? 'Login kiriting' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passwordController,
                labelText: 'Parol',
                obscureText: true,
                validator: (value) =>
                    value!.trim().isEmpty ? 'Parol kiriting' : null,
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveEmployee,
                        child: const Text('Saqlash'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarChild() {
    if (_isLoading) {
      return const CircularProgressIndicator();
    }
    if (_faceData != null) {
      return const Icon(Icons.check_circle, size: 40, color: Colors.green);
    }
    if (_selectedImage == null &&
        (_existingImageUrl == null || _existingImageUrl!.isEmpty)) {
      return const Icon(Icons.camera_alt, size: 40, color: Colors.grey);
    }
    return const SizedBox.shrink();
  }
}
