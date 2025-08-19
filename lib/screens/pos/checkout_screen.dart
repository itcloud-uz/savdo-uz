import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:savdo_uz/models/customer_model.dart';
import 'package:savdo_uz/models/sale_model.dart';
import 'package:savdo_uz/providers/cart_provider.dart';
import 'package:savdo_uz/services/firestore_service.dart';
import 'package:savdo_uz/screens/pos/receipt_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  PaymentType _paymentType = PaymentType.cash;
  Customer? _selectedCustomer;
  bool _isLoading = false;

  Future<void> _completeSale() async {
    if (_paymentType == PaymentType.debt && _selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Qarzga yozish uchun mijozni tanlang!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final cart = context.read<CartProvider>();
    final firestoreService = context.read<FirestoreService>();

    try {
      final newSale = Sale(
        saleId: '${DateTime.now().millisecondsSinceEpoch}', // noyob ID
        totalAmount: cart.totalPrice,
        timestamp: DateTime.now(),
        items: cart.items,
        paymentType: _paymentType.name,
        customerId: _selectedCustomer?.id,
        customerName: _selectedCustomer?.name,
      );

      await firestoreService.addSale(newSale);

      if (mounted) {
        cart.clearCart();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => ReceiptScreen(sale: newSale)),
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Xatolik: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('To\'lovni Yakunlash'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // To'lov turini tanlash
            SegmentedButton<PaymentType>(
              segments: const [
                ButtonSegment(
                    value: PaymentType.cash,
                    label: Text('Naqd'),
                    icon: Icon(Icons.money)),
                ButtonSegment(
                    value: PaymentType.card,
                    label: Text('Karta'),
                    icon: Icon(Icons.credit_card)),
                ButtonSegment(
                    value: PaymentType.debt,
                    label: Text('Qarzga'),
                    icon: Icon(Icons.book)),
              ],
              selected: {_paymentType},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _paymentType = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 24),
            // Agar "Qarzga" tanlansa, mijozlar ro'yxati chiqadi
            if (_paymentType == PaymentType.debt) ...[
              StreamBuilder<List<Customer>>(
                stream: firestoreService.getCustomers(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final customers = snapshot.data!;
                  return DropdownButtonFormField<Customer>(
                    initialValue:
                        _selectedCustomer, // 🔥 value o‘rniga initialValue
                    hint: const Text('Mijozni tanlang'),
                    isExpanded: true,
                    items: customers.map((customer) {
                      return DropdownMenuItem(
                        value: customer,
                        child: Text(customer.name),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedCustomer = value),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 32),
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _completeSale,
                      child: const Text('Sotuvni Yakunlash'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
