import 'package:flutter/material.dart';
import '../models/material_item.dart';
import '../utils/db_helper.dart';

class MaterialScreen extends StatefulWidget {
  final List<MaterialItem> materials;
  final Function(List<MaterialItem>) onUpdate;

  const MaterialScreen({
    Key? key,
    required this.materials,
    required this.onUpdate,
  }) : super(key: key);

  @override
  _MaterialScreenState createState() => _MaterialScreenState();
}

class _MaterialScreenState extends State<MaterialScreen> {
  late List<MaterialItem> _materials;

  @override
  void initState() {
    super.initState();
    // Initialize local copy from widget.materials
    _materials = List.from(widget.materials);
  }

  Future<void> _loadMaterialsFromDb() async {
    final materials = await DatabaseHelper().getAllMaterials();
    setState(() {
      _materials = materials;
    });
  }

  Future<void> _addOrEditMaterial({MaterialItem? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final qtyController = TextEditingController(text: existing?.qty.toString() ?? '');
    final unitController = TextEditingController(text: existing?.unit ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'Add Material' : 'Edit Material'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: qtyController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(labelText: 'Unit'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final qty = int.tryParse(qtyController.text.trim());
              final unit = unitController.text.trim();

              if (name.isEmpty || qty == null || qty <= 0 || unit.isEmpty) {
                // Add error handling, e.g., show Snackbar or Alert
                return;
              }

              if (existing != null) {
                final updatedMaterial = MaterialItem(
                  id: existing.id,
                  name: name,
                  qty: qty,
                  unit: unit,
                );
                await DatabaseHelper().updateMaterial(updatedMaterial);

                // Update local list
                final index = _materials.indexWhere((m) => m.id == existing.id);
                if (index != -1) _materials[index] = updatedMaterial;
              } else {
                final newMaterial = MaterialItem(
                  id: 0,
                  name: name,
                  qty: qty,
                  unit: unit,
                );
                final newId = await DatabaseHelper().insertMaterial(newMaterial);
                _materials.add(MaterialItem(id: newId, name: name, qty: qty, unit: unit));
              }

              widget.onUpdate(_materials);
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMaterial(MaterialItem material) async {
    await DatabaseHelper().deleteMaterial(material.id);
    _materials.removeWhere((m) => m.id == material.id);
    widget.onUpdate(_materials);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Materials')),
      body: ListView.builder(
        itemCount: _materials.length,
        itemBuilder: (_, i) {
          final m = _materials[i];
          return ListTile(
            title: Text('${m.name} (Qty: ${m.qty} ${m.unit})'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _addOrEditMaterial(existing: m),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteMaterial(m),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditMaterial(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
