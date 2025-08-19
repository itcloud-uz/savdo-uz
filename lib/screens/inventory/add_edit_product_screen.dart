import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:savdo_uz/models/product_model.dart';
import 'package:savdo_uz/services/firestore_service.dart';
import 'package:savdo_uz/widgets/custom_textfield.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _barcodeController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name);
    _barcodeController = TextEditingController(text: widget.product?.barcode);
    _priceController =
        TextEditingController(text: widget.product?.price.toString());
    _quantityController =
        TextEditingController(text: widget.product?.quantity.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    try {
      String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Bekor qilish', true, ScanMode.BARCODE);
      if (barcodeScanRes != '-1') {
        _barcodeController.text = barcodeScanRes;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Skanerlashda xatolik: $e')),
      );
    }
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final firestoreService = context.read<FirestoreService>();

      try {
        final product = Product(
          id: widget.product?.id,
          name: _nameController.text.trim(),
          barcode: _barcodeController.text.trim(),
          price: double.tryParse(_priceController.text) ?? 0.0,
          quantity: int.tryParse(_quantityController.text) ?? 0,
        );

        if (widget.product == null) {
          await firestoreService.addProduct(product);
        } else {
          await firestoreService.updateProduct(product);
        }

        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Xatolik: $e")));
      } finally {
        if (mounted)
          setState(() {
            _isLoading = false;
          });
      }
    }
  }

  Future<void> _deleteProduct() async {
    if (widget.product == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('O\'chirishni tasdiqlang'),
        content: Text(
            '${widget.product!.name} nomli mahsulotni o\'chirishga ishonchingiz komilmi?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Bekor qilish')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('O\'chirish'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      setState(() {
        _isLoading = true;
      });
      try {
        final firestoreService = context.read<FirestoreService>();
        await firestoreService.deleteProduct(widget.product!.id!);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Xatolik: $e")));
      } finally {
        if (mounted)
          setState(() {
            _isLoading = false;
          });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Yangi Mahsulot' : 'Tahrirlash'),
        actions: [
          if (widget.product != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _isLoading ? null : _deleteProduct,
              tooltip: 'O\'chirish',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _nameController,
                labelText: 'Mahsulot nomi',
                validator: (value) =>
                    value!.trim().isEmpty ? 'Nomini kiriting' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _barcodeController,
                labelText: 'Shtrix-kod',
                validator: (value) =>
                    value!.trim().isEmpty ? 'Shtrix-kodni kiriting' : null,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _scanBarcode,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _priceController,
                      labelText: 'Narxi',
                      keyboardType: TextInputType.number,
                      validator: (value) => (double.tryParse(value!) == null)
                          ? 'To\'g\'ri narx kiriting'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _quantityController,
                      labelText: 'Soni',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) => (int.tryParse(value!) == null)
                          ? 'To\'g\'ri son kiriting'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProduct,
                        child: const Text('Saqlash'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
