import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:savdo_uz/models/employee_model.dart';
import 'package:savdo_uz/services/firestore_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:savdo_uz/widgets/custom_search_bar.dart';
import 'package:savdo_uz/widgets/loading_list_tile.dart';
import 'package:savdo_uz/widgets/error_retry_widget.dart';
import 'package:savdo_uz/widgets/empty_state_widget.dart';
import 'package:savdo_uz/widgets/accessible_icon_button.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xodimlar'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Stack(
              children: [
                Image.asset(
                  'assets/images/xodimlar_bulimi.jpg',
                  fit: BoxFit.cover,
                ),
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      color: Colors.black.withOpacity(0.18),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              CustomSearchBar(
                controller: _searchController,
                onChanged: (query) =>
                    setState(() => _searchQuery = query.toLowerCase()),
                hintText: 'Xodim ismi bo\'yicha qidirish...',
              ),
              Expanded(
                child: StreamBuilder<List<Employee>>(
                  stream: firestoreService.getEmployees(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return ListView.builder(
                        itemCount: 5,
                        itemBuilder: (ctx, i) => const LoadingListTile(),
                      );
                    }
                    if (snapshot.hasError) {
                      return ErrorRetryWidget(
                        errorMessage: 'Xatolik: ${snapshot.error}',
                        onRetry: () => setState(() {}),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('Xodimlar mavjud emas.'));
                    }

                    final allEmployees = snapshot.data!;
                    final filteredEmployees = allEmployees.where((employee) {
                      return employee.name.toLowerCase().contains(_searchQuery);
                    }).toList();

                    if (filteredEmployees.isEmpty) {
                      return const EmptyStateWidget(
                        message: 'Qidiruv natijasi topilmadi.',
                        icon: Icons.search_off,
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredEmployees.length,
                      itemBuilder: (context, index) {
                        final employee = filteredEmployees[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          color: Colors.white.withAlpha((0.78 * 255).toInt()),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundImage: (employee.imageUrl != null &&
                                          employee.imageUrl!.isNotEmpty)
                                      ? CachedNetworkImageProvider(
                                          employee.imageUrl!)
                                      : null,
                                  child: (employee.imageUrl == null ||
                                          employee.imageUrl!.isEmpty)
                                      ? const Icon(Icons.person, size: 32)
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(employee.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16)),
                                      Text(employee.position,
                                          style: const TextStyle(fontSize: 14)),
                                      if (employee.login != null &&
                                          employee.login!.isNotEmpty)
                                        Text('Login: ${employee.login}',
                                            style:
                                                const TextStyle(fontSize: 13)),
                                      if (employee.password != null &&
                                          employee.password!.isNotEmpty)
                                        Text('Parol: ${employee.password}',
                                            style:
                                                const TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AddEditEmployeeScreen(
                                                employee: employee),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: AccessibleIconButton(
        icon: Icons.add,
        semanticLabel: 'Xodim qo‘shish',
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddEditEmployeeScreen(),
              ));
        },
        color: Colors.white,
        size: 28,
      ),
    );
  }
}

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
  late TextEditingController _loginController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee?.name);
    _positionController =
        TextEditingController(text: widget.employee?.position);
    _loginController = TextEditingController(text: widget.employee?.login);
    _passwordController =
        TextEditingController(text: widget.employee?.password);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _positionController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employee == null ? 'Yangi Xodim' : 'Tahrirlash'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 370),
            child: Card(
              color: Colors.white.withOpacity(0.78),
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {},
                        child: CircleAvatar(
                          radius: 38,
                          backgroundColor: Colors.blue.shade50,
                          backgroundImage: widget.employee?.imageUrl != null &&
                                  widget.employee!.imageUrl!.isNotEmpty
                              ? CachedNetworkImageProvider(
                                  widget.employee!.imageUrl!)
                              : null,
                          child: widget.employee?.imageUrl == null ||
                                  widget.employee!.imageUrl!.isEmpty
                              ? const Icon(Icons.camera_alt,
                                  size: 28, color: Colors.blueGrey)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.employee == null
                            ? 'Yuzni ro’yxatdan o’tkazing'
                            : 'Yuz ro’yxatdan o’tgan',
                        style: TextStyle(
                          color: Colors.blueGrey.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Ism-sharifi',
                          prefixIcon: const Icon(Icons.person_outline),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        style: const TextStyle(fontSize: 14),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Ismni kiriting.'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _positionController,
                        decoration: InputDecoration(
                          labelText: 'Lavozimi',
                          prefixIcon: const Icon(Icons.work_outline),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        style: const TextStyle(fontSize: 14),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Lavozimni kiriting.'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _loginController,
                        decoration: InputDecoration(
                          labelText: 'Login',
                          prefixIcon: const Icon(Icons.login),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        style: const TextStyle(fontSize: 14),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Loginni kiriting.'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Parol',
                          prefixIcon: const Icon(Icons.lock_outline),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        style: const TextStyle(fontSize: 14),
                        obscureText: true,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Parolni kiriting.'
                            : null,
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: Text(widget.employee == null
                              ? 'Saqlash'
                              : 'Yangilash'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            elevation: 2,
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              final updatedEmployee = Employee(
                                id: widget.employee?.id ?? '',
                                name: _nameController.text,
                                position: _positionController.text,
                                login: _loginController.text,
                                password: _passwordController.text,
                                imageUrl: widget.employee?.imageUrl,
                              );
                              if (widget.employee == null) {
                                firestoreService.addEmployee(updatedEmployee);
                              } else {
                                firestoreService
                                    .updateEmployee(updatedEmployee);
                              }
                              Navigator.pop(context);
                            }
                          },
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
    );
  }
}
