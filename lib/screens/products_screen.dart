import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/models.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final DB = DatabaseHelper.instance;
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final data = await DB.getAllProducts();
    setState(() {
      _products = data.map((e) => Product.fromMap(e)).toList();
      _isLoading = false;
    });
  }

  Future<void> _showProductDialog([Product? product]) async {
    final isEdit = product != null;
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final purchaseCtrl = TextEditingController(text: product?.purchasePrice.toString() ?? '');
    final retailCtrl = TextEditingController(text: product?.retailPrice.toString() ?? '');
    final wholesaleCtrl = TextEditingController(text: product?.wholesalePrice.toString() ?? '');
    final unitCtrl = TextEditingController(text: product?.unit ?? '个');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? '编辑商品' : '添加商品'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: '商品名称', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: purchaseCtrl,
                decoration: const InputDecoration(labelText: '进货价(元)', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: retailCtrl,
                decoration: const InputDecoration(labelText: '零售价(元)', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: wholesaleCtrl,
                decoration: const InputDecoration(labelText: '批发价(元)', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: unitCtrl,
                decoration: const InputDecoration(labelText: '单位', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final purchase = double.tryParse(purchaseCtrl.text) ?? 0;
              final retail = double.tryParse(retailCtrl.text) ?? 0;
              final wholesale = double.tryParse(wholesaleCtrl.text) ?? 0;
              final unit = unitCtrl.text.trim();

              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入商品名称')));
                return;
              }

              final now = DateTime.now();
              final data = {
                'name': name,
                'purchasePrice': purchase,
                'retailPrice': retail,
                'wholesalePrice': wholesale,
                'unit': unit.isEmpty ? '个' : unit,
                'createdAt': isEdit ? product!.createdAt.toIso8601String() : now.toIso8601String(),
                'updatedAt': now.toIso8601String(),
              };

              if (isEdit) {
                await DB.updateProduct(product.id!, data);
              } else {
                await DB.insertProduct(data);
              }

              Navigator.pop(context, true);
            },
            child: Text(isEdit ? '保存' : '添加'),
          ),
        ],
      ),
    );

    if (result == true) _loadProducts();
  }

  Future<void> _deleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除「${product.name}」吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DB.deleteProduct(product.id!);
      _loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('商品管理'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('暂无商品，点击下方 + 添加', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final p = _products[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '进价: ¥${p.purchasePrice.toStringAsFixed(2)} | 零售: ¥${p.retailPrice.toStringAsFixed(2)} | 批发: ¥${p.wholesalePrice.toStringAsFixed(2)} | ${p.unit}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '利润: ¥${p.profit.toStringAsFixed(2)}',
                                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '利润率: ${(p.profitRate * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showProductDialog(p);
                                } else if (value == 'delete') {
                                  _deleteProduct(p);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: Text('编辑')),
                                const PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
