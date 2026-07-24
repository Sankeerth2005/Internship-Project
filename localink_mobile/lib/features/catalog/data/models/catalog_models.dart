class Catalog {
  final int id;
  final int businessId;
  final String title;
  final String? description;
  final List<CatalogItem> items;

  Catalog({
    required this.id,
    required this.businessId,
    required this.title,
    this.description,
    required this.items,
  });

  factory Catalog.fromJson(Map<String, dynamic> json) {
    return Catalog(
      id: json['id'],
      businessId: json['businessId'],
      title: json['title'],
      description: json['description'],
      items: (json['items'] as List?)
              ?.map((item) => CatalogItem.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': businessId,
      'title': title,
      'description': description,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}

class CatalogItem {
  final int id;
  final int catalogId;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final bool isAvailable;

  CatalogItem({
    required this.id,
    required this.catalogId,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    required this.isAvailable,
  });

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    return CatalogItem(
      id: json['id'],
      catalogId: json['catalogId'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'],
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'catalogId': catalogId,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
    };
  }
}
