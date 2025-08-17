// lib/employees_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:savdo_uz/face_recognition_service.dart';

class Employee {
  final String id;
  final String name;
  final String login;
  final String role;
  final String pinCode;
  final String? imageUrl;

  Employee({
    required this.id,
    required this.name,
    required this.login,
    required this.role,
    required this.pinCode,
    this.imageUrl,
  });

  factory Employee.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Employee(
      id: doc.id,
      name: data['fullName'] ?? 'Nomsiz',
      login: data['login'] ?? 'noma\'lum',
      role: data['role'] ?? 'Noma\'lum',
      pinCode: data['pinCode'] ?? '****',
      imageUrl: data['imageUrl'],
    );
  }
}

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final _usersCollection = FirebaseFirestore.instance.collection('users');
  final FaceRecognitionService _faceRecognitionService =
      FaceRecognitionService();
  bool _isProcessing = false;

  @override
  void dispose() {
    _faceRecognitionService.dispose();
    super.dispose();
  }

  void _showEmployeeDialog({Employee? employee}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: employee?.name);
    final loginController = TextEditingController(text: employee?.login);
    final pinController = TextEditingController(text: employee?.pinCode);
    String selectedRole = employee?.role ?? 'Sotuvchi';
    final roles = ['Sotuvchi', 'Omborchi', 'Admin'];
    XFile? pickedImage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(employee == null
                  ? "Yangi xodim qo'shish"
                  : "Xodimni tahrirlash"),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () async {
                          final ImagePicker picker = ImagePicker();
                          final XFile? image = await picker.pickImage(
                              source: ImageSource.gallery);
                          if (image != null) {
                            setDialogState(() => pickedImage = image);
                          }
                        },
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: pickedImage != null
                              ? FileImage(File(pickedImage!.path))
                              : (employee?.imageUrl != null
                                  ? CachedNetworkImageProvider(
                                      employee!.imageUrl!)
                                  : null) as ImageProvider?,
                          child:
                              pickedImage == null && employee?.imageUrl == null
                                  ? const Icon(Icons.add_a_photo,
                                      size: 30, color: Colors.grey)
                                  : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text("Rasmni tanlang"),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameController,
                        decoration:
                            const InputDecoration(labelText: "To'liq ismi"),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Ismni kiriting";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: loginController,
                        decoration: const InputDecoration(labelText: "Login"),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Loginni kiriting";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: selectedRole, // ✅ TUZATILDI
                        items: roles
                            .map((role) => DropdownMenuItem(
                                value: role, child: Text(role)))
                            .toList(),
                        onChanged: (value) => selectedRole = value!,
                        decoration: const InputDecoration(labelText: "Roli"),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: pinController,
                        decoration: const InputDecoration(
                            labelText: "PIN-kod (4 xonali)"),
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        validator: (value) {
                          if (value == null || value.length < 4) {
                            return "PIN-kod 4 xonali bo'lishi kerak";
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                    onPressed:
                        _isProcessing ? null : () => Navigator.pop(context),
                    child: const Text("Bekor qilish")),
                _isProcessing
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      )
                    : ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            setDialogState(() => _isProcessing = true);

                            final navigator = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);

                            try {
                              String? imageUrl = employee?.imageUrl;
                              List? faceEmbedding;

                              if (pickedImage != null) {
                                faceEmbedding = await _faceRecognitionService
                                    .processImageFileForEmbedding(pickedImage!);

                                if (faceEmbedding == null) {
                                  messenger.showSnackBar(const SnackBar(
                                      content: Text(
                                          "Rasmdan yuz topilmadi! Boshqa rasm tanlang."),
                                      backgroundColor: Colors.red));
                                  setDialogState(() => _isProcessing = false);
                                  return;
                                }

                                final ref = FirebaseStorage.instance
                                    .ref()
                                    .child('user_images')
                                    .child(
                                        '${DateTime.now().toIso8601String()}.jpg');
                                await ref.putFile(File(pickedImage!.path));
                                imageUrl = await ref.getDownloadURL();
                              }

                              final userData = {
                                'fullName': nameController.text,
                                'login': loginController.text,
                                'role': selectedRole,
                                'pinCode': pinController.text,
                                'imageUrl': imageUrl,
                                if (faceEmbedding != null)
                                  'faceEmbedding': faceEmbedding,
                              };

                              if (employee == null) {
                                userData['createdAt'] = Timestamp.now();
                                await _usersCollection.add(userData);
                              } else {
                                await _usersCollection
                                    .doc(employee.id)
                                    .update(userData);
                              }

                              if (!mounted) return;
                              navigator.pop();
                            } catch (e) {
                              if (!mounted) return;
                              messenger.showSnackBar(
                                  SnackBar(content: Text("Xatolik: $e")));
                            } finally {
                              setDialogState(() => _isProcessing = false);
                            }
                          }
                        },
                        child: const Text("Saqlash"),
                      ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(Employee employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("O'chirishni tasdiqlash"),
        content: Text("Haqiqatan ham ${employee.name}ni o'chirmoqchimisiz?"),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Bekor qilish")),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              try {
                if (employee.imageUrl != null) {
                  await FirebaseStorage.instance
                      .refFromURL(employee.imageUrl!)
                      .delete();
                }
                await _usersCollection.doc(employee.id).delete();

                if (!mounted) return;
                navigator.pop();
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Xodimlarni Boshqarish",
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _showEmployeeDialog(),
                icon: const Icon(Icons.add),
                label: const Text("Xodim qo'shish"),
              ),
            ],
          ),
          const SizedBox(height: 24),
          StreamBuilder<QuerySnapshot>(
            stream: _usersCollection.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Xodimlar mavjud emas."));
              }
              final employees = snapshot.data!.docs
                  .map((doc) => Employee.fromFirestore(doc))
                  .toList();
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 350,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 3,
                ),
                itemCount: employees.length,
                itemBuilder: (context, index) {
                  return _buildEmployeeCard(employees[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(Employee employee) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[200],
              backgroundImage: employee.imageUrl != null
                  ? CachedNetworkImageProvider(employee.imageUrl!)
                  : null,
              child: employee.imageUrl == null && employee.name.length >= 2
                  ? Text(employee.name.substring(0, 2).toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold))
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(employee.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(employee.login,
                      style: const TextStyle(color: Colors.blueGrey)),
                  Text(employee.role,
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showEmployeeDialog(employee: employee);
                } else if (value == 'delete') {
                  _showDeleteConfirmationDialog(employee);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Tahrirlash')),
                const PopupMenuItem(
                    value: 'delete',
                    child: Text('O\'chirish',
                        style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
