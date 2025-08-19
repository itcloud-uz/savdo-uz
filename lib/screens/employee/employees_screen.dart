import 'package:flutter/material.dart'; // <-- XATO TUZATILDI
import 'package:provider/provider.dart';
import 'package:savdo_uz/models/employee_model.dart';
import 'package:savdo_uz/services/firestore_service.dart';
import 'package:savdo_uz/screens/employee/add_edit_employee_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:savdo_uz/widgets/custom_search_bar.dart';
import 'package:savdo_uz/widgets/loading_list_tile.dart';

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
      body: Column(
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
                  return Center(child: Text('Xatolik: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Xodimlar mavjud emas.'));
                }

                final allEmployees = snapshot.data!;
                final filteredEmployees = allEmployees.where((employee) {
                  return employee.name.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filteredEmployees.isEmpty) {
                  return const Center(
                      child: Text('Qidiruv natijasi topilmadi.'));
                }

                return ListView.builder(
                  itemCount: filteredEmployees.length,
                  itemBuilder: (context, index) {
                    final employee = filteredEmployees[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: (employee.imageUrl != null &&
                                  employee.imageUrl!.isNotEmpty)
                              ? CachedNetworkImageProvider(employee.imageUrl!)
                              : null,
                          child: (employee.imageUrl == null ||
                                  employee.imageUrl!.isEmpty)
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(employee.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(employee.position),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AddEditEmployeeScreen(employee: employee),
                              ));
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddEditEmployeeScreen(),
              ));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
