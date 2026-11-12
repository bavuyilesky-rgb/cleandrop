import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/laundry_models.dart';
import 'blanket_customizer_screen.dart';
import '../screens/schedule_service_screen.dart';
import '../screens/orders_receipts_tab.dart';
import '../screens/live_tracking_tab.dart';
import '../screens/profile_settings_tab.dart';

class MainNavigationShell extends StatefulWidget {
  final int initialTab;
  final String? activeOrderId;

  const MainNavigationShell({
    super.key,
    this.initialTab = 0,
    this.activeOrderId,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  late int _currentIndex;
  String? _trackedOrderId;

  String _userName = 'Sipho';
  String _userPhone = '+27 73 456 7890';
  String _streetAddress = '12 Devereux Ave';
  String _suburbCity = 'Vincent, East London';
  LatLng _userCoords = const LatLng(-32.9865, 27.9052);
  bool _gpsSyncing = true;

  List<LaundromatVendor> _vendors = [];
  LaundromatVendor? _selectedVendor;
  final List<BasketLineItem> _basket = [];
  String _searchQuery = '';
  String _selectedCategoryFilter = 'All';

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    _trackedOrderId = widget.activeOrderId;
    _vendors = _generateInitialSeedVendors(_userCoords);
    _selectedVendor = _vendors.first;
    _loadUserProfileAndLiveGps();
  }

  Future<void> _loadUserProfileAndLiveGps() async {
    setState(() => _gpsSyncing = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final d = doc.data()!;
        _userName = (d['fullName'] ?? user.displayName ?? 'Sipho')
            .toString()
            .split(' ')
            .first;
        _userPhone = (d['phone'] ?? '+27 73 456 7890').toString();
      }
    }

    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        _userCoords = LatLng(pos.latitude, pos.longitude);
        final marks =
        await geo.Geocoding().placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (marks.isNotEmpty) {
          final p = marks.first;
          _streetAddress = (p.street != null && p.street!.isNotEmpty)
              ? p.street!
              : '14 Nelson Mandela Dr';
          _suburbCity =
          '${p.subLocality?.isNotEmpty == true ? p.subLocality : (p.locality ?? "Mthatha Central")}, ${p.administrativeArea ?? "Eastern Cape"}';
        }
      }
    } catch (e) {
      debugPrint('Using fallback coordinates: $e');
    }

    await _seedTestVendorsAndOrders(_userCoords);
    if (mounted) setState(() => _gpsSyncing = false);
  }

  static List<LaundromatVendor> _generateInitialSeedVendors(LatLng center) {
    final catalog = [
      ServiceCatalogItem(
        id: 'srv_queen_blanket',
        name: 'Queen Heavy Winter Blanket',
        subtitle: 'Soft wash, sanitized deep tumble dry',
        category: 'Blanket & Duvet',
        price: 130.0,
        tags: ['2-Ply Heavy', 'Anti-bacterial'],
        isBlanket: true,
      ),
      ServiceCatalogItem(
        id: 'srv_single_fleece',
        name: 'Single Fleece Blanket',
        subtitle: 'Gentle low tumble dry & fold',
        category: 'Blanket & Duvet',
        price: 90.0,
        tags: ['Gentle Cycle'],
        isBlanket: true,
      ),
      ServiceCatalogItem(
        id: 'srv_king_duvet',
        name: 'King Duvet & Feathers',
        subtitle: 'Deep sanitise wash & loft recovery',
        category: 'Blanket & Duvet',
        price: 160.0,
        tags: ['Specialty Feather'],
        isBlanket: true,
      ),
      ServiceCatalogItem(
        id: 'srv_wash_fold_5kg',
        name: 'Daily Wash & Fold Bag (5kg)',
        subtitle: 'Standard wardrobe bundle, ready to store',
        category: 'Wash & Fold',
        price: 125.0,
        tags: ['Everyday Essentials'],
        isBlanket: false,
      ),
      ServiceCatalogItem(
        id: 'srv_dry_clean_suit',
        name: 'Executive 2-Piece Suit Dry Clean',
        subtitle: 'Delicate solvent clean & hand press',
        category: 'Dry Cleaning',
        price: 180.0,
        tags: ['Delicates & Suits'],
        isBlanket: false,
      ),
      ServiceCatalogItem(
        id: 'srv_iron_press',
        name: 'Crisp Steam Iron & Press (10 items)',
        subtitle: 'Hanger or folded crisp hand finish',
        category: 'Iron & Press',
        price: 95.0,
        tags: ['Steam Press'],
        isBlanket: false,
      ),
    ];

    return [
      LaundromatVendor(
        id: 'vendor_vincent_park',
        name: 'Vincent Park CleanDrop Express',
        area: 'Vincent',
        address: '12 Devereux Ave, Vincent, East London',
        rating: 4.9,
        deliveryFee: 35.0,
        turnaroundHours: 24,
        latitude: center.latitude + 0.0035,
        longitude: center.longitude + 0.0028,
        driverName: 'Sipho N.',
        driverVehicle: 'White Hyundai H100',
        driverPlate: 'EL 829-102',
        driverPhone: '+27829988112',
        services: catalog,
      ),
      LaundromatVendor(
        id: 'vendor_beacon_bay',
        name: 'Beacon Bay Eco Wash & Blanket Care',
        area: 'Beacon Bay',
        address: '18 Bonza Bay Rd, Beacon Bay, East London',
        rating: 4.9,
        deliveryFee: 30.0,
        turnaroundHours: 48,
        latitude: center.latitude + 0.0220,
        longitude: center.longitude + 0.0298,
        driverName: 'Thando M.',
        driverVehicle: 'Silver Nissan NP200',
        driverPlate: 'EL 119-482',
        driverPhone: '+27834455667',
        services: catalog,
      ),
      LaundromatVendor(
        id: 'vendor_selborne_dry',
        name: 'Selborne Executive Dry Cleaners & Suits',
        area: 'Selborne',
        address: '34 Oxford St, Selborne, East London',
        rating: 4.8,
        deliveryFee: 35.0,
        turnaroundHours: 24,
        latitude: center.latitude - 0.0117,
        longitude: center.longitude - 0.0051,
        driverName: 'Mandla Z.',
        driverVehicle: 'White Isuzu D-Max',
        driverPlate: 'EL 482-901',
        driverPhone: '+27821122334',
        services: catalog,
      ),
      LaundromatVendor(
        id: 'vendor_gonubie_hub',
        name: 'Gonubie Coastal Laundry & Duvet Hub',
        area: 'Gonubie',
        address: '5 Main Rd, Gonubie, East London',
        rating: 4.8,
        deliveryFee: 40.0,
        turnaroundHours: 48,
        latitude: center.latitude + 0.0545,
        longitude: center.longitude + 0.1158,
        driverName: 'Anele B.',
        driverVehicle: 'White Ford Ranger',
        driverPlate: 'EL 302-881',
        driverPhone: '+27718899001',
        services: catalog,
      ),
      LaundromatVendor(
        id: 'vendor_nahoon_stirling',
        name: 'Nahoon Beachside Wash, Fold & Press',
        area: 'Nahoon',
        address: '22 Beach Rd, Nahoon, East London',
        rating: 4.9,
        deliveryFee: 35.0,
        turnaroundHours: 24,
        latitude: center.latitude - 0.0055,
        longitude: center.longitude + 0.0178,
        driverName: 'Khaya M.',
        driverVehicle: 'Toyota Quantum Van',
        driverPlate: 'EL 992-104',
        driverPhone: '+27827766554',
        services: catalog,
      ),
      LaundromatVendor(
        id: 'vendor_mthatha_hub',
        name: 'Mthatha Central CleanDrop Hub',
        area: 'Mthatha Central',
        address: '14 Nelson Mandela Dr, Mthatha Central',
        rating: 4.9,
        deliveryFee: 35.0,
        turnaroundHours: 48,
        latitude: center.latitude + 1.3976,
        longitude: center.longitude + 0.8792,
        driverName: 'Lwazi M.',
        driverVehicle: 'White Toyota HiAce',
        driverPlate: 'EC 492-910',
        driverPhone: '+27821234567',
        services: catalog,
      ),
    ];
  }

  Future<void> _seedTestVendorsAndOrders(LatLng center) async {
    final seededVendors = _generateInitialSeedVendors(center);
    if (_vendors.isEmpty) {
      _vendors = seededVendors;
      _selectedVendor ??= _vendors.first;
    }

    try {
      final snap =
      await FirebaseFirestore.instance.collection('laundromats').get();
      if (snap.docs.isEmpty) {
        for (final v in seededVendors) {
          await FirebaseFirestore.instance
              .collection('laundromats')
              .doc(v.id)
              .set(v.toMap());
        }
      }

      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'demo_user';
      final orderSnap = await FirebaseFirestore.instance
          .collection('orders')
          .where('customerId', isEqualTo: uid)
          .get();

      if (orderSnap.docs.isEmpty) {
        final now = DateTime.now();
        const sampleActiveId = 'CD-9048';
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(sampleActiveId)
            .set({
          'orderId': sampleActiveId,
          'customerId': uid,
          'customerName': _userName,
          'customerPhone': _userPhone,
          'laundromatId': seededVendors.first.id,
          'laundromatName': seededVendors.first.name,
          'driverName': 'Lwazi M.',
          'driverVehicle': 'White Toyota HiAce',
          'driverPlate': 'EC 492-910',
          'driverPhone': '+27821234567',
          'pickupAddress': '$_streetAddress, $_suburbCity',
          'pickupDate': DateFormat('EEE, dd MMM yyyy').format(now),
          'deliveryDate': DateFormat('EEE, dd MMM yyyy')
              .format(now.add(const Duration(hours: 48))),
          'timeSlot': '10:00 - 12:00',
          'userLat': center.latitude,
          'userLng': center.longitude,
          'vendorLat': seededVendors.first.latitude,
          'vendorLng': seededVendors.first.longitude,
          'subtotal': 255.0,
          'stainCareFee': 15.0,
          'deliveryFee': 35.0,
          'expressFee': 0.0,
          'totalAmount': 325.0,
          'paymentMethod': 'Visa •••• 4829',
          'orderStatus': 'DRIVER_EN_ROUTE',
          'handoverPin': '4821',
          'items': [
            {
              'name': 'Queen Winter Blanket (2-Ply)',
              'quantity': 1,
              'basePrice': 130.0,
              'fabricComposition': 'Plush Microfibre',
              'hasStains': true,
              'stainCategory': 'Oil / Mud stain',
              'stainFee': 15.0,
              'hasPhoto': true,
              'lineTotal': 145.0,
            },
            {
              'name': 'Standard Wash & Fold (5 kg bag)',
              'quantity': 1,
              'basePrice': 125.0,
              'fabricComposition': 'Mixed Cotton',
              'hasStains': false,
              'stainCategory': 'None',
              'stainFee': 0.0,
              'hasPhoto': false,
              'lineTotal': 125.0,
            },
          ],
          'createdAt': FieldValue.serverTimestamp(),
        });
        _trackedOrderId = sampleActiveId;
      } else {
        _trackedOrderId = orderSnap.docs.first.id;
      }
    } catch (_) {}

    _vendors = seededVendors;
    _selectedVendor ??= _vendors.first;
  }

  double get _basketTotal =>
      _basket.fold(0.0, (total, item) => total + item.lineTotal);

  int get _basketCount =>
      _basket.fold(0, (count, item) => count + item.quantity);

  void _openItemCustomizer(ServiceCatalogItem service) async {
    final addedItem = await Navigator.push<BasketLineItem>(
      context,
      MaterialPageRoute(
        builder: (_) => BlanketCustomizerScreen(service: service),
      ),
    );
    if (addedItem != null && mounted) {
      setState(() => _basket.add(addedItem));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.darkNavy,
          content: Text(
              'Added ${addedItem.service.name} (R${addedItem.lineTotal.toStringAsFixed(2)}) to basket'),
        ),
      );
    }
  }

  void _proceedToScheduling() {
    if (_basket.isEmpty) {
      _openItemCustomizer(_selectedVendor!.services.first);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleServiceScreen(
          vendor: _selectedVendor!,
          basket: _basket,
          streetAddress: _streetAddress,
          suburbCity: _suburbCity,
          userCoords: _userCoords,
          userName: _userName,
          userPhone: _userPhone,
          onOrderPlaced: (newOrderId) {
            setState(() {
              _basket.clear();
              _trackedOrderId = newOrderId;
              _currentIndex = 2;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomeCatalogTab(),
      OrdersAndReceiptsTab(
        onTrackOrder: (orderId) {
          setState(() {
            _trackedOrderId = orderId;
            _currentIndex = 2;
          });
        },
        onReorder: (_) {
          if (_selectedVendor != null) {
            _openItemCustomizer(_selectedVendor!.services.first);
          }
        },
      ),
      LiveTrackingTab(
        orderId: _trackedOrderId ?? 'CD-9048',
        fallbackUserCoords: _userCoords,
      ),
      ProfileAndSettingsTab(
        userName: _userName,
        userPhone: _userPhone,
        streetAddress: _streetAddress,
        suburbCity: _suburbCity,
        onRefreshGps: _loadUserProfileAndLiveGps,
        onUpdateProfile: (newName, newPhone, newAddr) {
          setState(() {
            _userName = newName;
            _userPhone = newPhone;
            _streetAddress = newAddr;
          });
        },
      ),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: _buildStitchBottomNavBar(),
    );
  }

  Widget _buildHomeCatalogTab() {
    final vendor = _selectedVendor ??
        (_vendors.isNotEmpty
            ? _vendors.first
            : _generateInitialSeedVendors(_userCoords).first);

    final matchingVendors = _vendors.where((v) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return v.name.toLowerCase().contains(q) ||
          v.area.toLowerCase().contains(q) ||
          v.services.any((s) => s.name.toLowerCase().contains(q));
    }).toList();

    final filteredServices = vendor.services.where((s) {
      final matchesCategory = _selectedCategoryFilter == 'All' ||
          s.category == _selectedCategoryFilter;
      final matchesQuery = _searchQuery.isEmpty ||
          s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.subtitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();

    return SafeArea(
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.darkNavy,
                            child: Text(
                              _userName.isNotEmpty ? _userName[0] : 'S',
                              style: const TextStyle(
                                color: AppColors.mintAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back,',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  'Hello, $_userName',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              showLocalPushNotification(
                                'CleanDrop Winter Special',
                                'Get 20% OFF your first heavy blanket wash in $_suburbCity!',
                              );
                            },
                            icon: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: const Icon(
                                  Icons.notifications_none_rounded,
                                  size: 22),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          InkWell(
                            onTap: _showVendorMapPickerModal,
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                      size: 16, color: AppColors.deepEmerald),
                                  const SizedBox(width: 6),
                                  Text(
                                    _gpsSyncing
                                        ? 'Syncing GPS...'
                                        : _streetAddress,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.keyboard_arrow_down,
                                      size: 16),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: _showVendorMapPickerModal,
                              child: Text(
                                '• ${vendor.name}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.deepEmerald,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          hintText:
                          'Search dry cleaners, blankets, laundry...',
                          hintStyle: TextStyle(
                              fontSize: 13, color: Colors.grey.shade500),
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            tooltip: 'Pick Dry Cleaner on Map',
                            icon: const Icon(Icons.tune_rounded,
                                color: AppColors.deepEmerald),
                            onPressed: _showVendorMapPickerModal,
                          ),
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: matchingVendors.length,
                          itemBuilder: (context, idx) {
                            final v = matchingVendors[idx];
                            final isSelected = v.id == vendor.id;
                            final distKm = (Geolocator.distanceBetween(
                              _userCoords.latitude,
                              _userCoords.longitude,
                              v.latitude,
                              v.longitude,
                            ) /
                                1000)
                                .toStringAsFixed(1);
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(
                                    '${v.name} ($distKm km • ★${v.rating})'),
                                selected: isSelected,
                                selectedColor: AppColors.mintAccent,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? AppColors.darkNavy
                                      : Colors.grey.shade700,
                                ),
                                onSelected: (_) =>
                                    setState(() => _selectedVendor = v),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0D1B2A), Color(0xFF133B43)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.mintAccent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    '✨ 20% OFF FIRST ORDER',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.darkNavy,
                                    ),
                                  ),
                                ),
                                const Text(
                                  '🕒 48h turnaround',
                                  style: TextStyle(
                                    color: AppColors.mintAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Winter Blanket Special',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Wash & Fold with sanitised 48h turnaround service.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.mintAccent,
                                foregroundColor: AppColors.darkNavy,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () =>
                                  _openItemCustomizer(vendor.services.first),
                              icon: const Text(
                                'Book Pickup',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              label: const Icon(Icons.arrow_forward, size: 16),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Services',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          TextButton(
                            onPressed: () => setState(
                                    () => _selectedCategoryFilter = 'All'),
                            child: const Text(
                              'View All',
                              style: TextStyle(
                                color: AppColors.deepEmerald,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.32,
                        children: [
                          _buildServiceCategoryCard(
                            title: 'Blanket & Duvet',
                            subtitle: 'Deep steam & dry',
                            icon: Icons.bed_rounded,
                            badge: 'Popular',
                          ),
                          _buildServiceCategoryCard(
                            title: 'Wash & Fold',
                            subtitle: 'From R25 / kg',
                            icon: Icons.local_laundry_service_outlined,
                          ),
                          _buildServiceCategoryCard(
                            title: 'Dry Cleaning',
                            subtitle: 'Delicates & suits',
                            icon: Icons.checkroom_rounded,
                          ),
                          _buildServiceCategoryCard(
                            title: 'Iron & Press',
                            subtitle: 'Crisp hand finish',
                            icon: Icons.iron_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Popular Services',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      ...filteredServices
                          .map((srv) => _buildPopularServiceTile(srv)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_basket.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 12,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.darkNavy,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.deepEmerald,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shopping_basket_outlined,
                          color: AppColors.mintAccent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_basketCount item${_basketCount > 1 ? 's' : ''} in basket',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${_basket.first.service.name} • R ${_basketTotal.toStringAsFixed(2)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.mintAccent,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mintAccent,
                        foregroundColor: AppColors.darkNavy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _proceedToScheduling,
                      child: const Text(
                        'View Cart →',
                        style: TextStyle(fontWeight: FontWeight.w800),
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

  Widget _buildServiceCategoryCard({
    required String title,
    required String subtitle,
    required IconData icon,
    String? badge,
  }) {
    final isSelected = _selectedCategoryFilter == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryFilter = isSelected ? 'All' : title;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? AppColors.mintAccent
                : Colors.grey.withOpacity(0.25),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.tagBlue.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.darkNavy, size: 22),
                ),
                if (badge != null)
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.deepEmerald,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularServiceTile(ServiceCatalogItem srv) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    children: srv.tags
                        .map(
                          (t) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.tagBlue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          t,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkNavy,
                          ),
                        ),
                      ),
                    )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    srv.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    srv.subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.darkNavy,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'R ${srv.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.mintAccent,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () => _openItemCustomizer(srv),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.darkNavy,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVendorMapPickerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.72,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Nearby Laundromats & Dry Cleaners (Live GPS)',
                      style:
                      TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: _userCoords,
                    initialZoom: 14.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.cleandrop.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _userCoords,
                          width: 48,
                          height: 48,
                          child: const Icon(Icons.my_location,
                              color: Colors.blueAccent, size: 34),
                        ),
                        ..._vendors.map(
                              (v) => Marker(
                            point: LatLng(v.latitude, v.longitude),
                            width: 120,
                            height: 65,
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _selectedVendor = v);
                                Navigator.pop(ctx);
                              },
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.darkNavy,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      v.name.split(' ').first,
                                      style: const TextStyle(
                                          color: AppColors.mintAccent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const Icon(Icons.location_on,
                                      color: AppColors.deepEmerald, size: 34),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStitchBottomNavBar() {
    final items = [
      {'icon': Icons.local_laundry_service_outlined, 'label': 'Home'},
      {'icon': Icons.receipt_long_outlined, 'label': 'Orders'},
      {'icon': Icons.local_shipping_outlined, 'label': 'Tracking'},
      {'icon': Icons.person_outline_rounded, 'label': 'Profile'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (i) {
            final active = _currentIndex == i;
            return GestureDetector(
              onTap: () => setState(() => _currentIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? AppColors.mintAccent : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      items[i]['icon'] as IconData,
                      size: 22,
                      color: active ? AppColors.darkNavy : Colors.grey.shade600,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      items[i]['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                        active ? FontWeight.w800 : FontWeight.normal,
                        color:
                        active ? AppColors.darkNavy : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}