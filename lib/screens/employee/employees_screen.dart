import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:savdo_uz/models/employee_model.dart';
import 'package:savdo_uz/services/firestore_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final TextEditingController _searchController = TextEditingController();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Yangilash',
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
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.22),
                            Colors.blueGrey.withOpacity(0.12)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Ism, login yoki telefon bo'yicha qidirish...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.85),
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Employee>>(
                  stream: firestoreService.getEmployees(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Xatolik: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('Xodimlar mavjud emas.'));
                    }

                    final allEmployees = snapshot.data!;
                    final filteredEmployees = allEmployees.where((employee) {
                      final query = _searchQuery;
                      return employee.name.toLowerCase().contains(query) ||
                          (employee.login?.toLowerCase().contains(query) ??
                              false) ||
                          (employee.phone?.toLowerCase().contains(query) ??
                              false);
                    }).toList();

                    if (filteredEmployees.isEmpty) {
                      return const Center(
                          child: Text('Qidiruv natijasi topilmadi.'));
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 0.78,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: filteredEmployees.length,
                      itemBuilder: (context, index) {
                        final employee = filteredEmployees[index];
                        return Card(
                          color: Colors.white,
                          elevation: 8,
                          shadowColor: Colors.blueGrey.withOpacity(0.18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AddEditEmployeeScreen(employee: employee),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 30,
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
                                            size: 34, color: Colors.blue)
                                        : null,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    employee.name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                      color: Colors.black,
                                      letterSpacing: 0.2,
                                      shadows: [
                                        Shadow(
                                            color: Colors.white, blurRadius: 2),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    employee.role,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: Colors.blueGrey,
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
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.blueAccent),
                                        tooltip: 'Tahrirlash',
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
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            color: Colors.redAccent),
                                        tooltip: 'O\'chirish',
                                        onPressed: () async {
                                          final confirm =
                                              await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text(
                                                  "O'chirishni tasdiqlang"),
                                              content: Text(
                                                  "${employee.name} nomli xodimni o'chirishga ishonchingiz komilmi?"),
                                              actions: [
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            ctx, false),
                                                    child: const Text(
                                                        'Bekor qilish')),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, true),
                                                  style: TextButton.styleFrom(
                                                      foregroundColor:
                                                          Colors.red),
                                                  child:
                                                      const Text("O'chirish"),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            await firestoreService
                                                .deleteEmployee(employee.id!);
                                            setState(() {});
                                          }
                                        },
                                      ),
                                    ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditEmployeeScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Yangi xodim',
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
