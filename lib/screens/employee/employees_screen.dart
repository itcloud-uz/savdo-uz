import 'package.flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:savdo_uz/models/employee_model.dart';
import 'package:savdo_uz/services/firestore_service.dart';
import 'package:savdo_uz/screens/employee/add_edit_employee_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EmployeesScreen extends StatelessWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xodimlar'),
      ),
      body: StreamBuilder<List<Employee>>(
        stream: firestoreService.getEmployees(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Xatolik yuz berdi: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Xodimlar mavjud emas.\nQo\'shish uchun "+" tugmasini bosing.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final employees = snapshot.data!;

          return ListView.builder(
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final employee = employees[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey.shade200,
                    // Agar xodimning rasmi bo'lsa ko'rsatadi, bo'lmasa standart ikonka
                    backgroundImage: (employee.imageUrl != null &&
                            employee.imageUrl!.isNotEmpty)
                        ? CachedNetworkImageProvider(employee.imageUrl!)
                        : null,
                    child: (employee.imageUrl == null ||
                            employee.imageUrl!.isEmpty)
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                  title: Text(employee.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(employee.position),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Tahrirlash ekraniga o'tish
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddEditEmployeeScreen(employee: employee),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Yangi xodim qo'shish ekraniga o'tish
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditEmployeeScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Yangi xodim qo\'shish',
      ),
    );
  }
}
