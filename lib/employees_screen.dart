import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Xodim ma'lumotlari uchun model
class Employee {
  final String id;
  final String name;
  final String role;
  final String pinCode;
  final String? imageUrl;

  Employee({
    required this.id,
    required this.name,
    required this.role,
    required this.pinCode,
    this.imageUrl,
  });

  factory Employee.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Employee(
      id: doc.id,
      name: data['fullName'] ?? 'Nomsiz',
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

  // Xodim qo'shish/tahrirlash oynasini ochish
  void _showEmployeeDialog({Employee? employee}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: employee?.name);
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
                        validator: (value) =>
                            value!.isEmpty ? "Ismni kiriting" : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedRole,
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
                        validator: (value) => value!.length < 4
                            ? "PIN-kod 4 xonali bo'lishi kerak"
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Bekor qilish")),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      try {
                        String? imageUrl;
                        if (pickedImage != null) {
                          final ref = FirebaseStorage.instance
                              .ref()
                              .child('user_images')
                              .child('${DateTime.now().toIso8601String()}.jpg');
                          await ref.putFile(File(pickedImage!.path));
                          imageUrl = await ref.getDownloadURL();
                        } else {
                          imageUrl = employee?.imageUrl;
                        }

                        if (employee == null) {
                          await _usersCollection.add({
                            'fullName': nameController.text,
                            'role': selectedRole,
                            'pinCode': pinController.text,
                            'imageUrl': imageUrl,
                            'createdAt': Timestamp.now(),
                          });
                        } else {
                          await _usersCollection.doc(employee.id).update({
                            'fullName': nameController.text,
                            'role': selectedRole,
                            'pinCode': pinController.text,
                            'imageUrl': imageUrl,
                          });
                        }
                        if (mounted) Navigator.pop(context);
                      } catch (e) {
                        if (mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Xatolik: $e")));
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
              onPressed: () => Navigator.pop(context),
              child: const Text("Bekor qilish")),
          ElevatedButton(
            onPressed: () async {
              try {
                if (employee.imageUrl != null) {
                  await FirebaseStorage.instance
                      .refFromURL(employee.imageUrl!)
                      .delete();
                }
                await _usersCollection.doc(employee.id).delete();
                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (mounted)
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
              child: employee.imageUrl == null
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
