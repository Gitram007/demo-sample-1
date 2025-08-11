import 'package:flutter/material.dart';
import '../models/product.dart';
import '../utils/db_helper.dart';

class ProductScreen extends StatefulWidget {
  final List<Product> products;
  final Function(List<Product>) onUpdate;

  const ProductScreen({
    Key? key,
    required this.products,
    required this.onUpdate,
  }) : super(key: key);

  @override
  _ProductScreenState createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _products = List.from(widget.products);
  }

  @override
  void didUpdateWidget(covariant ProductScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.products != oldWidget.products) {
      _products = List.from(widget.products);
    }
}


  Future<void> _loadProductsFromDb() async {
    final products = await DatabaseHelper().getAllProducts();
    setState(() {
      _products = products;
    });
  }

  Future<void> _addOrEditProduct({Product? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'Add Product' : 'Edit Product'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Product Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              if (existing != null) {
                // Update existing product
                final updatedProduct = Product(id: existing.id, name: name);
                await DatabaseHelper().updateProduct(updatedProduct);

                final index = _products.indexWhere((p) => p.id == existing.id);
                if (index != -1) _products[index] = updatedProduct;
              } else {
                // Insert new product
                final newProduct = Product(id: null, name: name);
                final newId = await DatabaseHelper().insertProduct(newProduct);
                _products.add(Product(id: newId, name: name));
              }

              widget.onUpdate(_products);
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(Product product) async {
    await DatabaseHelper().deleteProduct(product.id!);
    _products.removeWhere((p) => p.id == product.id);
    widget.onUpdate(_products);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: ListView.builder(
        itemCount: _products.length,
        itemBuilder: (_, i) {
          final p = _products[i];
          return ListTile(
            title: Text('${p.name} (ID: ${p.id})'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _addOrEditProduct(existing: p),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteProduct(p),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditProduct(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
