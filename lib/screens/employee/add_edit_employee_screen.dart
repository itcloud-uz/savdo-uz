import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:savdo_uz/models/employee_model.dart';
import 'package:savdo_uz/services/firestore_service.dart';
import 'package:savdo_uz/widgets/custom_textfield.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AddEditEmployeeScreen extends StatefulWidget {
  final Employee? employee; // Tahrirlash uchun xodim ma'lumotlari

  const AddEditEmployeeScreen({super.key, this.employee});

  @override
  State<AddEditEmployeeScreen> createState() => _AddEditEmployeeScreenState();
}

class _AddEditEmployeeScreenState extends State<AddEditEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _positionController;
  late TextEditingController _phoneController;

  File? _imageFile;
  String? _networkImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee?.name);
    _positionController =
        TextEditingController(text: widget.employee?.position);
    _phoneController = TextEditingController(text: widget.employee?.phone);
    _networkImageUrl = widget.employee?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _positionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final firestoreService = context.read<FirestoreService>();
    final pickedFile = await firestoreService.pickImage();
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveEmployee() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final firestoreService = context.read<FirestoreService>();
      String? imageUrl = _networkImageUrl;

      try {
        // Agar yangi rasm tanlangan bo'lsa, uni yuklash
        if (_imageFile != null) {
          imageUrl = await firestoreService.uploadEmployeeImage(_imageFile!);
        }

        final employee = Employee(
          id: widget.employee?.id,
          name: _nameController.text,
          position: _positionController.text,
          phone: _phoneController.text,
          imageUrl: imageUrl,
          // faceEmbedding hozircha null, keyingi bosqichda qo'shamiz
        );

        if (widget.employee == null) {
          await firestoreService.addEmployee(employee);
        } else {
          await firestoreService.updateEmployee(employee);
        }

        if (mounted) {
          Navigator.pop(context);
        }
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

  Future<void> _deleteEmployee() async {
    if (widget.employee == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('O\'chirishni tasdiqlang'),
        content: Text(
            '${widget.employee!.name} ismli xodimni o\'chirishga ishonchingiz komilmi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('O\'chirish'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      setState(() {
        _isLoading = true;
      });
      try {
        final firestoreService = context.read<FirestoreService>();
        await firestoreService.deleteEmployee(widget.employee!);
        if (mounted) {
          Navigator.pop(context);
        }
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
              _buildImagePicker(),
              const SizedBox(height: 24),
              CustomTextField(
                controller: _nameController,
                labelText: 'Ism-sharifi',
                validator: (value) => value!.isEmpty ? 'Ismni kiriting' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _positionController,
                labelText: 'Lavozimi',
                validator: (value) =>
                    value!.isEmpty ? 'Lavozimni kiriting' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _phoneController,
                labelText: 'Telefon raqami',
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value!.isEmpty ? 'Raqamni kiriting' : null,
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

  Widget _buildImagePicker() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: _imageFile != null
                ? FileImage(_imageFile!)
                : (_networkImageUrl != null && _networkImageUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(_networkImageUrl!)
                    : null) as ImageProvider?,
            child: (_imageFile == null &&
                    (_networkImageUrl == null || _networkImageUrl!.isEmpty))
                ? const Icon(Icons.person, size: 60, color: Colors.grey)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(context).primaryColor,
              child: IconButton(
                icon:
                    const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                onPressed: _pickImage,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
