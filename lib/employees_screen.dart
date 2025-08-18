// lib/employees_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:savdo_uz/face_recognition_service.dart';
import 'package:savdo_uz/services/firestore_service.dart';

/// Employee model sinfi
class Employee {
  final String id;
  final String name;
  final String login;
  final String role;
  final String? imageUrl;
  final List<dynamic>? faceEmbedding;

  Employee({
    required this.id,
    required this.name,
    required this.login,
    required this.role,
    this.imageUrl,
    this.faceEmbedding,
  });

  factory Employee.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Employee(
      id: doc.id,
      name: data['fullName'] ?? 'Nomsiz',
      login: data['login'] ?? 'noma\'lum',
      role: data['role'] ?? 'Noma\'lum',
      imageUrl: data['imageUrl'] as String?,
      faceEmbedding: data['faceEmbedding'] as List<dynamic>?,
    );
  }
}

/// Xodimlar sahifasi (list)
class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  void _navigateToAddEditEmployee([Employee? employee]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditEmployeeScreen(employee: employee),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext ctx, Employee emp) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text("O'chirishni tasdiqlash"),
        content: Text("Haqiqatan ham ${emp.name} ni o'chirmoqchimisiz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Bekor qilish"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _firestoreService.deleteEmployee(emp.id,
                    imageUrl: emp.imageUrl);
                if (mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text("O‘chirildi")),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text("Xatolik: $e")),
                  );
                }
              }
            },
            child: const Text("O'chirish"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Xodimlarni Boshqarish"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: "Yangi xodim qo‘shish",
            onPressed: () => _navigateToAddEditEmployee(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getEmployees(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("Maʼlumot yuklab bo‘lmadi"));
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Xodimlar mavjud emas"));
          }

          final employees = snapshot.data!.docs
              .map((doc) => Employee.fromFirestore(doc))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final emp = employees[index];
              return _EmployeeCard(
                employee: emp,
                onEdit: () => _navigateToAddEditEmployee(emp),
                onDelete: () => _showDeleteConfirmation(context, emp),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final Employee employee;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EmployeeCard({
    required this.employee,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey[200],
          backgroundImage: employee.imageUrl != null
              ? CachedNetworkImageProvider(employee.imageUrl!)
              : null,
          child: employee.imageUrl == null
              ? const Icon(Icons.person_outline, color: Colors.grey)
              : null,
        ),
        title: Text(
          employee.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("${employee.role} | Login: ${employee.login}"),
        trailing: PopupMenuButton<String>(
          onSelected: (val) {
            if (val == 'edit') onEdit();
            if (val == 'delete') onDelete();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Tahrirlash')),
            PopupMenuItem(
              value: 'delete',
              child: Text("O'chirish", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Xodim qo‘shish/tahrirlash ekrani
class AddEditEmployeeScreen extends StatefulWidget {
  final Employee? employee;
  const AddEditEmployeeScreen({super.key, this.employee});

  @override
  State<AddEditEmployeeScreen> createState() => _AddEditEmployeeScreenState();
}

class _AddEditEmployeeScreenState extends State<AddEditEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final FaceRecognitionService _faceService = FaceRecognitionService();
  final FirestoreService _firestoreService = FirestoreService();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _loginCtrl;
  late final TextEditingController _passwordCtrl;
  String? _selectedRole;
  final List<String> _roles = ['Sotuvchi', 'Omborchi', 'Admin'];

  XFile? _pickedImage;
  String? _existingUrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.employee?.name);
    _loginCtrl = TextEditingController(text: widget.employee?.login);
    _passwordCtrl = TextEditingController();
    _selectedRole = widget.employee?.role ?? _roles.first;
    _existingUrl = widget.employee?.imageUrl;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _loginCtrl.dispose();
    _passwordCtrl.dispose();
    _faceService.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() => _pickedImage = img);
    }
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.employee == null && _passwordCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Yangi xodim uchun parol kiritilishi shart!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    List<dynamic>? embedding = widget.employee?.faceEmbedding;
    String? imgUrl = _existingUrl;

    try {
      if (_pickedImage != null) {
        final e =
            await _faceService.processImageFileForEmbedding(_pickedImage!);
        if (e == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Yuz topilmadi!"),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _loading = false);
          return;
        }
        embedding = e;
        imgUrl = await _firestoreService
            .uploadEmployeeImage(File(_pickedImage!.path));
      }

      final dataMap = {
        'fullName': _nameCtrl.text,
        'login': _loginCtrl.text,
        'role': _selectedRole,
        'imageUrl': imgUrl,
        'faceEmbedding': embedding,
      };

      if (_passwordCtrl.text.isNotEmpty) {
        dataMap['password'] = _passwordCtrl.text;
      }

      if (widget.employee == null) {
        await _firestoreService.addEmployee(dataMap);
      } else {
        await _firestoreService.updateEmployee(widget.employee!.id, dataMap);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Saqlash muvaffaqiyatli!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Xatolik: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employee == null ? 'Yangi xodim' : 'Tahrirlash'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _pickedImage != null
                          ? FileImage(File(_pickedImage!.path))
                          : (_existingUrl != null
                              ? CachedNetworkImageProvider(_existingUrl!)
                              : null) as ImageProvider<Object>?,
                      child: _pickedImage == null && _existingUrl == null
                          ? Icon(Icons.person,
                              size: 60, color: Colors.grey.shade400)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton.filled(
                        icon: const Icon(Icons.camera_alt),
                        onPressed: _pickImage,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: "To'liq ismi"),
                validator: (value) =>
                    (value == null || value.isEmpty) ? "Ismni kiriting" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _loginCtrl,
                decoration: const InputDecoration(labelText: "Login"),
                validator: (value) => (value == null || value.isEmpty)
                    ? "Loginni kiriting"
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Parol",
                  hintText: widget.employee != null
                      ? "O‘zgartirish uchun terningiz"
                      : null,
                ),
                validator: (value) {
                  if (widget.employee == null &&
                      (value == null || value.isEmpty)) {
                    return "Parolni kiriting";
                  }
                  if (value != null && value.isNotEmpty && value.length < 6) {
                    return "Kamida 6 ta belgi";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: "Roli"),
                items: _roles
                    .map((role) =>
                        DropdownMenuItem(value: role, child: Text(role)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedRole = value);
                },
              ),
              const SizedBox(height: 32),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _onSave,
                      icon: const Icon(Icons.save_alt_outlined),
                      label: const Text("Saqlash"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
