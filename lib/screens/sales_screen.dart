import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/models.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final DB = DatabaseHelper.instance;
  List<Product> _products = [];
  List<_CartItem> _cart = [];
  double _totalAmount = 0;
  double _totalCost = 0;
  double _totalProfit = 0;

  final _formatter = NumberFormat('#,##0.00');

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final data = await DB.getAllProducts();
    setState(() {
      _products = data.map((e) => Product.fromMap(e)).toList();
    });
  }

  void _addToCart(Product product) async {
    final qtyCtrl = TextEditingController(text: '1');
    final selectedPriceType = await showDialog<_PriceType>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('选择「${product.name}」的售价类型'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('零售价 ¥${product.retailPrice.toStringAsFixed(2)}'),
              subtitle: Text('利润 ¥${product.profit.toStringAsFixed(2)} (${(product.profitRate * 100).toStringAsFixed(1)}%)'),
              onTap: () => Navigator.pop(ctx, _PriceType.retail),
            ),
            ListTile(
              title: Text('批发价 ¥${product.wholesalePrice.toStringAsFixed(2)}'),
              subtitle: Text('利润 ¥${(product.wholesalePrice - product.purchasePrice).toStringAsFixed(2)}'),
              onTap: () => Navigator.pop(ctx, _PriceType.wholesale),
            ),
          ],
        ),
      ),
    );

    if (selectedPriceType == null) return;

    final price = selectedPriceType == _PriceType.retail ? product.retailPrice : product.wholesalePrice;
    final cost = product.purchasePrice;

    final qty = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('「${product.name}」x ¥${price.toStringAsFixed(2)}'),
        content: TextField(
          controller: qtyCtrl,
          decoration: const InputDecoration(labelText: '数量', border: OutlineInputBorder()),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final qty = double.tryParse(qtyCtrl.text);
              Navigator.pop(ctx, qty);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (qty == null || qty <= 0) return;

    setState(() {
      _cart.add(_CartItem(product: product, quantity: qty, unitPrice: price, costPrice: cost));
      _recalculate();
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      _cart.removeAt(index);
      _recalculate();
    });
  }

  void _recalculate() {
    double amount = 0, cost = 0, profit = 0;
    for (var item in _cart) {
      amount += item.amount;
      cost += item.cost;
      profit += item.profit;
    }
    _totalAmount = amount;
    _totalCost = cost;
    _totalProfit = profit;
  }

  Future<void> _submitOrder() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先添加商品')));
      return;
    }

    final now = DateTime.now();
    final saleData = {
      'totalAmount': _totalAmount,
      'totalCost': _totalCost,
      'totalProfit': _totalProfit,
      'saleDate': now.toIso8601String(),
      'createdAt': now.toIso8601String(),
    };

    final saleId = await DB.insertSale(saleData);

    for (var item in _cart) {
      await DB.insertSaleItem({
        'saleId': saleId,
        'productId': item.product.id,
        'productName': item.product.name,
        'quantity': item.quantity,
        'unitPrice': item.unitPrice,
        'costPrice': item.costPrice,
        'profit': item.profit,
        'saleDate': now.toIso8601String(),
      });
    }

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('开单成功'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('成交金额: ¥${_formatter.format(_totalAmount)}'),
            Text('进货成本: ¥${_formatter.format(_totalCost)}'),
            Text('利润: ¥${_formatter.format(_totalProfit)}', style: const TextStyle(color: Colors.green)),
            Text('时间: ${DateFormat('yyyy-MM-dd HH:mm').format(now)}'),
          ],
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确定')),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _cart.clear();
        _recalculate();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('销售开单'),
        centerTitle: true,
        actions: [
          if (_cart.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _cart.clear();
                  _recalculate();
                });
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('清空'),
            ),
        ],
      ),
      body: Column(
        children: [
          // 商品选择区
          if (_products.isNotEmpty)
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(12),
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final p = _products[index];
                  return Card(
                    margin: const EdgeInsets.only(right: 10),
                    child: InkWell(
                      onTap: () => _addToCart(p),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 100,
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                            const SizedBox(height: 4),
                            Text('¥${p.retailPrice.toStringAsFixed(2)}', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                            Text('${p.unit}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          if (_products.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              child: Text('暂无商品，请先在「商品」页面添加', style: TextStyle(color: Colors.grey[600])),
            ),

          const Divider(height: 1),

          // 购物车列表
          Expanded(
            child: _cart.isEmpty
                ? Center(child: Text('点击上方商品添加', style: TextStyle(color: Colors.grey[500], fontSize: 16)))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _cart.length,
                    itemBuilder: (context, index) {
                      final item = _cart[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(item.product.name),
                          subtitle: Text('${item.quantity} ${item.product.unit} x ¥${item.unitPrice.toStringAsFixed(2)} = ¥${item.amount.toStringAsFixed(2)} | 利润 ¥${item.profit.toStringAsFixed(2)}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _removeFromCart(index),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // 底部结算栏
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(label: '成交金额', value: '¥${_formatter.format(_totalAmount)}', color: Colors.blue),
                      _StatItem(label: '进货成本', value: '¥${_formatter.format(_totalCost)}', color: Colors.orange),
                      _StatItem(label: '利润', value: '¥${_formatter.format(_totalProfit)}', color: Colors.green),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _cart.isEmpty ? null : _submitOrder,
                      icon: const Icon(Icons.receipt_long),
                      label: Text('确认开单 (${_cart.length}种商品)'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _PriceType { retail, wholesale }

class _CartItem {
  final Product product;
  final double quantity;
  final double unitPrice;
  final double costPrice;

  _CartItem({required this.product, required this.quantity, required this.unitPrice, required this.costPrice});

  double get amount => quantity * unitPrice;
  double get cost => quantity * costPrice;
  double get profit => amount - cost;
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
