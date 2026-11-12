import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../theme/app_theme.dart';

class OrdersAndReceiptsTab extends StatelessWidget {
  final void Function(String orderId) onTrackOrder;
  final void Function(List<dynamic> items) onReorder;

  const OrdersAndReceiptsTab({
    super.key,
    required this.onTrackOrder,
    required this.onReorder,
  });

  Future<void> _generatePdfReceipt(Map<String, dynamic> orderData) async {
    final doc = pw.Document();
    final orderId = orderData['orderId'] ?? 'CD-9042';
    final total = (orderData['totalAmount'] ?? 325.0).toDouble();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('CLEANDROP OFFICIAL TAX INVOICE',
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Order Ref: #$orderId'),
              pw.Text(
                  'Customer: ${orderData['customerName'] ?? 'Sipho'} (${orderData['customerPhone'] ?? ''})'),
              pw.Text('Address: ${orderData['pickupAddress'] ?? ''}'),
              pw.Divider(),
              pw.Text('Total Paid: R ${total.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'CleanDrop_Receipt_$orderId.pdf',
    );
  }

  static const List<Map<String, dynamic>> _dummyPreviewOrders = [
    {
      'orderId': 'CD-9048',
      'laundromatName': 'Mthatha Central CleanDrop Hub',
      'totalAmount': 325.0,
      'customerName': 'Sipho M.',
      'customerPhone': '+27 73 456 7890',
      'pickupAddress': '14 Nelson Mandela Dr, Mthatha Central',
      'orderStatus': 'DRIVER_EN_ROUTE',
    },
    {
      'orderId': 'CD-9042',
      'laundromatName': 'Sparkle Care Dry Cleaners & Blankets',
      'totalAmount': 210.0,
      'customerName': 'Sipho M.',
      'customerPhone': '+27 73 456 7890',
      'pickupAddress': '14 Nelson Mandela Dr, Mthatha Central',
      'orderStatus': 'COMPLETED',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'demo_user';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History & Receipts',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('customerId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          final ordersList = docs.isNotEmpty
              ? docs.map((d) => d.data() as Map<String, dynamic>).toList()
              : _dummyPreviewOrders;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ordersList.length,
            itemBuilder: (context, index) {
              final data = ordersList[index];
              final id = data['orderId'] ?? 'CD-9048';
              final total = (data['totalAmount'] ?? 325.0).toDouble();

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Order #$id',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w900)),
                          Text('R ${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.deepEmerald)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(data['laundromatName'] ?? 'CleanDrop Hub'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _generatePdfReceipt(data),
                              icon: const Icon(Icons.picture_as_pdf_outlined,
                                  size: 18),
                              label: const Text('PDF Receipt'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.mintAccent,
                                foregroundColor: AppColors.darkNavy,
                              ),
                              onPressed: () => onTrackOrder(id.toString()),
                              icon: const Icon(Icons.near_me_outlined, size: 18),
                              label: const Text('Track Live'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
