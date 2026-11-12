import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/laundry_models.dart';
import 'order_summary_payment_screen.dart';

class ScheduleServiceScreen extends StatefulWidget {
  final LaundromatVendor vendor;
  final List<BasketLineItem> basket;
  final String streetAddress;
  final String suburbCity;
  final LatLng userCoords;
  final String userName;
  final String userPhone;
  final void Function(String orderId) onOrderPlaced;

  const ScheduleServiceScreen({
    super.key,
    required this.vendor,
    required this.basket,
    required this.streetAddress,
    required this.suburbCity,
    required this.userCoords,
    required this.userName,
    required this.userPhone,
    required this.onOrderPlaced,
  });

  @override
  State<ScheduleServiceScreen> createState() => _ScheduleServiceScreenState();
}

class _ScheduleServiceScreenState extends State<ScheduleServiceScreen> {
  late List<DateTime> _days;
  int _selectedDayIdx = 1;
  String _selectedWindow = '10:00 - 12:00';
  bool _express24h = false;
  late TextEditingController _streetCtrl;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _days = List.generate(6, (i) => now.add(Duration(days: i)));
    _streetCtrl = TextEditingController(text: widget.streetAddress);
  }

  double get _itemsSubtotal =>
      widget.basket.fold(0.0, (s, item) => s + item.lineTotal);

  double get _expressAddon => _express24h ? 45.0 : 0.0;

  @override
  Widget build(BuildContext context) {
    final pickupDate = _days[_selectedDayIdx];
    final returnDate =
    pickupDate.add(Duration(hours: _express24h ? 24 : 48));

    final windows = [
      {'time': '08:00 - 10:00', 'label': 'Morning slot'},
      {'time': '10:00 - 12:00', 'label': 'Standard slot'},
      {'time': '14:00 - 16:00', 'label': 'Afternoon'},
      {'time': '16:00 - 18:00', 'label': 'Evening'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Pickup & Delivery',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pickup Location',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        height: 130,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: widget.userCoords,
                            initialZoom: 14.5,
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
                                  point: widget.userCoords,
                                  width: 48,
                                  height: 48,
                                  child: const Icon(Icons.location_on,
                                      color: AppColors.deepEmerald, size: 34),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _streetCtrl,
                      decoration: InputDecoration(
                        labelText: 'Doorstep Street Address',
                        helperText: widget.suburbCity,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Select Pickup Date',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 10),
            SizedBox(
              height: 92,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _days.length,
                itemBuilder: (context, i) {
                  final d = _days[i];
                  final selected = _selectedDayIdx == i;
                  final topLabel = i == 0
                      ? 'TODAY'
                      : i == 1
                      ? 'TOMORROW'
                      : DateFormat('EEE').format(d).toUpperCase();
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDayIdx = i),
                    child: Container(
                      width: 82,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.mintAccent.withOpacity(0.2)
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? AppColors.deepEmerald
                              : Colors.grey.shade300,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(topLabel,
                              style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold)),
                          Text(
                            DateFormat('dd').format(d),
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w900),
                          ),
                          Text(DateFormat('MMM').format(d),
                              style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            const Text('Pickup Window',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: windows.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.3,
              ),
              itemBuilder: (context, i) {
                final w = windows[i];
                final active = _selectedWindow == w['time'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedWindow = w['time']!),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.mintAccent.withOpacity(0.18)
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: active
                            ? AppColors.deepEmerald
                            : Colors.grey.shade300,
                        width: active ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(w['time']!,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 13)),
                        Text(w['label']!,
                            style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            Card(
              child: Column(
                children: [
                  RadioListTile<bool>(
                    activeColor: AppColors.deepEmerald,
                    value: false,
                    groupValue: _express24h,
                    onChanged: (_) => setState(() => _express24h = false),
                    title: const Text('Standard 48-Hour Return (FREE)',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  RadioListTile<bool>(
                    activeColor: AppColors.deepEmerald,
                    value: true,
                    groupValue: _express24h,
                    onChanged: (_) => setState(() => _express24h = true),
                    title: const Text('⚡ Express 24-Hour Return (+R45.00)',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkNavy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderSummaryAndPaymentScreen(
                    vendor: widget.vendor,
                    basket: widget.basket,
                    pickupAddress:
                    '${_streetCtrl.text.trim()}, ${widget.suburbCity}',
                    pickupDate: pickupDate,
                    returnDate: returnDate,
                    timeWindow: _selectedWindow,
                    expressFee: _expressAddon,
                    userCoords: widget.userCoords,
                    userName: widget.userName,
                    userPhone: widget.userPhone,
                    onOrderConfirmed: widget.onOrderPlaced,
                  ),
                ),
              );
            },
            child: Text(
              'Proceed to Checkout • R ${(_itemsSubtotal + _expressAddon).toStringAsFixed(2)} →',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}