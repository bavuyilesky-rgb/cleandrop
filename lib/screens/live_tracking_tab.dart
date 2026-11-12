import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class LiveTrackingTab extends StatelessWidget {
  final String orderId;
  final LatLng fallbackUserCoords;

  const LiveTrackingTab({
    super.key,
    required this.orderId,
    required this.fallbackUserCoords,
  });

  static const List<Map<String, String>> _milestones = [
    {'code': 'CONFIRMED', 'title': 'Order Confirmed', 'time': '09:15 AM'},
    {
      'code': 'DRIVER_EN_ROUTE',
      'title': 'Driver En Route for Pickup',
      'time': 'Now'
    },
    {'code': 'WASHING', 'title': 'In Wash & Sanitise', 'time': '12:00 PM'},
    {
      'code': 'OUT_FOR_DELIVERY',
      'title': 'Quality Dried & Out for Delivery',
      'time': '15:30 PM'
    },
    {'code': 'COMPLETED', 'title': 'Delivered & Signed Off', 'time': '16:15 PM'},
  ];

  Future<void> _callDriver(BuildContext context, String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _smsDriver(BuildContext context, String phone) async {
    final uri = Uri.parse('smsto:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final status = (data['orderStatus'] ?? 'DRIVER_EN_ROUTE').toString();
        final pin = (data['handoverPin'] ?? '4821').toString();
        final driverName = (data['driverName'] ?? 'Lwazi M.').toString();
        final driverVehicle =
        (data['driverVehicle'] ?? 'White Toyota HiAce').toString();
        final driverPlate = (data['driverPlate'] ?? 'EC 492-910').toString();
        final driverPhone =
        (data['driverPhone'] ?? '+27821234567').toString();

        final userPt = LatLng(
          (data['userLat'] ?? fallbackUserCoords.latitude).toDouble(),
          (data['userLng'] ?? fallbackUserCoords.longitude).toDouble(),
        );
        final driverPt = LatLng(
          (data['vendorLat'] ?? userPt.latitude + 0.0045).toDouble(),
          (data['vendorLng'] ?? userPt.longitude - 0.0038).toDouble(),
        );

        final currentIdx = _milestones
            .indexWhere((element) => element['code'] == status)
            .clamp(0, _milestones.length - 1);

        return Scaffold(
          appBar: AppBar(
            title: Text('Live Order #$orderId',
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
          body: Column(
            children: [
              SizedBox(
                height: 230,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: userPt,
                    initialZoom: 14.2,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.cleandrop.app',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [driverPt, userPt],
                          color: AppColors.deepEmerald,
                          strokeWidth: 4.5,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: driverPt,
                          width: 48,
                          height: 48,
                          child: const CircleAvatar(
                            backgroundColor: AppColors.mintAccent,
                            child: Icon(Icons.local_shipping,
                                color: AppColors.darkNavy),
                          ),
                        ),
                        Marker(
                          point: userPt,
                          width: 48,
                          height: 48,
                          child: const CircleAvatar(
                            backgroundColor: AppColors.darkNavy,
                            child: Icon(Icons.location_on,
                                color: AppColors.mintAccent),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.darkNavy,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Handover Security PIN',
                              style: TextStyle(
                                color: AppColors.mintAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'PIN: $pin',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.deepEmerald,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(driverName,
                              style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('$driverVehicle • $driverPlate'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton.filledTonal(
                                onPressed: () =>
                                    _callDriver(context, driverPhone),
                                icon: const Icon(Icons.phone_in_talk),
                              ),
                              IconButton.filledTonal(
                                onPressed: () =>
                                    _smsDriver(context, driverPhone),
                                icon: const Icon(Icons.message_outlined),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: List.generate(_milestones.length, (i) {
                              final m = _milestones[i];
                              final isDone = i <= currentIdx;
                              return ListTile(
                                dense: true,
                                leading: Icon(
                                  isDone
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: isDone
                                      ? AppColors.deepEmerald
                                      : Colors.grey,
                                ),
                                title: Text(
                                  m['title']!,
                                  style: TextStyle(
                                    fontWeight: isDone
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                trailing: Text(m['time']!),
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}