import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:savdo_uz/models/customer_model.dart';
import 'package:savdo_uz/services/firestore_service.dart';
import 'package:savdo_uz/screens/customer/add_edit_customer_screen.dart';
import 'package:savdo_uz/widgets/custom_search_bar.dart'; // <-- YANGI IMPORT

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
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
    final currencyFormatter = NumberFormat.currency(
        locale: 'uz_UZ', symbol: 'so\'m', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mijozlar'),
      ),
      body: Column(
        children: [
          CustomSearchBar(
            controller: _searchController,
            onChanged: (query) {
              setState(() {
                _searchQuery = query.toLowerCase();
              });
            },
            hintText: 'Mijoz ismi yoki raqami bo\'yicha...',
          ),
          Expanded(
            child: StreamBuilder<List<Customer>>(
              stream: firestoreService.getCustomers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Xatolik: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Mijozlar mavjud emas.'));
                }

                // Qidiruv natijalarini filtrlash
                final allCustomers = snapshot.data!;
                final filteredCustomers = allCustomers.where((customer) {
                  final name = customer.name.toLowerCase();
                  final phone = customer.phone;
                  return name.contains(_searchQuery) ||
                      phone.contains(_searchQuery);
                }).toList();

                if (filteredCustomers.isEmpty) {
                  return const Center(
                      child: Text('Qidiruv natijasi topilmadi.'));
                }

                return ListView.builder(
                  itemCount: filteredCustomers.length,
                  itemBuilder: (context, index) {
                    final customer = filteredCustomers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(customer.name.isNotEmpty
                              ? customer.name[0].toUpperCase()
                              : 'M'),
                        ),
                        title: Text(customer.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(customer.phone),
                        trailing: Text(
                          currencyFormatter.format(customer.debt),
                          style: TextStyle(
                              color: customer.debt > 0
                                  ? Colors.red
                                  : Colors.green),
                        ),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AddEditCustomerScreen(customer: customer),
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
                builder: (context) => const AddEditCustomerScreen(),
              ));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
