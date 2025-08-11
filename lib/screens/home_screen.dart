import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/material_item.dart';
import '../utils/db_helper.dart';
import 'product_screen.dart';
import 'material_screen.dart';
import 'mapping_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> products = [];
  List<MaterialItem> materials = [];
  Map<int, List<int>> productMaterialsMap = {}; // your mappings here

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final loadedProducts = await DatabaseHelper().getAllProducts();
    final loadedMaterials = await DatabaseHelper().getAllMaterials();
    // TODO: Load your product-material mappings here from DB or initialize empty
    setState(() {
      products = loadedProducts;
      materials = loadedMaterials;
      productMaterialsMap = {}; // load or init your mappings
    });
  }

  void _updateProducts(List<Product> updated) {
    setState(() {
      products = List.from(updated);
    });
  }


  void _updateMaterials(List<MaterialItem> updated)  {
    setState(() {
    materials = List.from(updated);
    });
  }

  void _updateMappings(Map<int, List<int>> updated) {
    // TODO: persist mapping changes in DB if you have table for it
    setState(() => productMaterialsMap = updated);
  }

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      ProductScreen(products: products, onUpdate: _updateProducts),
      MaterialScreen(materials: materials, onUpdate: _updateMaterials),
      MappingScreen(
        products: products,
        materials: materials,
        productMaterialsMap: productMaterialsMap,
        onUpdate: _updateMappings,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.production_quantity_limits), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Materials'),
          BottomNavigationBarItem(icon: Icon(Icons.link), label: 'Mapping'),
        ],
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
