class ServiceCatalogItem {
  final String id;
  final String name;
  final String subtitle;
  final String category;
  final double price;
  final List<String> tags;
  final bool isBlanket;

  ServiceCatalogItem({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.category,
    required this.price,
    required this.tags,
    required this.isBlanket,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'subtitle': subtitle,
    'category': category,
    'price': price,
    'tags': tags,
    'isBlanket': isBlanket,
  };

  factory ServiceCatalogItem.fromMap(Map<String, dynamic> map) =>
      ServiceCatalogItem(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        subtitle: map['subtitle'] ?? '',
        category: map['category'] ?? 'Blanket & Duvet',
        price: (map['price'] ?? 130.0).toDouble(),
        tags: List<String>.from(map['tags'] ?? ['2-Ply Heavy']),
        isBlanket: map['isBlanket'] ?? true,
      );
}

class LaundromatVendor {
  final String id;
  final String name;
  final String area;
  final String address;
  final double rating;
  final double deliveryFee;
  final int turnaroundHours;
  final double latitude;
  final double longitude;
  final String driverName;
  final String driverVehicle;
  final String driverPlate;
  final String driverPhone;
  final List<ServiceCatalogItem> services;

  LaundromatVendor({
    required this.id,
    required this.name,
    required this.area,
    required this.address,
    required this.rating,
    required this.deliveryFee,
    required this.turnaroundHours,
    required this.latitude,
    required this.longitude,
    required this.driverName,
    required this.driverVehicle,
    required this.driverPlate,
    required this.driverPhone,
    required this.services,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'area': area,
    'address': address,
    'rating': rating,
    'deliveryFee': deliveryFee,
    'turnaroundHours': turnaroundHours,
    'latitude': latitude,
    'longitude': longitude,
    'driverName': driverName,
    'driverVehicle': driverVehicle,
    'driverPlate': driverPlate,
    'driverPhone': driverPhone,
    'services': services.map((s) => s.toMap()).toList(),
  };

  factory LaundromatVendor.fromMap(Map<String, dynamic> map) =>
      LaundromatVendor(
        id: map['id'] ?? 'v1',
        name: map['name'] ?? 'Mthatha Central CleanDrop Hub',
        area: map['area'] ?? 'Mthatha Central',
        address: map['address'] ?? '14 Nelson Mandela Dr, Mthatha',
        rating: (map['rating'] ?? 4.9).toDouble(),
        deliveryFee: (map['deliveryFee'] ?? 35.0).toDouble(),
        turnaroundHours: map['turnaroundHours'] ?? 48,
        latitude: (map['latitude'] ?? -31.5889).toDouble(),
        longitude: (map['longitude'] ?? 28.7844).toDouble(),
        driverName: map['driverName'] ?? 'Lwazi M.',
        driverVehicle: map['driverVehicle'] ?? 'White Toyota HiAce',
        driverPlate: map['driverPlate'] ?? 'EC 492-910',
        driverPhone: map['driverPhone'] ?? '+27821234567',
        services: (map['services'] as List<dynamic>? ?? [])
            .map((e) =>
            ServiceCatalogItem.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class BasketLineItem {
  final ServiceCatalogItem service;
  int quantity;
  String fabricComposition;
  bool hasStains;
  String stainCategory;
  bool hasDelicateTrim;
  bool hasPreExistingTears;
  String careNotes;
  String? localPhotoPath;

  BasketLineItem({
    required this.service,
    this.quantity = 1,
    this.fabricComposition = 'Plush Microfibre',
    this.hasStains = false,
    this.stainCategory = 'Mud / Dirt',
    this.hasDelicateTrim = false,
    this.hasPreExistingTears = false,
    this.careNotes = '',
    this.localPhotoPath,
  });

  double get stainFee => hasStains ? 15.0 * quantity : 0.0;
  double get lineTotal => (service.price * quantity) + stainFee;

  Map<String, dynamic> toMap() => {
    'serviceId': service.id,
    'name': service.name,
    'category': service.category,
    'basePrice': service.price,
    'quantity': quantity,
    'fabricComposition': fabricComposition,
    'hasStains': hasStains,
    'stainCategory': stainCategory,
    'stainFee': stainFee,
    'hasDelicateTrim': hasDelicateTrim,
    'hasPreExistingTears': hasPreExistingTears,
    'careNotes': careNotes,
    'hasPhoto': localPhotoPath != null,
    'lineTotal': lineTotal,
  };
}