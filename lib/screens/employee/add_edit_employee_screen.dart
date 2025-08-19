import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:savdo_uz/models/employee_model.dart';
import 'package:savdo_uz/services/face_recognition_service.dart';
import 'package:savdo_uz/services/firestore_service.dart';
import 'package:savdo_uz/widgets/custom_textfield.dart';

class AddEditEmployeeScreen extends StatefulWidget {
  final Employee? employee;

  const AddEditEmployeeScreen({super.key, this.employee});

  @override
  State<AddEditEmployeeScreen> createState() => _AddEditEmployeeScreenState();
}

class _AddEditEmployeeScreenState extends State<AddEditEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _positionController;
  late TextEditingController _phoneController;

  File? _selectedImage;
  String? _existingImageUrl;
  List<double>? _faceData;
  bool _isLoading = false;
  String _statusMessage = 'Rasmni tanlang';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee?.name);
    _positionController =
        TextEditingController(text: widget.employee?.position);
    _phoneController = TextEditingController(text: widget.employee?.phone);
    _existingImageUrl = widget.employee?.imageUrl;
    if (widget.employee?.faceData.isNotEmpty ?? false) {
      _faceData = List<double>.from(widget.employee!.faceData);
      _statusMessage = 'Yuz ma\'lumoti mavjud';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _positionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAndRegisterFace() async {
    final faceRecognitionService = context.read<FaceRecognitionService>();
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (pickedFile == null) return;

    setState(() {
      _selectedImage = File(pickedFile.path);
      _isLoading = true;
      _statusMessage = 'Yuz aniqlanmoqda...';
    });

    final embedding =
        await faceRecognitionService.getEmbeddingFromImageFile(pickedFile);

    if (mounted) {
      if (embedding != null) {
        setState(() {
          _faceData = embedding;
          _isLoading = false;
          _statusMessage = 'Yuz muvaffaqiyatli aniqlandi!';
        });
      } else {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Rasmdan yuz topilmadi. Boshqa rasm tanlang.';
          _selectedImage = null;
        });
      }
    }
  }

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
