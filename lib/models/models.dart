class Product {
  final int? id;
  final String name;
  final double purchasePrice;
  final double retailPrice;
  final double wholesalePrice;
  final String unit;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    this.id,
    required this.name,
    required this.purchasePrice,
    required this.retailPrice,
    required this.wholesalePrice,
    required this.unit,
    required this.createdAt,
    required this.updatedAt,
  });

  double get profit => retailPrice - purchasePrice;
  double get profitRate => purchasePrice > 0 ? profit / purchasePrice : 0;
  double get profitMargin => retailPrice > 0 ? profit / retailPrice : 0;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'purchasePrice': purchasePrice,
      'retailPrice': retailPrice,
      'wholesalePrice': wholesalePrice,
      'unit': unit,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      purchasePrice: (map['purchasePrice'] as num).toDouble(),
      retailPrice: (map['retailPrice'] as num).toDouble(),
      wholesalePrice: (map['wholesalePrice'] as num).toDouble(),
      unit: map['unit'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Product copyWith({
    int? id,
    String? name,
    double? purchasePrice,
    double? retailPrice,
    double? wholesalePrice,
    String? unit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      retailPrice: retailPrice ?? this.retailPrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      unit: unit ?? this.unit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SaleItem {
  final int? id;
  final int saleId;
  final int productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double costPrice;
  final double profit;
  final DateTime saleDate;

  SaleItem({
    this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.costPrice,
    required this.profit,
    required this.saleDate,
  });

  double get amount => quantity * unitPrice;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'saleId': saleId,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'costPrice': costPrice,
      'profit': profit,
      'saleDate': saleDate.toIso8601String(),
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'] as int?,
      saleId: map['saleId'] as int,
      productId: map['productId'] as int,
      productName: map['productName'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unitPrice'] as num).toDouble(),
      costPrice: (map['costPrice'] as num).toDouble(),
      profit: (map['profit'] as num).toDouble(),
      saleDate: DateTime.parse(map['saleDate'] as String),
    );
  }
}

class Sale {
  final int? id;
  final double totalAmount;
  final double totalCost;
  final double totalProfit;
  final DateTime saleDate;
  final DateTime createdAt;
  final List<SaleItem> items;

  Sale({
    this.id,
    required this.totalAmount,
    required this.totalCost,
    required this.totalProfit,
    required this.saleDate,
    required this.createdAt,
    this.items = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'totalAmount': totalAmount,
      'totalCost': totalCost,
      'totalProfit': totalProfit,
      'saleDate': saleDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map, [List<SaleItem>? items]) {
    return Sale(
      id: map['id'] as int?,
      totalAmount: (map['totalAmount'] as num).toDouble(),
      totalCost: (map['totalCost'] as num).toDouble(),
      totalProfit: (map['totalProfit'] as num).toDouble(),
      saleDate: DateTime.parse(map['saleDate'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
      items: items ?? [],
    );
  }
}
