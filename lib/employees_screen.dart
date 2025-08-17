import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:savdo_uz/face_recognition_service.dart'; // Buni o'zgartirmang

// --- Model Class ---
// Ma'lumotlar bazasi tuzilmasiga mos keladigan sinf.
// "pinCode" -> "password" ga o'zgartirildi.
class Employee {
  final String id;
  final String name;
  final String login;
  final String role;
  final String? imageUrl;
  final List? faceEmbedding; // Yuz ma'lumotlari uchun maydon

  Employee({
    required this.id,
    required this.name,
    required this.login,
    required this.role,
    this.imageUrl,
    this.faceEmbedding,
  });

  factory Employee.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Employee(
      id: doc.id,
      name: data['fullName'] ?? 'Nomsiz',
      login: data['login'] ?? 'noma\'lum',
      role: data['role'] ?? 'Noma\'lum',
      imageUrl: data['imageUrl'],
      faceEmbedding: data['faceEmbedding'],
    );
  }
}

// --- Asosiy Ekran ---
// Barcha xodimlar ro'yxatini ko'rsatadi.
class EmployeesScreen extends StatelessWidget {
  const EmployeesScreen({super.key});

  void _navigateToAddEmployee(BuildContext context, {Employee? employee}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditEmployeeScreen(employee: employee),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Orqaga qaytish tugmasi va sarlavha uchun AppBar qo'shildi.
      appBar: AppBar(
        title: const Text("Xodimlarni Boshqarish"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: "Yangi xodim qo'shish",
            onPressed: () => _navigateToAddEmployee(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
                child: Text("Ma'lumotlarni yuklashda xatolik yuz berdi."));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Xodimlar mavjud emas."));
          }

          final employees = snapshot.data!.docs
              .map((doc) => Employee.fromFirestore(doc))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: employees.length,
            itemBuilder: (context, index) {
              return _EmployeeCard(
                employee: employees[index],
                onEdit: () =>
                    _navigateToAddEmployee(context, employee: employees[index]),
                onDelete: () =>
                    _showDeleteConfirmationDialog(context, employees[index]),
              );
            },
          );
        },
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, Employee employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("O'chirishni tasdiqlash"),
        content: Text("Haqiqatan ham ${employee.name}ni o'chirmoqchimisiz?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Bekor qilish")),
          ElevatedButton(
            onPressed: () async {
              try {
                final navigator = Navigator.of(context);
                // Rasmni Storage'dan o'chirish
                if (employee.imageUrl != null) {
                  await FirebaseStorage.instance
                      .refFromURL(employee.imageUrl!)
                      .delete();
                }
                // Ma'lumotni Firestore'dan o'chirish
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(employee.id)
                    .delete();
                navigator.pop();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("O'chirishda xatolik: $e")));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("O'chirish"),
          ),
        ],
      ),
    );
  }
}

// --- Xodim Kartochkasi Vidjeti ---
// Kodni toza saqlash uchun alohida vidjet.
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
        title: Text(employee.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${employee.role} | Login: ${employee.login}"),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Tahrirlash')),
            const PopupMenuItem(
                value: 'delete',
                child: Text('O\'chirish', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }
}

// --- XODIM QO'SHISH / TAHRIRLASH SAHIFASI ---
// Dialog o'rniga ishlatiladigan yangi, toza sahifa.
class AddEditEmployeeScreen extends StatefulWidget {
  final Employee? employee;

  const AddEditEmployeeScreen({super.key, this.employee});

  @override
  State<AddEditEmployeeScreen> createState() => _AddEditEmployeeScreenState();
}

class _AddEditEmployeeScreenState extends State<AddEditEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _faceService = FaceRecognitionService();

  late final TextEditingController _nameController;
  late final TextEditingController _loginController;
  late final TextEditingController _passwordController;
  String? _selectedRole;
  final _roles = ['Sotuvchi', 'Omborchi', 'Admin'];

  XFile? _pickedImage;
  String? _existingImageUrl;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee?.name);
    _loginController = TextEditingController(text: widget.employee?.login);
    _passwordController =
        TextEditingController(); // Parol har doim bo'sh boshlanadi
    _selectedRole = widget.employee?.role ?? 'Sotuvchi';
    _existingImageUrl = widget.employee?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    _faceService.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() {
        _pickedImage = image;
      });
    }
  }

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    // Tahrirlash rejimida parol kiritilmasa, majburiy emas
    if (widget.employee == null && _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Yangi xodim uchun parol kiritilishi shart!"),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _isProcessing = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      String? imageUrl = _existingImageUrl;
      List? faceEmbedding = widget.employee?.faceEmbedding;

      // 1. Agar yangi rasm tanlansa, uni qayta ishlaymiz
      if (_pickedImage != null) {
        // Yuzni topish va embedding olish
        faceEmbedding =
            await _faceService.processImageFileForEmbedding(_pickedImage!);
        if (faceEmbedding == null) {
          messenger.showSnackBar(const SnackBar(
            content: Text("Rasmdan yuz topilmadi! Boshqa rasm tanlang."),
            backgroundColor: Colors.red,
          ));
          setState(() => _isProcessing = false);
          return;
        }

        // Rasmni Storage'ga yuklash
        final ref = FirebaseStorage.instance
            .ref()
            .child('user_images/${DateTime.now().toIso8601String()}.jpg');
        await ref.putFile(File(_pickedImage!.path));
        imageUrl = await ref.getDownloadURL();
      }

      // 2. Ma'lumotlarni tayyorlash
      final userData = <String, dynamic>{
        'fullName': _nameController.text,
        'login': _loginController.text,
        'role': _selectedRole,
        'imageUrl': imageUrl,
        'faceEmbedding': faceEmbedding,
      };

      // Agar parol kiritilgan bo'lsa, uni qo'shamiz (heshlash tavsiya etiladi)
      if (_passwordController.text.isNotEmpty) {
        userData['password'] = _passwordController.text;
      }

      // 3. Firestore'ga saqlash
      if (widget.employee == null) {
        userData['createdAt'] = Timestamp.now();
        await FirebaseFirestore.instance.collection('users').add(userData);
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.employee!.id)
            .update(userData);
      }

      messenger.showSnackBar(
          const SnackBar(content: Text("Muvaffaqiyatli saqlandi!")));
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Xatolik yuz berdi: $e")));
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employee == null ? 'Yangi Xodim' : 'Tahrirlash'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Rasm tanlash qismi
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _pickedImage != null
                          ? FileImage(File(_pickedImage!.path))
                          : (_existingImageUrl != null
                              ? CachedNetworkImageProvider(_existingImageUrl!)
                              : null) as ImageProvider?,
                      child: _pickedImage == null && _existingImageUrl == null
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

              // Ism-familiya maydoni
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "To'liq ismi"),
                validator: (value) =>
                    (value == null || value.isEmpty) ? "Ismni kiriting" : null,
              ),
              const SizedBox(height: 16),

              // Login maydoni
              TextFormField(
                controller: _loginController,
                decoration: const InputDecoration(labelText: "Login"),
                validator: (value) => (value == null || value.isEmpty)
                    ? "Loginni kiriting"
                    : null,
              ),
              const SizedBox(height: 16),

              // Parol maydoni ("pin-kod" o'rniga)
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                    labelText: "Parol",
                    hintText: widget.employee != null
                        ? "O'zgartirish uchun kiriting"
                        : null),
                validator: (value) {
                  // Yangi xodim uchun parol majburiy
                  if (widget.employee == null &&
                      (value == null || value.isEmpty)) {
                    return "Parolni kiriting";
                  }
                  // Agar parol kiritilsa, kamida 6ta belgi bo'lishi kerak
                  if (value != null && value.isNotEmpty && value.length < 6) {
                    return "Parol kamida 6 belgidan iborat bo'lishi kerak";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Rolni tanlash
              DropdownButtonFormField<String>(
                value: _selectedRole,
                items: _roles
                    .map((role) =>
                        DropdownMenuItem(value: role, child: Text(role)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedRole = value!),
                decoration: const InputDecoration(labelText: "Roli"),
              ),
              const SizedBox(height: 32),

              // Saqlash tugmasi
              _isProcessing
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _saveEmployee,
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
