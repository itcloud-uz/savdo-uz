import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'dart:ui';
import '../../models/employee_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/custom_textfield.dart';
import 'package:savdo_uz/l10n/app_localizations.dart';

class AddEditEmployeeScreen extends StatefulWidget {
  const AddEditEmployeeScreen({super.key, this.employee});
  final Employee? employee;

  @override
  State<AddEditEmployeeScreen> createState() => _AddEditEmployeeScreenState();
}

class _AddEditEmployeeScreenState extends State<AddEditEmployeeScreen> {
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

  final _emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.[a-zA-Z]{2,}');
  late TextEditingController _emailController;
  final _phoneRegex =
      RegExp(r'^(\+998|998)?[ -]?(\d{2})[ -]?(\d{3})[ -]?(\d{2})[ -]?(\d{2})');
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _roleController;
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
    _roleController = TextEditingController(text: widget.employee?.role);
    _phoneController = TextEditingController(text: widget.employee?.phone);
    _loginController = TextEditingController(text: widget.employee?.login);
    _passwordController =
        TextEditingController(text: widget.employee?.password);
    _emailController = TextEditingController();
    _existingImageUrl = widget.employee?.imageUrl;
  }

  Future<void> _pickAndRegisterFace() async {
    // TODO: Implement face registration logic if needed
    setState(() {
      _statusMessage = 'Yuz roʻyxatdan oʻtkazildi (demo)';
      _faceData = [1.0]; // Demo value
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
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
          role: _roleController.text.trim(),
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

  Widget _buildImagePickerSheet(BuildContext ctx) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Galereyadan tanlash'),
            onTap: () async {
              // Demo: pick image from gallery
              // You can use image_picker package for real implementation
              Navigator.pop(ctx, null); // Replace with actual file
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Kamera orqali'),
            onTap: () async {
              // Demo: pick image from camera
              Navigator.pop(ctx, null); // Replace with actual file
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.employee == null ? l10n.employeeAdd : l10n.employeeEdit),
        actions: [
          if (widget.employee != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _isLoading ? null : _deleteEmployee,
              tooltip: l10n.delete,
            ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Stack(
              children: [
                Image.asset(
                  'assets/images/Menyular_orqafoni.jpg',
                  fit: BoxFit.cover,
                ),
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      color: Colors.black.withOpacity(0.18),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  color: Colors.white.withOpacity(0.95),
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 22, horizontal: 18),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final picked = await showModalBottomSheet<File?>(
                                context: context,
                                builder: (ctx) => _buildImagePickerSheet(ctx),
                              );
                              if (picked != null) {
                                setState(() {
                                  _selectedImage = picked;
                                  _statusMessage = 'Rasm tanlandi.';
                                });
                              } else {
                                setState(() {
                                  _statusMessage = '';
                                });
                              }
                            },
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: _faceData != null
                                  ? Colors.green.shade100
                                  : Colors.grey.shade200,
                              backgroundImage: _selectedImage != null
                                  ? FileImage(_selectedImage!)
                                  : (_existingImageUrl != null &&
                                          _existingImageUrl!.isNotEmpty)
                                      ? CachedNetworkImageProvider(
                                              _existingImageUrl!)
                                          as ImageProvider<Object>
                                      : null,
                              child: _buildAvatarChild(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.face_retouching_natural),
                            label: const Text('Yuzni ro‘yxatdan o‘tkazish'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade100,
                              foregroundColor: Colors.blue.shade900,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _pickAndRegisterFace,
                          ),
                          const SizedBox(height: 8),
                          Text(_statusMessage,
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black87)),
                          const SizedBox(height: 18),
                          CustomTextField(
                            controller: _nameController,
                            labelText: l10n.name,
                            validator: (value) => value!.trim().isEmpty
                                ? l10n.validationName
                                : null,
                            // Font style for visibility
                            obscureText: false,
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            controller: _roleController,
                            labelText: l10n.role,
                            validator: (value) => value!.trim().isEmpty
                                ? l10n.validationRole
                                : null,
                            obscureText: false,
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            controller: _phoneController,
                            labelText: l10n.phone,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              final v = value?.trim() ?? '';
                              if (v.isEmpty) return l10n.validationPhone;
                              if (!_phoneRegex.hasMatch(v))
                                return l10n.validationPhoneFormat;
                              return null;
                            },
                            obscureText: false,
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            controller: _emailController,
                            labelText: l10n.email,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              final v = value?.trim() ?? '';
                              if (v.isNotEmpty && !_emailRegex.hasMatch(v)) {
                                return l10n.validationEmailFormat;
                              }
                              return null;
                            },
                            obscureText: false,
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            controller: _loginController,
                            labelText: l10n.login,
                            validator: (value) => value!.trim().isEmpty
                                ? l10n.validationLogin
                                : null,
                            obscureText: false,
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            controller: _passwordController,
                            labelText: l10n.password,
                            obscureText: true,
                            validator: (value) => value!.trim().isEmpty
                                ? l10n.validationPassword
                                : null,
                          ),
                          const SizedBox(height: 24),
                          _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.save),
                                    label: Text(l10n.save),
                                    onPressed: _saveEmployee,
                                    style: ElevatedButton.styleFrom(
                                      textStyle: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
