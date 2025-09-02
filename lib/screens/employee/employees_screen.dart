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
                    // 5x5 grid ko'rinishi
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        childAspectRatio: 0.78,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: filteredEmployees.length,
                      itemBuilder: (context, index) {
                        final employee = filteredEmployees[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AddEditEmployeeScreen(employee: employee),
                              ),
                            );
                          },
                          child: Card(
                            color: Colors.white.withOpacity(0.55),
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundImage:
                                        (employee.imageUrl != null &&
                                                employee.imageUrl!.isNotEmpty)
                                            ? CachedNetworkImageProvider(
                                                employee.imageUrl!)
                                            : null,
                                    backgroundColor: Colors.blue.shade50,
                                    child: (employee.imageUrl == null ||
                                            employee.imageUrl!.isEmpty)
                                        ? const Icon(Icons.person,
                                            size: 32, color: Colors.blue)
                                        : null,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    employee.name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 17,
                                      color: Colors.black,
                                      letterSpacing: 0.2,
                                      shadows: [
                                        Shadow(
                                          color: Colors.white,
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    employee.role,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: Colors.black87,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                  if (employee.login != null &&
                                      employee.login!.isNotEmpty)
                                    Text(
                                      'Login: ${employee.login}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  if (employee.phone != null &&
                                      employee.phone!.isNotEmpty)
                                    Text(
                                      employee.phone!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                    ),
                                ],
                              ),
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
  late TextEditingController _loginController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee?.name);
    _loginController = TextEditingController(text: widget.employee?.login);
    _passwordController =
        TextEditingController(text: widget.employee?.password);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final firestoreService = context.read<FirestoreService>();
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
                        onTap: () async {
                          // TODO: Implement image picker and face registration
                        },
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
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Ism',
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Ism majburiy'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _loginController,
                        decoration: const InputDecoration(
                          labelText: 'Login',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Parol',
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            // TODO: Save logic
                          }
                        },
                        child: Text(
                            widget.employee == null ? 'Saqlash' : 'Yangilash'),
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
