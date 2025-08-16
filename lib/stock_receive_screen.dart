import 'package:flutter/material.dart';
// Yordamchi: Firebase Firestore paketini import qilamiz
import 'package:cloud_firestore/cloud_firestore.dart';

class StockReceiveScreen extends StatefulWidget {
  const StockReceiveScreen({super.key});

  @override
  State<StockReceiveScreen> createState() => _StockReceiveScreenState();
}

class _StockReceiveScreenState extends State<StockReceiveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();

  String _selectedUnit = 'dona';
  final List<String> _units = ['dona', 'kg', 'litr', 'metr'];
  bool _isLoading = false; // Yuklanish holatini kuzatish uchun

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    super.dispose();
  }

  // Ma'lumotlarni Firebase'ga yuborish funksiyasi
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Yuklanishni boshlaymiz
      });

      try {
        // Firestore'dagi 'products' nomli koleksiyaga ulanamiz
        final collection = FirebaseFirestore.instance.collection('products');

        // Yangi mahsulot ma'lumotlarini tayyorlaymiz
        await collection.add({
          'name': _nameController.text,
          'unit': _selectedUnit,
          'quantity': double.tryParse(_quantityController.text) ?? 0,
          'costPrice': double.tryParse(_costPriceController.text) ?? 0,
          'sellingPrice': double.tryParse(_sellingPriceController.text) ?? 0,
          'createdAt': Timestamp.now(), // Saqlangan vaqt
        });

        // Muvaffaqiyatli saqlanganda xabar ko'rsatamiz
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Mahsulot omborga muvaffaqiyatli qabul qilindi!"),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Formalarni tozalaymiz
        _formKey.currentState!.reset();
        _nameController.clear();
        _quantityController.clear();
        _costPriceController.clear();
        _sellingPriceController.clear();
        setState(() {
          _selectedUnit = 'dona';
        });
      } catch (e) {
        // Xatolik yuzaga kelsa, xabar ko'rsatamiz
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Xatolik yuz berdi: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false; // Yuklanishni tugatamiz
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Yangi mahsulotni qabul qilish",
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Bu yerda omborga kelgan yangi mahsulotlar ro'yxatga olinadi.",
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: "Mahsulot nomi",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.label_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Iltimos, mahsulot nomini kiriting";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedUnit,
                              items: _units.map((String unit) {
                                return DropdownMenuItem<String>(
                                  value: unit,
                                  child: Text(unit),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  _selectedUnit = newValue!;
                                });
                              },
                              decoration: const InputDecoration(
                                labelText: "O'lchov birligi",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _quantityController,
                              decoration: const InputDecoration(
                                labelText: "Miqdori",
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty ||
                                    double.tryParse(value) == null) {
                                  return "To'g'ri miqdor kiriting";
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _costPriceController,
                        decoration: const InputDecoration(
                          labelText: "Tan narxi (1 birlik uchun)",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.money_off),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              double.tryParse(value) == null) {
                            return "To'g'ri narx kiriting";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _sellingPriceController,
                        decoration: const InputDecoration(
                          labelText: "Sotuv narxi (1 birlik uchun)",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              double.tryParse(value) == null) {
                            return "To'g'ri narx kiriting";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // Agar yuklanish bo'layotgan bo'lsa, aylana, aks holda tugma ko'rsatiladi
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton.icon(
                              onPressed: _submitForm,
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text("Omborga qabul qilish"),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                            )
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
