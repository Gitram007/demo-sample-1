import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/material_item.dart';
import '../models/product.dart';
import '../utils/storage_helper.dart';

class MappingScreen extends StatefulWidget {
  final List<MaterialItem> materials;
  final List<Product> products;
  final Map<int, List<int>> productMaterialsMap;
  final Function(Map<int, List<int>>) onUpdate;

  const MappingScreen({
    super.key,
    required this.materials,
    required this.products,
    required this.productMaterialsMap,
    required this.onUpdate,
  });

  @override
  State<MappingScreen> createState() => _MappingScreenState();
}

class _MappingScreenState extends State<MappingScreen> with SingleTickerProviderStateMixin {
  int? selectedProductId;
  late TabController _tabController;

  Map<int, List<int>> localProductMaterialsMap = {};
  Map<int, Map<int, double>> mappingQuantities = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    localProductMaterialsMap = Map<int, List<int>>.from(widget.productMaterialsMap);

    StorageHelper.loadMappings().then((result) {
      setState(() {
        localProductMaterialsMap = Map<int, List<int>>.from(result.$1);
        mappingQuantities = Map<int, Map<int, double>>.from(result.$2);
      });
      widget.onUpdate(localProductMaterialsMap);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _cleanupQuantities() {
    mappingQuantities.removeWhere((productId, qtyMap) {
      final mappedIds = localProductMaterialsMap[productId] ?? [];
      qtyMap.removeWhere((id, _) => !mappedIds.contains(id));
      return qtyMap.isEmpty;
    });
  }

  void _saveAndUpdate() {
    _cleanupQuantities();
    StorageHelper.saveMappings(localProductMaterialsMap, mappingQuantities);
    widget.onUpdate(localProductMaterialsMap);
  }

  void selectAllMaterials() {
    if (selectedProductId == null) return;
    setState(() {
      localProductMaterialsMap[selectedProductId!] = widget.materials.map((m) => m.id).toList();
      mappingQuantities[selectedProductId!] = {
        for (var m in widget.materials) m.id: 1.0,
      };
      _saveAndUpdate();
    });
  }

  void deselectAllMaterials() {
    if (selectedProductId == null) return;
    setState(() {
      localProductMaterialsMap.remove(selectedProductId!);
      mappingQuantities.remove(selectedProductId!);
      _saveAndUpdate();
    });
  }

  Widget buildMappingTab() {
    final materials = widget.materials;
    final products = widget.products;

    final mappedMaterialIds = selectedProductId != null
        ? (localProductMaterialsMap[selectedProductId!] ?? [])
        : [];

    final currentQtys = selectedProductId != null
        ? (mappingQuantities[selectedProductId!] ?? {})
        : {};

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: DropdownButton<int>(
            hint: const Text('Select Product'),
            value: selectedProductId,
            isExpanded: true,
            items: products
                .map((p) => DropdownMenuItem<int>(
              value: p.id,
              child: Text('${p.name} (ID: ${p.id})'),
            ))
                .toList(),
            onChanged: (val) => setState(() {
              selectedProductId = val;
            }),
          ),
        ),
        if (selectedProductId != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: selectAllMaterials,
                  child: const Text('Select All'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: deselectAllMaterials,
                  child: const Text('Deselect All'),
                ),
              ],
            ),
          ),
        Expanded(
          child: selectedProductId == null
              ? const Center(child: Text('Select a product to map materials'))
              : ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: materials.map((m) {
              final isMapped = mappedMaterialIds.contains(m.id);
              final quantity = currentQtys[m.id] ?? 1.0;

              return CheckboxListTile(
                title: Text('${m.name} (ID: ${m.id})'),
                subtitle: isMapped
                    ? Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: TextFormField(
                        initialValue: quantity.toString(),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        decoration: const InputDecoration(labelText: 'Qty'),
                        onChanged: (val) {
                          final parsed = double.tryParse(val);
                          if (parsed != null && parsed > 0) {
                            setState(() {
                              mappingQuantities
                                  .putIfAbsent(selectedProductId!, () => {})[m.id] = parsed;
                              _saveAndUpdate();
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(m.unit),
                  ],
                )
                    : Text('Default: ${m.qty} ${m.unit}'),
                value: isMapped,
                onChanged: (bool? value) {
                  setState(() {
                    final list = localProductMaterialsMap.putIfAbsent(selectedProductId!, () => []);
                    if (value == true) {
                      if (!list.contains(m.id)) {
                        list.add(m.id);
                        mappingQuantities.putIfAbsent(selectedProductId!, () => {})[m.id] = 1.0;
                      }
                    } else {
                      list.remove(m.id);
                      mappingQuantities[selectedProductId!]?.remove(m.id);
                      if (list.isEmpty) {
                        localProductMaterialsMap.remove(selectedProductId!);
                        mappingQuantities.remove(selectedProductId!);
                      }
                    }
                    _saveAndUpdate();
                  });
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget buildViewMappingTab() {
    final products = widget.products;
    final materials = widget.materials;

    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final mappedIds = localProductMaterialsMap[product.id] ?? [];

        final mappedMaterials = mappedIds
            .map((id) => materials.firstWhere(
              (m) => m.id == id,
          orElse: () => MaterialItem(id: id, name: 'Unknown', qty: 0, unit: ''),
        ))
            .toList();

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: ExpansionTile(
            title: Text('${product.name} (ID: ${product.id})'),
            children: mappedMaterials.isEmpty
                ? [const ListTile(title: Text('No materials mapped'))]
                : mappedMaterials.map((mat) {
              final qty = mappingQuantities[product.id]?[mat.id];
              return ListTile(
                title: Text(mat.name),
                subtitle: Text(qty != null
                    ? 'Mapping Qty: $qty ${mat.unit}'
                    : 'Qty: ${mat.qty} ${mat.unit}'),
                trailing: Text('ID: ${mat.id}'),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Material-Product Mapping'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Map Materials'),
            Tab(text: 'View Mappings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildMappingTab(),
          buildViewMappingTab(),
        ],
      ),
    );
  }
}
